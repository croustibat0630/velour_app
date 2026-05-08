import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../utils/velour_audio_trace.dart';
import 'velour_audio_platform.dart';

/// Audio centralisé : **aucune redirection** entre menu, sélection gemme et combo.
///
/// - [playMenuClick] → uniquement `sfx_click.mp3`
/// - [playGemSelect] → `sfx_tap.mp3` (canal dédié, réactif)
/// - [playMatchCombo] → `sfx_match.mp3` pur (pool polyphonique) — **sans** pitch
class AudioHandler {
  AudioHandler._();

  static final AudioHandler instance = AudioHandler._();

  static const String _menuClickFile = 'sfx_click.mp3';
  static const String _tapFile = 'sfx_tap.mp3';
  static const String _matchFile = 'sfx_match.mp3';
  static const String _perfectFile = 'sfx_perfect.mp3';
  static const String _levelUpFile = 'sfx_level_up.mp3';
  static const String _creditFile = 'sfx_credit.mp3';

  /// Pool polyphonique pour les combos (overlap sans attendre la fin du son).
  static const int _matchPolyphony = 10;
  static const int _matchPolyphonyWeb = 1;
  static const int _matchPolyphonyApple = 1;

  /// Plafond par player : en dessous du timeout interne d’audioplayers (~30s)
  /// pour échouer vite ; évite les blocages si deux préloads se chevauchent.
  static const Duration _pooledSfxLoadTimeout = Duration(seconds: 12);

  Future<void>? _preloadGameSfxFuture;

  final AudioPlayer _bgm = AudioPlayer(playerId: 'velour_bgm');

  final List<AudioPlayer> _sfxMatchPool = <AudioPlayer>[];
  int _matchPoolCursor = 0;
  final AudioPlayer _sfxTap = AudioPlayer(playerId: 'velour_sfx_tap');
  final AudioPlayer _sfxPerfect = AudioPlayer(playerId: 'velour_sfx_perfect');
  final AudioPlayer _sfxLevelUp = AudioPlayer(playerId: 'velour_sfx_level_up');
  final AudioPlayer _sfxCredit = AudioPlayer(playerId: 'velour_sfx_credit');

  bool _matchPoolReady = false;
  bool _tapReady = false;
  bool _perfectPoolReady = false;
  bool _levelUpReady = false;
  bool _creditReady = false;

  bool _matchPrimedThisRun = false;
  bool _tapPrimedThisRun = false;
  bool _tapChannelConfirmedThisRun = false;
  bool _creditPrimedThisRun = false;

  final ValueNotifier<bool> muted = ValueNotifier<bool>(false);
  final ValueNotifier<bool> sfxMuted = ValueNotifier<bool>(false);

  bool _configured = false;
  final bool _disabled = false;
  bool _bgmStarted = false;

  // audioplayers préfixe déjà les sources assets par `assets/`.
  // Donc ici on fournit un chemin relatif à `assets/` pour éviter `assets/assets/...`.
  String _assetKey(String fileName) => 'audio/$fileName';

  Source _sourceFor(String fileName) {
    final String key = _assetKey(fileName);
    if (kIsWeb) return UrlSource('assets/$key');
    final bool apple =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    // iOS 17+ : AVURLAsset sans MIME peut refuser certains MP3 en release.
    if (apple) {
      return AssetSource(key, mimeType: 'audio/mpeg');
    }
    return AssetSource(key);
  }

  Future<void> configure() async {
    if (_configured) return;
    _configured = true;
    try {
      if (!kIsWeb) {
        await _bgm.setAudioContext(velourGameAudioContext());
      }
      await _bgm.setPlayerMode(PlayerMode.mediaPlayer);
      await _bgm.setReleaseMode(ReleaseMode.loop);
      await _bgm.setVolume(0.42);
    } catch (_) {
      // Ne pas mettre [_disabled] : une erreur sur le player BGM ne doit pas
      // couper tous les SFX (souvent le cas si la session n’était pas prête au cold start).
    }
  }

  /// Prépare le pipeline audio au lancement (splash / cold start).
  /// Ne doit pas être **critique** pour la navigation : peut échouer ou
  /// rester partiel jusqu’à [unlockAudio] / [resumeAudioThenStartMenuBgm].
  Future<void> init() async {
    if (_disabled) return;
    try {
      await configure();
      if (_disabled) return;
      await preloadGameSfx();
    } catch (_) {
      // Cold start : ne pas désactiver tout le pipeline pour une erreur partielle.
    }
  }

  /// Premier geste sur le menu principal : réveille l’AudioContext (Chrome)
  /// puis lance la BGM — ordre séquentiel pour respecter la politique navigateur.
  ///
  /// Retourne `true` si la BGM est considérée comme lancée (ou musique coupée
  /// volontairement dans les réglages), `false` si échec — pour permettre un
  /// nouvel essai au prochain tap ([MainMenuView]).
  Future<bool> resumeAudioThenStartMenuBgm() async {
    if (_disabled) {
      velourAudioTrace('resumeAudioThenStartMenuBgm: skipped (_disabled)');
      return false;
    }
    if (muted.value) {
      velourAudioTrace(
        'resumeAudioThenStartMenuBgm: music muted in settings → no BGM',
      );
      return true;
    }
    velourAudioTrace('resumeAudioThenStartMenuBgm: begin');
    try {
      await configureVelourAudioPipeline(activateSession: true);
    } catch (e) {
      velourAudioTrace('resumeAudioThenStartMenuBgm: pipeline threw $e');
    }
    try {
      await unlockAudio();
    } catch (e) {
      velourAudioTrace('resumeAudioThenStartMenuBgm: unlockAudio threw $e');
    }
    try {
      await playMusic('music_main.mp3');
    } catch (e) {
      velourAudioTrace('resumeAudioThenStartMenuBgm: playMusic threw $e');
    }
    velourAudioTrace(
      'resumeAudioThenStartMenuBgm: end bgmStarted=$_bgmStarted sfxMuted=${sfxMuted.value}',
    );
    return _bgmStarted;
  }

  Future<void> _warmUpSfxDecoder(AudioPlayer p) async {
    // Chrome / Web : `resume()` sans interaction utilisateur peut ne jamais
    // compléter — le splash ne doit pas en dépendre ; [unlockAudio] fera
    // le vrai réveil au premier geste (menu).
    if (kIsWeb) {
      return;
    }
    try {
      await p.setVolume(0.0);
      await p.resume();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await p.stop();
    } catch (_) {
      // Intentionally silent: warm-up is best-effort.
    }
  }

  Future<void> _interruptMatchAndPerfect() async {
    // Exclusive match policy: new match cuts previous sounds.
    // Web: we keep the pool tiny, but we still apply the same contract.
    //
    // IMPORTANT: Ne doit pas retarder le déclenchement du nouveau son.
    // On coupe en best-effort, en arrière-plan.
    try {
      if (_sfxMatchPool.isNotEmpty) {
        for (final AudioPlayer p in _sfxMatchPool) {
          // Stop immédiat (meilleure synchro) ; on évite d'attendre le fade.
          unawaited(p.stop());
        }
      }
    } catch (_) {}
    try {
      unawaited(_sfxPerfect.stop());
    } catch (_) {}
  }

  Future<void> _setupPooledSfx({
    required AudioPlayer player,
    required String fileName,
  }) async {
    Future<void> work() async {
      if (!kIsWeb) {
        await player.setAudioContext(velourGameAudioContext());
      }
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSource(_sourceFor(fileName));
      await _warmUpSfxDecoder(player);
      await player.setVolume(1.0);
    }

    await work().timeout(
      _pooledSfxLoadTimeout,
      onTimeout: () {
        velourAudioTrace(
          'AudioHandler._setupPooledSfx timeout file=$fileName '
          'after ${_pooledSfxLoadTimeout.inSeconds}s',
        );
        throw TimeoutException('pooled sfx', _pooledSfxLoadTimeout);
      },
    );
  }

  /// Précharge match (pool) + perfect (mono pool).
  ///
  /// Une seule exécution à la fois : plusieurs appels concurrents (ex. double
  /// [preloadGameSfx] depuis [GameScreen]) rejoignent la même [Future] et
  /// n’entrelacent pas les [setSource] sur les mêmes [AudioPlayer].
  Future<void> preloadGameSfx() {
    return _preloadGameSfxFuture ??= _preloadGameSfxOnce().whenComplete(
      () => _preloadGameSfxFuture = null,
    );
  }

  Future<void> _preloadGameSfxOnce() async {
    try {
      if (_disabled) return;
      await configure();
      if (_disabled) return;
      if (!kIsWeb) {
        try {
          await configureVelourAudioPipeline(activateSession: true);
        } catch (_) {}
      }

      try {
        await _ensureMatchPool();
      } catch (_) {
        _matchPoolReady = false;
      }

      try {
        await _setupPooledSfx(player: _sfxTap, fileName: _tapFile);
        _tapReady = true;
      } catch (_) {
        _tapReady = false;
      }

      try {
        await _setupPooledSfx(player: _sfxPerfect, fileName: _perfectFile);
        _perfectPoolReady = true;
      } catch (_) {
        _perfectPoolReady = false;
      }

      // Level-up is long; keep it ready but not playing.
      try {
        await _setupPooledSfx(player: _sfxLevelUp, fileName: _levelUpFile);
        _levelUpReady = true;
      } catch (_) {
        _levelUpReady = false;
      }

      try {
        await _setupPooledSfx(player: _sfxCredit, fileName: _creditFile);
        _creditReady = true;
      } catch (_) {
        _creditReady = false;
      }
    } catch (_) {
      // Best-effort preload; ignore in production.
    }
  }

  /// Réveil total du contexte audio (politique Chrome) :
  /// micro-séquence de **chaque** SFX pour forcer validation + cache ressource.
  Future<void> unlockAudio() async {
    if (_disabled) return;
    try {
      await configureVelourAudioPipeline(activateSession: true);
    } catch (_) {}
    try {
      await configure();
      if (_disabled) return;

      // Important: séquentiel pour forcer le chargement individuel de chaque asset.
      await _playDisposableOneShot(_menuClickFile, volume: 0.001, holdMs: 70);
      await _playDisposableOneShot(_tapFile, volume: 0.001, holdMs: 70);
      await _playDisposableOneShot(_matchFile, volume: 0.001, holdMs: 70);
      await _playDisposableOneShot(_perfectFile, volume: 0.001, holdMs: 70);

      // On en profite pour rendre le tap immédiatement prêt (canal dédié).
      try {
        await _ensureTapReady();
      } catch (_) {}
    } catch (_) {
      // Best-effort unlock; ignore in production.
    }
  }

  /// **Menus uniquement** : pause, retour, boutons du menu principal, etc.
  void playMenuClick() {
    if (_disabled) return;
    if (sfxMuted.value) return;
    unawaited(_playDisposableOneShot(_menuClickFile, volume: 1.0, holdMs: 220));
  }

  /// Tap gemme (sélection) : distinct du combo (court + plus bas).
  /// Identité dédiée: `sfx_tap.mp3` (volume 0.8), **sans pitch**.
  void playGemSelect() {
    if (_disabled) return;
    if (sfxMuted.value) return;
    // iOS: le premier `resume()` d'un canal low-latency peut être silencieux même si
    // la source est prête. On "prime" une seule fois avec un one-shot audible.
    if (!_tapPrimedThisRun) {
      _tapPrimedThisRun = true;
      velourAudioTrace(
        'tap trigger (prime one-shot) t=${DateTime.now().microsecondsSinceEpoch}',
      );
      unawaited(_playDisposableOneShot(_tapFile, volume: 0.8, holdMs: 220));
      unawaited(_ensureTapReady());
      return;
    }
    // iOS: le 1er `resume()` du canal low-latency peut encore être silencieux.
    // On garantit au moins un tap audible avant de basculer 100% sur le canal.
    if (!_tapChannelConfirmedThisRun) {
      _tapChannelConfirmedThisRun = true;
      velourAudioTrace(
        'tap trigger (confirm channel + audible fallback) t=${DateTime.now().microsecondsSinceEpoch}',
      );
      unawaited(_playDisposableOneShot(_tapFile, volume: 0.8, holdMs: 220));
      // Warm the dedicated channel in parallel (even if silent once).
      unawaited(_playTapFromChannel(volume: 0.001));
      unawaited(_ensureTapReady());
      return;
    }
    // Sur device (surtout iOS), le tout premier tap peut arriver avant que le canal dédié
    // (_sfxTap) ne soit prêt (préload async). Pour éviter un premier tap silencieux,
    // on joue un one-shot immédiat si le canal n’est pas encore warm.
    if (!_tapReady) {
      velourAudioTrace(
        'tap trigger (fallback one-shot) t=${DateTime.now().microsecondsSinceEpoch}',
      );
      unawaited(_playDisposableOneShot(_tapFile, volume: 0.8, holdMs: 220));
      unawaited(_ensureTapReady());
      return;
    }
    velourAudioTrace(
      'tap trigger (channel) t=${DateTime.now().microsecondsSinceEpoch}',
    );
    unawaited(_playTapFromChannel(volume: 0.8));
  }

  /// Combo classique : `sfx_match` pur, polyphonique, **sans** `setPlaybackRate`.
  void playMatchCombo() {
    if (_disabled) return;
    if (sfxMuted.value) return;
    velourAudioTrace(
      'match trigger t=${DateTime.now().microsecondsSinceEpoch}',
    );
    unawaited(_playMatchExclusive(volume: 1.0));
  }

  /// Combo parfait : `sfx_perfect` (piste séparée).
  void playPerfectCombo() {
    if (_disabled) return;
    if (sfxMuted.value) return;
    velourAudioTrace(
      'perfect trigger t=${DateTime.now().microsecondsSinceEpoch}',
    );
    unawaited(_playPerfectExclusive());
  }

  /// Petit scintillement premium (Menu / cadeau de bienvenue).
  /// Canal dédié (perfect) mais lecture très courte + volume faible.
  void playWelcomeGift() {
    if (_disabled) return;
    if (sfxMuted.value) return;
    unawaited(_playWelcomeGiftChime());
  }

  /// Son de crédit premium (2s) synchronisé avec un compteur qui défile.
  void playCredit() {
    if (_disabled) return;
    if (sfxMuted.value) return;
    // Comme pour le tap : sur device, le tout premier trigger peut arriver avant que
    // le player dédié soit réellement chaud (préload async). On prime une fois avec un
    // one-shot audible pour éviter un “crédit” en retard.
    if (!_creditPrimedThisRun) {
      _creditPrimedThisRun = true;
      velourAudioTrace(
        'credit trigger (prime one-shot) t=${DateTime.now().microsecondsSinceEpoch}',
      );
      unawaited(_playDisposableOneShot(_creditFile, volume: 1.0, holdMs: 450));
      unawaited(_ensureCreditReady());
      return;
    }
    velourAudioTrace(
      'credit trigger (player) t=${DateTime.now().microsecondsSinceEpoch} ready=$_creditReady',
    );
    unawaited(_playCreditSfx());
  }

  /// Level up : `sfx_level_up` (8s) mais coupé/fade-out après 3s max.
  void playLevelUp() {
    if (_disabled) return;
    if (sfxMuted.value) return;
    unawaited(_playLevelUpCapped());
  }

  /// Web policy: sur le tout premier tap réel, on force un micro `sfx_match`
  /// (10ms à volume 0.001) pour activer/valider le pool côté Chrome.
  void primeMatchPoolOnFirstUserTap() {
    if (_disabled) return;
    if (_matchPrimedThisRun) return;
    _matchPrimedThisRun = true;
    unawaited(_primeMatchPoolMicro());
  }

  // ---------------------------------------------------------------------------
  // BGM
  // ---------------------------------------------------------------------------

  Future<void> playBGM({String fileName = 'music_main.mp3'}) async {
    if (_disabled) return;
    if (muted.value) return;
    if (_bgmStarted) return;
    try {
      await configureVelourAudioPipeline(activateSession: true);
      await configure();
      await _bgm.play(
        _sourceFor(fileName),
        mode: PlayerMode.mediaPlayer,
        volume: 0.42,
        ctx: velourGameAudioContext(),
      );
      _bgmStarted = true;
    } on AudioPlayerException {
      _bgmStarted = false;
    } catch (_) {
      _bgmStarted = false;
    }
  }

  Future<void> playMusic(String fileName) async {
    if (_disabled) return;
    if (muted.value) return;
    try {
      await configureVelourAudioPipeline(activateSession: true);
      await configure();
      velourAudioTrace('playMusic: starting $fileName');
      await _bgm.play(
        _sourceFor(fileName),
        mode: PlayerMode.mediaPlayer,
        volume: 0.42,
        ctx: velourGameAudioContext(),
      );
      _bgmStarted = true;
      velourAudioTrace('playMusic: _bgm.play completed');
    } on AudioPlayerException catch (e, st) {
      _bgmStarted = false;
      velourAudioTrace('playMusic: AudioPlayerException $e');
      velourAudioTrace('$st');
    } catch (e, st) {
      _bgmStarted = false;
      velourAudioTrace('playMusic: error $e');
      velourAudioTrace('$st');
    }
  }

  Future<void> stopMusic() async {
    if (_disabled) return;
    try {
      await _bgm.stop();
      _bgmStarted = false;
    } catch (_) {}
  }

  Future<void> stopBGM() => stopMusic();

  void cutAllAudio() {
    if (_disabled) return;
    unawaited(_cutAllAudioAsync());
  }

  Future<void> _cutAllAudioAsync() async {
    try {
      await _bgm.stop();
    } catch (_) {}
    for (final p in _sfxMatchPool) {
      try {
        await p.stop();
      } catch (_) {}
    }
    try {
      await _sfxPerfect.stop();
    } catch (_) {}
  }

  /// Réinitialise l’état “premier combo” côté pool (nouvelle run).
  void resetSelectAudioWake() {
    _matchPoolCursor = 0;
    _matchPrimedThisRun = false;
    _tapPrimedThisRun = false;
    _tapChannelConfirmedThisRun = false;
    _creditPrimedThisRun = false;
  }

  Future<void> setMuted(bool v) async {
    muted.value = v;
    if (_disabled) return;
    try {
      if (v) {
        await _bgm.pause();
      } else {
        await _bgm.resume();
      }
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _bgm.dispose();
    } catch (_) {}
    for (final p in _sfxMatchPool) {
      try {
        await p.dispose();
      } catch (_) {}
    }
    try {
      await _sfxTap.dispose();
    } catch (_) {}
    try {
      await _sfxPerfect.dispose();
    } catch (_) {}
    try {
      await _sfxLevelUp.dispose();
    } catch (_) {}
    try {
      await _sfxCredit.dispose();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<void> _ensureMatchPool() async {
    if (_matchPoolReady) return;
    if (_disabled) return;
    await configure();
    if (_disabled) return;

    if (_sfxMatchPool.isEmpty) {
      final bool apple =
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS;
      final int n = kIsWeb
          ? _matchPolyphonyWeb
          : (apple ? _matchPolyphonyApple : _matchPolyphony);
      for (int i = 0; i < n; i++) {
        _sfxMatchPool.add(AudioPlayer(playerId: 'velour_sfx_match_$i'));
      }
    }
    for (final p in _sfxMatchPool) {
      await _setupPooledSfx(player: p, fileName: _matchFile);
    }
    _matchPoolReady = true;
  }

  Future<void> _ensurePerfectPool() async {
    if (_perfectPoolReady) return;
    if (_disabled) return;
    await configure();
    if (_disabled) return;
    await _setupPooledSfx(player: _sfxPerfect, fileName: _perfectFile);
    _perfectPoolReady = true;
  }

  Future<void> _ensureLevelUpReady() async {
    if (_levelUpReady) return;
    if (_disabled) return;
    await configure();
    if (_disabled) return;
    await _setupPooledSfx(player: _sfxLevelUp, fileName: _levelUpFile);
    _levelUpReady = true;
  }

  Future<void> _ensureCreditReady() async {
    if (_creditReady) return;
    if (_disabled) return;
    await configure();
    if (_disabled) return;
    await _setupPooledSfx(player: _sfxCredit, fileName: _creditFile);
    _creditReady = true;
  }

  Future<void> _ensureTapReady() async {
    if (_tapReady) return;
    if (_disabled) return;
    await configure();
    if (_disabled) return;
    await _setupPooledSfx(player: _sfxTap, fileName: _tapFile);
    _tapReady = true;
  }

  Future<void> _playTapFromChannel({required double volume}) async {
    try {
      await _ensureTapReady();
      if (_disabled || !_tapReady) return;
      await _sfxTap.seek(Duration.zero);
      await _sfxTap.setVolume(volume.clamp(0.0, 1.0));
      await _sfxTap.resume();
    } catch (_) {
      // Intentionally silent: SFX failures shouldn't crash gameplay.
    }
  }

  Future<void> _playMatchExclusive({required double volume}) async {
    try {
      await _ensureMatchPool();
      if (_disabled || !_matchPoolReady) return;
      // Ne pas attendre : la coupure des sons précédents ne doit pas retarder celui-ci.
      unawaited(_interruptMatchAndPerfect());
      final AudioPlayer p =
          _sfxMatchPool[_matchPoolCursor++ % _sfxMatchPool.length];
      await p.seek(Duration.zero);
      await p.setVolume(volume.clamp(0.0, 1.0));
      await p.resume();
    } catch (_) {
      // Intentionally silent.
    }
  }

  Future<void> _playPerfectExclusive() async {
    try {
      await _ensurePerfectPool();
      if (_disabled || !_perfectPoolReady) return;
      // Ne pas attendre : la coupure des sons précédents ne doit pas retarder celui-ci.
      unawaited(_interruptMatchAndPerfect());
      await _sfxPerfect.seek(Duration.zero);
      await _sfxPerfect.setVolume(1.0);
      await _sfxPerfect.resume();
    } catch (_) {
      // Intentionally silent.
    }
  }

  Future<void> _playWelcomeGiftChime() async {
    try {
      await _ensurePerfectPool();
      if (_disabled || !_perfectPoolReady) return;
      await _sfxPerfect.seek(Duration.zero);
      await _sfxPerfect.setVolume(0.28);
      await _sfxPerfect.resume();
      await Future<void>.delayed(const Duration(milliseconds: 220));
      await _sfxPerfect.stop();
      await _sfxPerfect.setVolume(1.0);
    } catch (_) {
      // Intentionally silent.
    }
  }

  Future<void> _playCreditSfx() async {
    try {
      await _ensureCreditReady();
      if (_disabled || !_creditReady) return;
      await _sfxCredit.seek(Duration.zero);
      await _sfxCredit.setVolume(1.0);
      await _sfxCredit.resume();
      await Future<void>.delayed(const Duration(milliseconds: 2000));
      await _sfxCredit.stop();
    } catch (_) {
      // Intentionally silent.
    }
  }

  Future<void> _primeMatchPoolMicro() async {
    try {
      await _ensureMatchPool();
      if (_disabled || !_matchPoolReady) return;
      // Ensure we don't leave a faint tail behind on browsers.
      await _interruptMatchAndPerfect();
      final AudioPlayer p =
          _sfxMatchPool[_matchPoolCursor++ % _sfxMatchPool.length];
      await p.seek(Duration.zero);
      await p.setVolume(0.001);
      await p.resume();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await p.stop();
    } catch (_) {
      // Intentionally silent.
    }
  }

  Future<void> _playLevelUpCapped() async {
    try {
      await _ensureLevelUpReady();
      if (_disabled || !_levelUpReady) return;

      await _sfxLevelUp.seek(Duration.zero);
      await _sfxLevelUp.setVolume(1.0);
      await _sfxLevelUp.resume();

      // Cap @ 3s (fade over last 450ms).
      const int capMs = 3000;
      const int fadeMs = 450;
      await Future<void>.delayed(const Duration(milliseconds: capMs - fadeMs));
      const int steps = 9;
      for (int i = 0; i < steps; i++) {
        final double v = (1.0 - (i + 1) / steps).clamp(0.0, 1.0);
        try {
          await _sfxLevelUp.setVolume(v);
        } catch (_) {}
        await Future<void>.delayed(
          const Duration(milliseconds: fadeMs ~/ steps),
        );
      }
      await _sfxLevelUp.stop();
      await _sfxLevelUp.setVolume(1.0);
    } catch (_) {
      // Intentionally silent.
    }
  }

  /// Lecture one-shot ; `playbackRate` ignoré sur Web (pas de `setPlaybackRate`).
  Future<void> _playDisposableOneShot(
    String fileName, {
    required double volume,
    required int holdMs,
    double? playbackRate,
  }) async {
    try {
      await configure();
      if (_disabled) return;

      final AudioPlayer p = AudioPlayer();
      try {
        if (!kIsWeb) {
          await p.setAudioContext(velourGameAudioContext());
        }
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setSource(_sourceFor(fileName));
        if (!kIsWeb &&
            playbackRate != null &&
            playbackRate > 0 &&
            (playbackRate - 1.0).abs() > 0.001) {
          await p.setPlaybackRate(playbackRate);
        }
        await p.setVolume(volume.clamp(0.0, 1.0));
        await p.resume();
        await Future<void>.delayed(Duration(milliseconds: holdMs));
      } catch (_) {
        // Intentionally silent.
      } finally {
        try {
          await p.dispose();
        } catch (_) {}
      }
    } catch (_) {
      // Intentionally silent.
    }
  }
}
