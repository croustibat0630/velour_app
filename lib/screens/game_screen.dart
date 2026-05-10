import 'dart:ui' show FilterQuality, ImageFilter;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:velour_app/l10n/app_localizations.dart';
import 'package:velour_app/l10n/game_float_messages.dart';
import 'package:velour_app/l10n/narrative_messages.dart';
import 'package:velour_app/theme/colors.dart';
import 'package:velour_app/theme/theme_engine.dart';
import 'package:velour_app/widgets/items/neon_crystal.dart';
import 'package:velour_app/widgets/items/neon_sphere.dart';
import 'package:velour_app/widgets/items/neon_pyramid.dart';
import 'package:velour_app/widgets/items/neon_star.dart';
import 'package:velour_app/widgets/items/neon_diamond.dart';
import 'package:velour_app/widgets/items/neon_pentagon.dart';
import 'package:velour_app/widgets/items/neon_hexastar.dart';
import 'package:velour_app/screens/preparation_view.dart';
import 'package:velour_app/widgets/ui/game_over_overlay.dart';
import 'package:velour_app/widgets/ui/neon_score_board.dart';
import 'package:velour_app/widgets/ui/narrative_tutorial_chrome.dart';
import 'package:velour_app/providers/game_state.dart';
import 'package:velour_app/models/game_item.dart';
import 'package:velour_app/widgets/ui/pause_overlay.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:velour_app/services/audio_handler.dart';
import 'package:velour_app/services/haptics_handler.dart';
import 'package:velour_app/widgets/items/gem_shape_paths.dart';
import 'package:velour_app/game/particle_system.dart';
import 'package:velour_app/utils/gem_accessibility.dart';
import 'package:velour_app/utils/rack_accessibility.dart';
import 'package:velour_app/utils/velour_accessibility.dart';
import 'dart:math' as math;

part 'game_screen_widgets.dart';
part 'game_screen_widgets_combo_rack.dart';
part 'game_screen_widgets_overlays.dart';
part 'game_screen_state_layout.dart';

/// Empreinte du rendu « plateau + chrome » de [GameScreen].
///
/// Les listes board/slot sont mutées en place : une simple égalité par référence
/// ne suffit pas. On mélange ici tout ce qui influence le grand `Stack`
/// (hors couches locales `_floating`, `_comboFloater`, `_matchParticle`, shake).
///
/// [NeonScoreBoard] écoute déjà `GameState.timeBar` en interne : pas besoin du
/// tick chrono dans cette empreinte.
int _gameScreenStaticUiFingerprint(GameState gs) {
  final List<Object?> parts = <Object?>[];
  final Set<String> alert = gs.alertIds;
  final Set<String> removing = gs.removingIds;

  void addItemFingerprint(GameItem e) {
    parts.add(e.id);
    parts.add(e.position.dx);
    parts.add(e.position.dy);
    parts.add(e.typeId);
    parts.add(e.colorId);
    parts.add(e.isSelected);
    parts.add(e.floatPeriodMs);
    parts.add(e.floatPhase);
    parts.add(gs.narrativeGuideGemShouldPulse(e.id));
    parts.add(gs.removalKindFor(e.id)?.index);
    parts.add(alert.contains(e.id));
    parts.add(removing.contains(e.id));
  }

  for (final GameItem e in gs.boardItems) {
    addItemFingerprint(e);
  }
  for (final GameItem e in gs.slotItems) {
    addItemFingerprint(e);
  }

  final List<int> imminent = gs.imminentSlotIdxs.toList()..sort();
  parts.addAll(imminent);

  final List<String> trio = gs.narrativeTrioIds.toList()..sort();
  parts.addAll(trio);

  parts.add(gs.currentSkin.primaryColor);
  parts.add(gs.currentSkin.secondaryColor);

  final NarrativeGemGainFx? ngx = gs.narrativeGemGainFx;
  if (ngx != null) {
    parts.add(ngx.id);
    parts.add(ngx.from.dx);
    parts.add(ngx.from.dy);
    parts.add(ngx.colorId);
  } else {
    parts.add(null);
  }

  final ({double level, double lux, double score, double time}) op =
      gs.narrativeHudOpacities;
  parts.add(op.level);
  parts.add(op.lux);
  parts.add(op.score);
  parts.add(op.time);

  parts.add(gs.criticalFailure);
  parts.add(gs.hasDeferredTimerGameOver);
  parts.add(gs.isProcessingMatch);
  parts.add(gs.isNarrativeTutorialActive);
  parts.add(gs.narrativePhase.index);
  parts.add(gs.postNarrativeSpawnFadeTick);
  parts.add(gs.narrativeGemFlightMs);
  parts.add(gs.narrativeRippleTick);
  parts.add(gs.narrativeRippleCenter?.dx);
  parts.add(gs.narrativeRippleCenter?.dy);
  parts.add(gs.narrativePerfectBannerTick);
  parts.add(gs.narrativeOracleDockMessageId.index);
  parts.add(gs.narrativeTutorialStepDotIndex);
  parts.add(gs.narrativeUiReveal);
  parts.add(gs.narrativeLuxIntroTick);
  parts.add(gs.trinityBannerId.index);
  parts.add(gs.tutorialBannerTick);
  parts.add(gs.isTrinityTutorialComplete);
  parts.add(gs.sequenceTick);
  parts.add(gs.gameLevel);
  parts.add(gs.lux);
  parts.add(gs.luxComboFlashTick);
  parts.add(gs.levelUpFlashTick);
  parts.add(gs.isLevelTransitionInProgress);
  parts.add(gs.gameOverFlashTick);
  parts.add(gs.hasPremiumStakeSession);
  parts.add(gs.isRoyalSession);
  parts.add(gs.isHighStakesSession);
  parts.add(gs.sessionStake.index);
  parts.add(gs.lastEndedRunStakeKind.index);
  parts.add(gs.lastStakeRewardLuxCoins);
  parts.add(gs.runMatchLuxRawTotal);
  parts.add(gs.lastGameWasPersonalBest);
  parts.add(gs.sessionStakeFooterLine.index);
  parts.add(gs.lastOracleInsuranceRefundLux);
  parts.add(gs.replaySuggestedStake?.index ?? -1);
  parts.add(gs.perfectHeatUiTick);
  parts.add(gs.perfectHeatGhostFlashTick);
  parts.add(gs.perfectHeatFreezeTick);
  parts.add(gs.perfectHeatSurgeTierDisplay);
  parts.add(gs.perfectHeatSurgeFlashTick);

  return Object.hashAll(parts);
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  GameState? _gameStateListenee;

  late final AnimationController _shakeController;
  late final AnimationController _flashController;
  late final AnimationController _bgDrift;

  int _lastFloatingTick = 0;
  FloatingTextFx? _floating;
  int _lastComboFloaterTick = 0;
  ComboFloaterFx? _comboFloater;
  int _lastMatchParticleTick = 0;
  MatchParticleFx? _matchParticle;
  late final AnimationController _matchParticleController;
  List<LuxDustSeed> _luxDustSeeds = const <LuxDustSeed>[];

  int _lastShakeTick = 0;
  double _shakeStrength = 0;
  bool _pulseUp = true;
  late final List<Offset> _dust;
  int _lastLevelUpTick = 0;
  int _lastHandledNarrativeReturnToMenuTick = 0;
  ({
    Rect playZoneRect,
    Rect luxSafeRect,
    double boardSpawnMinY,
    double itemSize,
    double slotSize,
    double gridGap,
    List<Offset> slotTopLefts,
  })?
  _lastLayout;

  /// Dernière empreinte « statique » pour éviter les rebuild storms sur [GameState.notifyListeners].
  int? _lastStaticUiFingerprint;

  @override
  void initState() {
    super.initState();
    // Menu / BGM must not bleed into active gameplay.
    AudioHandler.instance.stopMusic();
    AudioHandler.instance.resetSelectAudioWake();
    // Un seul préload après le frame : [AudioHandler.preloadGameSfx] sérialise
    // les appels ; un double déclenchement concurrent pouvait bloquer iOS
    // (deux setSource sur les mêmes players).
    //
    // Sur iPhone, `stop()` BGM + `setSource` pool en parallèle peut faire expirer
    // tout le préload (logs Darwin retry puis TIMEOUT sur tap/match/perfect).
    // On attend la fin du stop avant de lancer le préload.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AudioHandler.instance.stopMusic();
      if (!mounted) return;
      unawaited(AudioHandler.instance.preloadGameSfx());
      if (!mounted) return;
      context.read<GameState>().startGame();
    });
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flashController.addStatusListener((AnimationStatus status) {
      // Sécurité : le flash ne doit jamais “rester blanc”.
      if (status == AnimationStatus.completed) {
        _flashController.reset();
      }
    });
    _matchParticleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _bgDrift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    );

    final math.Random r = math.Random(42);
    _dust = List<Offset>.generate(
      14,
      (_) => Offset(r.nextDouble(), r.nextDouble()),
    );
  }

  void _detachGameStateListener() {
    _gameStateListenee?.removeListener(_handleGameStateForFx);
    _gameStateListenee = null;
  }

  /// Réactions HUD/FX/audio : hors du corps de [build], déclenchées par notifies du [GameState].
  void _handleGameStateForFx() {
    if (!mounted) return;
    final GameState gs = context.read<GameState>();

    bool needSetState = false;

    // Shake trigger
    if (gs.shakeTick != _lastShakeTick) {
      _lastShakeTick = gs.shakeTick;
      if (velourReduceMotion(context)) {
        _shakeStrength = 0;
        _shakeController.reset();
      } else {
        _shakeStrength = gs.shakeStrength;
        _shakeController
          ..reset()
          ..forward();
      }
    }

    if (gs.floatingTick != _lastFloatingTick) {
      _lastFloatingTick = gs.floatingTick;
      _floating = gs.floatingTextFx;
      needSetState = true;
    }
    if (gs.comboFloaterTick != _lastComboFloaterTick) {
      _lastComboFloaterTick = gs.comboFloaterTick;
      _comboFloater = gs.comboFloater;
      needSetState = true;
    }
    if (gs.matchParticleTick != _lastMatchParticleTick) {
      _lastMatchParticleTick = gs.matchParticleTick;
      _matchParticle = gs.matchParticleFx;
      if (_matchParticle != null) {
        _luxDustSeeds = _buildLuxDustSeeds(
          _matchParticle!,
          _matchParticle!.id.hashCode,
        );
        if (velourReduceMotion(context)) {
          _matchParticleController.duration = const Duration(milliseconds: 1);
          _matchParticleController.value = 1.0;
        } else {
          _matchParticleController.duration = _matchParticle!.perfectLuxBurst
              ? const Duration(milliseconds: 640)
              : const Duration(milliseconds: 520);
          _matchParticleController.forward(from: 0);
        }
        // Perf: le flash global est désactivé (coûteux + source de « white stuck »).
      } else {
        _luxDustSeeds = const <LuxDustSeed>[];
        _matchParticleController.reset();
      }
      needSetState = true;
    }

    if (gs.levelUpFlashTick != _lastLevelUpTick) {
      _lastLevelUpTick = gs.levelUpFlashTick;
      if (_lastLevelUpTick > 0) {
        AudioHandler.instance.playLevelUp();
      }
    }

    final int narrativeReturnTick = gs.narrativeTutorialReturnToMainMenuTick;
    if (narrativeReturnTick > 0 &&
        narrativeReturnTick != _lastHandledNarrativeReturnToMenuTick) {
      _lastHandledNarrativeReturnToMenuTick = narrativeReturnTick;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final GameState gs2 = context.read<GameState>();
        gs2.clearSessionStakeForMenu();
        gs2.resetGame();
        Navigator.of(context).pushReplacementNamed('/main');
      });
    }

    final int fp = _gameScreenStaticUiFingerprint(gs);
    final bool uiDirty =
        _lastStaticUiFingerprint == null || _lastStaticUiFingerprint != fp;
    _lastStaticUiFingerprint = fp;

    if (mounted && (needSetState || uiDirty)) {
      setState(() {});
    }
  }

  void _syncBgDriftMotion() {
    if (!mounted) return;
    if (velourReduceMotion(context)) {
      if (_bgDrift.isAnimating) {
        _bgDrift.stop();
      }
    } else if (!_bgDrift.isAnimating) {
      _bgDrift.repeat(reverse: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBgDriftMotion();
    final GameState gs = context.read<GameState>();
    if (_gameStateListenee != gs) {
      _detachGameStateListener();
      _gameStateListenee = gs..addListener(_handleGameStateForFx);
      // Initialise à partir de l'état courant (évite une frame « stale » après hot-restart).
      _handleGameStateForFx();
    }
  }

  @override
  void dispose() {
    _detachGameStateListener();
    _bgDrift.stop();
    _shakeController.dispose();
    _flashController.dispose();
    _matchParticleController.dispose();
    _bgDrift.dispose();
    super.dispose();
  }

  Offset _shakeOffset(double strengthMultiplier) {
    // Cheap pseudo-random jitter based on animation value.
    final double t = _shakeController.value;
    final double a = math.sin(t * math.pi * 18);
    final double b = math.cos(t * math.pi * 23);
    final double m = strengthMultiplier.clamp(0.0, 1.0);
    return Offset(a * _shakeStrength * m, b * _shakeStrength * m);
  }

  List<LuxDustSeed> _buildLuxDustSeeds(MatchParticleFx fx, int seed) =>
      buildLuxDustSeeds(fx, seed);

  void _toggleBackgroundPulseForAmbient() {
    if (!mounted) return;
    setState(() => _pulseUp = !_pulseUp);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeEngine themeEngine = context.watch<ThemeEngine>();
    // Rebuild plateau sur chaque notify GameState (évite scaffold figé). Ne pas
    // fusionner [GameState.timeBar] ici : ~20 ticks/s videraient le thread UI.
    final GameState gameState = context.watch<GameState>();
    return buildScreenFrame(context, themeEngine, gameState);
  }
}
