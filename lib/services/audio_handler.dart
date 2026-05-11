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

  /// Plafond pour `setSource` + config player : **doit** rester aligné avec
  /// [AudioPlayer.preparationTimeout] (installé dans [configure]).
  static const Duration _pooledSfxLoadTimeout = Duration(seconds: 12);

  /// `resume()` du warm-up peut pendre sur iOS sans route audio idéale — ne pas
  /// l’inclure dans [_pooledSfxLoadTimeout] (sinon 12s atteint pendant le warm-up).
  static const Duration _pooledSfxWarmTimeout = Duration(seconds: 4);

  Future<void>? _preloadGameSfxFuture;
  static bool _installedAudioplayersTimeouts = false;

  /// Sur iOS (surtout simulateur) + hot restart, plusieurs `setSource` / `play`
  /// asset en parallèle (préload, [unlockAudio], [_ensureTapReady] en arrière-plan)
  /// peuvent faire expirer toute la pile (12 s). Tout passe par ce chaînage.
  Future<void> _nativeSourceLoadSerial = Future<void>.value();

  Future<T> _withNativeSourceLoadLock<T>(Future<T> Function() op) {
    final Future<T> work = _nativeSourceLoadSerial.then<T>((_) => op());
    _nativeSourceLoadSerial = work.then<void>((_) {}).catchError((_) {});
    return work;
  }

  static void _installAudioplayersTimeoutGuards() {
    if (_installedAudioplayersTimeouts) return;
    _installedAudioplayersTimeouts = true;
    AudioPlayer.preparationTimeout = _pooledSfxLoadTimeout;
    AudioPlayer.seekingTimeout = _pooledSfxLoadTimeout;
  }

  /// Idempotent — appeler au cold start avant tout [AudioPlayer.setSource]
  /// (ex. depuis [main]) pour éviter le défaut 30s du package sur la Future « prepared ».
  static void installAudioplayersTimeoutGuardsEarly() {
    _installAudioplayersTimeoutGuards();
  }

  final AudioPlayer _bgm = AudioPlayer(playerId: 'velour_bgm');

  final List<AudioPlayer> _sfxMatchPool = <AudioPlayer>[];
  int _matchPoolCursor = 0;

  /// Incrémenté après [dispose] + recréation (simulateur iOS : `setSource` bloqué).
  int _darwinTapPlayerSeq = 0;
  int _darwinMatchPoolGen = 0;
  AudioPlayer _sfxTap = AudioPlayer(playerId: 'velour_sfx_tap_0');
  final AudioPlayer _sfxPerfect = AudioPlayer(playerId: 'velour_sfx_perfect');
  final AudioPlayer _sfxLevelUp = AudioPlayer(playerId: 'velour_sfx_level_up');
  final AudioPlayer _sfxCredit = AudioPlayer(playerId: 'velour_sfx_credit');

  bool _matchPoolReady = false;
  bool _tapReady = false;
  bool _perfectPoolReady = false;
  bool _levelUpReady = false;
  bool _creditReady = false;

  /// iOS/macOS : [setSource] sur lecteurs pool a échoué — bascule sur one-shots
  /// jetables (même stratégie que le menu) pour éviter les parties silencieuses.
  bool _darwinDisposableSfxMode = false;

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
    _installAudioplayersTimeoutGuards();
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
  ///
  /// **Mobile / desktop natif** : le préload pool SFX ne part plus ici (il suivait
  /// le premier [resumeAudioThenStartMenuBgm] sur le verrou natif). Voir [preloadGameSfx].
  Future<void> init() async {
    if (_disabled) return;
    try {
      await configure();
      if (_disabled) return;
      // Web : précharger sous contrôle (geste navigateur). Darwin : ne pas bloquer
      // le splash sur une chaîne `setSource` qui peut prendre >10s après hot restart
      // simulateur — [preloadGameSfx] rejoue au menu / à l’écran jeu sous le verrou.
      if (kIsWeb) {
        await preloadGameSfx();
      } else {
        // Mobile / desktop natif : ne pas lancer le préload pool ici en parallèle du
        // splash. Il prenait le verrou [_withNativeSourceLoadLock] pendant des dizaines
        // de secondes (setSource séquentiels) et retardait ou bloquait le premier
        // [resumeAudioThenStartMenuBgm] (BGM absente, SFX en retard sur device).
        // Le menu enchaîne [preloadGameSfx] après déverrouillage ; [GameScreen] aussi.
      }
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
      // Sans ce passage, le simulateur iOS (surtout après hot restart) peut laisser
      // `setSource` sur les lecteurs pool pendre jusqu'au timeout — le bundle unlock
      // + micro one-shots aligne la session comme quand la BGM démarre.
      try {
        await _withNativeSourceLoadLock(
          () => _unlockAudioCore(preloadPooledTapChannel: false),
        );
      } catch (e) {
        velourAudioTrace('resumeAudioThenStartMenuBgm: muted unlock threw $e');
      }
      if (!kIsWeb) {
        unawaited(preloadGameSfx());
      }
      return true;
    }
    velourAudioTrace('resumeAudioThenStartMenuBgm: begin');
    try {
      // Un seul passage sous le verrou : unlock + BGM sans double reconfig pipeline.
      await _withNativeSourceLoadLock(() async {
        await _unlockAudioCore();
        await _playMusicCore('music_main.mp3', skipVelourPipelineReload: true);
      });
      _bgmStarted = true;
    } catch (e) {
      velourAudioTrace('resumeAudioThenStartMenuBgm: audio bundle threw $e');
      _bgmStarted = false;
    }
    velourAudioTrace(
      'resumeAudioThenStartMenuBgm: end bgmStarted=$_bgmStarted sfxMuted=${sfxMuted.value}',
    );
    if (!kIsWeb) {
      // Après BGM / unlock : charge le pool hors de la zone critique du premier geste
      // (évite la course avec l’ancien preload au cold start).
      unawaited(preloadGameSfx());
    }
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

  /// Prépare un lecteur pool (low-latency + setSource). Retourne `false` si
  /// chargement / timeout — **sans** lancer d’exception (évite pause débogueur
  /// « All Exceptions » et laisse le jeu continuer sans ce canal).
  /// Corps [setSource] SFX — **sans** verrou (appeler depuis [_withNativeSourceLoadLock]
  /// ou depuis un bundle déjà verrouillé).
  Future<bool> _setupPooledSfxCore({
    required AudioPlayer player,
    required String fileName,
  }) async {
    final bool applePooled =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    Future<void> loadCore() async {
      if (!kIsWeb) {
        await player.setAudioContext(velourGameAudioContext());
      }
      // Darwin (surtout simulateur) : lowLatency + setSource peut pendre indéfiniment
      // après hot restart / reconfig session — aligné sur [_playDisposableOneShotCore].
      await player.setPlayerMode(
        applePooled ? PlayerMode.mediaPlayer : PlayerMode.lowLatency,
      );
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSource(_sourceFor(fileName));
    }

    Future<bool> runLoadOnce() async {
      try {
        await loadCore().timeout(_pooledSfxLoadTimeout);
        return true;
      } on TimeoutException {
        return false;
      } catch (e, st) {
        velourAudioTrace(
          'AudioHandler._setupPooledSfx loadCore failed file=$fileName err=$e',
        );
        velourAudioTrace('$st');
        return false;
      }
    }

    bool loaded = await runLoadOnce();
    if (!loaded && applePooled) {
      velourAudioTrace(
        'AudioHandler._setupPooledSfx Darwin retry file=$fileName '
        'after ${_pooledSfxLoadTimeout.inSeconds}s timeout',
      );
      try {
        await configureVelourAudioPipeline(activateSession: true, force: true);
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 350));
      try {
        await player.stop();
      } catch (_) {}
      loaded = await runLoadOnce();
    }
    if (!loaded) {
      velourAudioTrace(
        'AudioHandler._setupPooledSfx setSource TIMEOUT file=$fileName '
        'after ${_pooledSfxLoadTimeout.inSeconds}s',
      );
      return false;
    }

    try {
      await _warmUpSfxDecoder(player).timeout(_pooledSfxWarmTimeout);
    } on TimeoutException {
      velourAudioTrace(
        'AudioHandler._warmUpSfxDecoder timeout file=$fileName '
        'after ${_pooledSfxWarmTimeout.inSeconds}s',
      );
    } catch (_) {
      // Best-effort warm-up (session / simulateur).
    }

    try {
      await player.setVolume(1.0);
    } catch (_) {}
    return true;
  }

  Future<bool> _setupPooledSfx({
    required AudioPlayer player,
    required String fileName,
  }) {
    return _withNativeSourceLoadLock(
      () => _setupPooledSfxCore(player: player, fileName: fileName),
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
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS)) {
        _darwinDisposableSfxMode = false;
      }

      // Ne **pas** tenir un seul verrou sur tout le préchargement : les
      // `_playDisposableOneShot` (menu, premier tap) s’y retrouvaient en file
      // derrière unlock + délai + N×`setSource` → latence audible vs l’action.
      // On enchaîne des sections courtes ; le délai iOS reste **hors** verrou.
      if (!kIsWeb) {
        await _withNativeSourceLoadLock(() async {
          await _unlockAudioCore(preloadPooledTapChannel: false);
        });
        await Future<void>.delayed(const Duration(milliseconds: 420));
      } else {
        await _withNativeSourceLoadLock(() => configure());
      }

      if (_disabled) return;

      if (!kIsWeb) {
        await _withNativeSourceLoadLock(() async {
          _tapReady = await _loadTapPooledWithDarwinRebuildIfNeeded();
        });
        await _withNativeSourceLoadLock(() async {
          try {
            await _populateMatchPoolIfNeeded();
          } catch (_) {
            _matchPoolReady = false;
          }
        });
      } else {
        await _withNativeSourceLoadLock(() async {
          try {
            await _populateMatchPoolIfNeeded();
          } catch (_) {
            _matchPoolReady = false;
          }
        });
        await _withNativeSourceLoadLock(() async {
          _tapReady = await _loadTapPooledWithDarwinRebuildIfNeeded();
        });
      }

      await _withNativeSourceLoadLock(() async {
        _perfectPoolReady = await _setupPooledSfxCore(
          player: _sfxPerfect,
          fileName: _perfectFile,
        );
      });

      await _withNativeSourceLoadLock(() async {
        _levelUpReady = await _setupPooledSfxCore(
          player: _sfxLevelUp,
          fileName: _levelUpFile,
        );
      });

      await _withNativeSourceLoadLock(() async {
        _creditReady = await _setupPooledSfxCore(
          player: _sfxCredit,
          fileName: _creditFile,
        );
      });

      if (!kIsWeb && _darwinPooledSfx) {
        final bool pooledIncomplete =
            !_tapReady ||
            !_matchPoolReady ||
            !_perfectPoolReady ||
            !_levelUpReady ||
            !_creditReady;
        if (pooledIncomplete) {
          _darwinDisposableSfxMode = true;
          velourAudioTrace(
            'AudioHandler: Darwin disposable SFX mode (pooled load incomplete: '
            'tap=$_tapReady match=$_matchPoolReady perfect=$_perfectPoolReady '
            'levelUp=$_levelUpReady credit=$_creditReady)',
          );
        }
      }
    } catch (_) {
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS)) {
        _darwinDisposableSfxMode = true;
        velourAudioTrace(
          'AudioHandler: Darwin disposable SFX mode (preload exception)',
        );
      }
      // Best-effort preload; ignore in production.
    }
  }

  /// Réveil total du contexte audio (politique Chrome) :
  /// micro-séquence de **chaque** SFX pour forcer validation + cache ressource.
  Future<void> unlockAudio() async {
    if (_disabled) return;
    try {
      await _withNativeSourceLoadLock(() => _unlockAudioCore());
    } catch (_) {
      // Best-effort unlock; ignore in production.
    }
  }

  /// [preloadPooledTapChannel] : `false` sur le menu **musique muette** uniquement —
  /// le `setSource` pooled du tap peut pendre 12s sur simulateur iOS alors que les
  /// one-shots suffisent à réveiller la session ; le pool est chargé dans [preloadGameSfx].
  Future<void> _unlockAudioCore({bool preloadPooledTapChannel = true}) async {
    try {
      await configureVelourAudioPipeline(activateSession: true, force: true);
    } catch (_) {}
    await configure();
    if (_disabled) return;

    await _playDisposableOneShotCore(_menuClickFile, volume: 0.001, holdMs: 70);
    await _playDisposableOneShotCore(_tapFile, volume: 0.001, holdMs: 70);
    await _playDisposableOneShotCore(_matchFile, volume: 0.001, holdMs: 70);
    await _playDisposableOneShotCore(_perfectFile, volume: 0.001, holdMs: 70);

    if (preloadPooledTapChannel) {
      try {
        await _ensureTapReadyCore();
      } catch (_) {}
    }
  }

  Future<void> _playMusicCore(
    String fileName, {
    bool skipVelourPipelineReload = false,
  }) async {
    if (!skipVelourPipelineReload) {
      try {
        await configureVelourAudioPipeline(activateSession: true, force: true);
      } catch (_) {}
    }
    await configure();
    velourAudioTrace('playMusic: starting $fileName');
    await _bgm.play(
      _sourceFor(fileName),
      mode: PlayerMode.mediaPlayer,
      volume: 0.42,
      ctx: velourGameAudioContext(),
    );
  }

  bool get _darwinPooledSfx =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Future<void> _rebuildDarwinTapPlayer() async {
    if (!_darwinPooledSfx) return;
    _tapReady = false;
    try {
      await _sfxTap.dispose();
    } catch (_) {}
    _darwinTapPlayerSeq++;
    _sfxTap = AudioPlayer(playerId: 'velour_sfx_tap_$_darwinTapPlayerSeq');
  }

  /// Un `AudioPlayer` Darwin peut rester bloqué après timeout `setSource` : recréation
  /// + pipeline + délais avant nouveaux essais (simulateur iOS / navigation).
  Future<bool> _loadTapPooledWithDarwinRebuildIfNeeded() async {
    if (_tapReady) return true;
    bool ok = await _setupPooledSfxCore(player: _sfxTap, fileName: _tapFile);
    if (ok || !_darwinPooledSfx) return ok;
    for (int pass = 0; pass < 2; pass++) {
      velourAudioTrace(
        'AudioHandler: rebuild tap player pass=${pass + 1} after pooled load failure',
      );
      await _rebuildDarwinTapPlayer();
      try {
        await configureVelourAudioPipeline(activateSession: true, force: true);
      } catch (_) {}
      await Future<void>.delayed(Duration(milliseconds: pass == 0 ? 320 : 700));
      ok = await _setupPooledSfxCore(player: _sfxTap, fileName: _tapFile);
      if (ok) return true;
    }
    return false;
  }

  Future<void> _ensureTapReadyCore() async {
    if (_tapReady) return;
    if (_disabled) return;
    await configure();
    if (_disabled) return;
    _tapReady = await _loadTapPooledWithDarwinRebuildIfNeeded();
  }

  /// Remplit le pool match si vide / pas prêt — **sans** verrou (appel depuis
  /// [_preloadGameSfxOnce] déjà verrouillé ou via [_ensureMatchPool]).
  Future<void> _populateMatchPoolIfNeeded() async {
    if (_matchPoolReady) return;
    if (_disabled) return;

    if (_sfxMatchPool.isEmpty) {
      final bool apple =
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS;
      final int n = kIsWeb
          ? _matchPolyphonyWeb
          : (apple ? _matchPolyphonyApple : _matchPolyphony);
      for (int i = 0; i < n; i++) {
        _sfxMatchPool.add(
          AudioPlayer(playerId: 'velour_sfx_match_${_darwinMatchPoolGen}_$i'),
        );
      }
    }
    int readyCount = 0;
    for (final AudioPlayer p in _sfxMatchPool) {
      if (await _setupPooledSfxCore(player: p, fileName: _matchFile)) {
        readyCount++;
      }
    }
    if (readyCount == 0 && _darwinPooledSfx && _sfxMatchPool.isNotEmpty) {
      velourAudioTrace(
        'AudioHandler._populateMatchPoolIfNeeded: rebuild match pool after '
        'all load failures',
      );
      for (final AudioPlayer p in _sfxMatchPool) {
        try {
          await p.dispose();
        } catch (_) {}
      }
      _sfxMatchPool.clear();
      _darwinMatchPoolGen++;
      final int n = _matchPolyphonyApple;
      for (int i = 0; i < n; i++) {
        _sfxMatchPool.add(
          AudioPlayer(playerId: 'velour_sfx_match_${_darwinMatchPoolGen}_$i'),
        );
      }
      for (final AudioPlayer p in _sfxMatchPool) {
        if (await _setupPooledSfxCore(player: p, fileName: _matchFile)) {
          readyCount++;
        }
      }
    }
    _matchPoolReady = readyCount > 0;
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
    if (_darwinDisposableSfxMode) {
      unawaited(_playDisposableOneShot(_tapFile, volume: 0.8, holdMs: 220));
      return;
    }
    // iOS: le premier `resume()` d'un canal low-latency peut être silencieux même si
    // la source est prête. On "prime" une seule fois avec un one-shot audible.
    if (!_tapPrimedThisRun) {
      _tapPrimedThisRun = true;
      unawaited(_playDisposableOneShot(_tapFile, volume: 0.8, holdMs: 220));
      unawaited(_ensureTapReady());
      return;
    }
    // iOS: le 1er `resume()` du canal low-latency peut encore être silencieux.
    // On garantit au moins un tap audible avant de basculer 100% sur le canal.
    if (!_tapChannelConfirmedThisRun) {
      _tapChannelConfirmedThisRun = true;
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
    unawaited(_playTapFromChannel(volume: 0.8));
  }

  /// Combo classique : `sfx_match` pur, polyphonique, **sans** `setPlaybackRate`.
  void playMatchCombo() {
    if (_disabled) return;
    if (sfxMuted.value) return;
    unawaited(_playMatchExclusive(volume: 1.0));
  }

  /// Combo parfait : `sfx_perfect` (piste séparée).
  void playPerfectCombo() {
    if (_disabled) return;
    if (sfxMuted.value) return;
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
      unawaited(_playDisposableOneShot(_creditFile, volume: 1.0, holdMs: 450));
      unawaited(_ensureCreditReady());
      return;
    }
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
      await _withNativeSourceLoadLock(() => _playMusicCore(fileName));
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
      await _withNativeSourceLoadLock(() => _playMusicCore(fileName));
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
    // Ne pas await les stops du pool : en concurrence avec un setSource encore
    // bloqué (simulateur / session), await(stop) peut prolonger indéfiniment le
    // filet de fin de partie.
    for (final AudioPlayer p in _sfxMatchPool) {
      try {
        unawaited(p.stop());
      } catch (_) {}
    }
    try {
      unawaited(_sfxPerfect.stop());
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
    await _withNativeSourceLoadLock(() async {
      await configure();
      if (_disabled) return;
      await _populateMatchPoolIfNeeded();
    });
  }

  Future<void> _ensurePerfectPool() async {
    if (_perfectPoolReady) return;
    if (_disabled) return;
    await configure();
    if (_disabled) return;
    _perfectPoolReady = await _setupPooledSfx(
      player: _sfxPerfect,
      fileName: _perfectFile,
    );
  }

  Future<void> _ensureLevelUpReady() async {
    if (_levelUpReady) return;
    if (_disabled) return;
    await configure();
    if (_disabled) return;
    _levelUpReady = await _setupPooledSfx(
      player: _sfxLevelUp,
      fileName: _levelUpFile,
    );
  }

  Future<void> _ensureCreditReady() async {
    if (_creditReady) return;
    if (_disabled) return;
    await configure();
    if (_disabled) return;
    _creditReady = await _setupPooledSfx(
      player: _sfxCredit,
      fileName: _creditFile,
    );
  }

  Future<void> _ensureTapReady() async {
    if (_tapReady) return;
    if (_disabled) return;
    await _withNativeSourceLoadLock(() => _ensureTapReadyCore());
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
      if (_darwinDisposableSfxMode) {
        unawaited(_interruptMatchAndPerfect());
        unawaited(
          _playDisposableOneShot(
            _matchFile,
            volume: volume.clamp(0.0, 1.0),
            holdMs: 280,
          ),
        );
        return;
      }
      await _ensureMatchPool();
      if (_disabled) return;
      if (!_matchPoolReady) {
        unawaited(_interruptMatchAndPerfect());
        unawaited(
          _playDisposableOneShot(
            _matchFile,
            volume: volume.clamp(0.0, 1.0),
            holdMs: 280,
          ),
        );
        return;
      }
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
      if (_darwinDisposableSfxMode) {
        unawaited(_interruptMatchAndPerfect());
        unawaited(
          _playDisposableOneShot(_perfectFile, volume: 1.0, holdMs: 320),
        );
        return;
      }
      await _ensurePerfectPool();
      if (_disabled) return;
      if (!_perfectPoolReady) {
        unawaited(_interruptMatchAndPerfect());
        unawaited(
          _playDisposableOneShot(_perfectFile, volume: 1.0, holdMs: 320),
        );
        return;
      }
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
      if (_darwinDisposableSfxMode) {
        unawaited(
          _playDisposableOneShot(_perfectFile, volume: 0.28, holdMs: 220),
        );
        return;
      }
      await _ensurePerfectPool();
      if (_disabled) return;
      if (!_perfectPoolReady) {
        unawaited(
          _playDisposableOneShot(_perfectFile, volume: 0.28, holdMs: 220),
        );
        return;
      }
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
      if (_darwinDisposableSfxMode) {
        unawaited(
          _playDisposableOneShot(_creditFile, volume: 1.0, holdMs: 450),
        );
        return;
      }
      await _ensureCreditReady();
      if (_disabled) return;
      if (!_creditReady) {
        unawaited(
          _playDisposableOneShot(_creditFile, volume: 1.0, holdMs: 450),
        );
        return;
      }
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
      if (_darwinDisposableSfxMode) {
        return;
      }
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
      if (_darwinDisposableSfxMode) {
        unawaited(
          _playDisposableOneShot(_levelUpFile, volume: 1.0, holdMs: 3200),
        );
        return;
      }
      await _ensureLevelUpReady();
      if (_disabled) return;
      if (!_levelUpReady) {
        unawaited(
          _playDisposableOneShot(_levelUpFile, volume: 1.0, holdMs: 3200),
        );
        return;
      }

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
  Future<void> _playDisposableOneShotCore(
    String fileName, {
    required double volume,
    required int holdMs,
    double? playbackRate,
  }) async {
    await configure();
    if (_disabled) return;

    final AudioPlayer p = AudioPlayer();
    try {
      if (!kIsWeb) {
        await p.setAudioContext(velourGameAudioContext());
      }
      final bool appleOneShot =
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS);
      await p.setPlayerMode(
        appleOneShot ? PlayerMode.mediaPlayer : PlayerMode.lowLatency,
      );
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
  }

  Future<void> _playDisposableOneShot(
    String fileName, {
    required double volume,
    required int holdMs,
    double? playbackRate,
  }) async {
    try {
      await _withNativeSourceLoadLock(
        () => _playDisposableOneShotCore(
          fileName,
          volume: volume,
          holdMs: holdMs,
          playbackRate: playbackRate,
        ),
      );
    } catch (_) {
      // Intentionally silent.
    }
  }
}
