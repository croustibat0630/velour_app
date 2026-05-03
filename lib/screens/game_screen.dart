import 'dart:ui' show FilterQuality, ImageFilter;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:velour_app/l10n/app_localizations.dart';
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
import 'dart:math' as math;

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
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

  @override
  void initState() {
    super.initState();
    // Menu / BGM must not bleed into active gameplay.
    AudioHandler.instance.stopMusic();
    AudioHandler.instance.resetSelectAudioWake();
    // Force pool initialization ASAP so the first match isn't silent.
    // (Still safe on Web because we arrive here via user gesture navigation.)
    unawaited(AudioHandler.instance.preloadGameSfx());
    // Web: if cold-start preload failed, warm pooled SFX after navigation (user gesture path).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioHandler.instance.preloadGameSfx();
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
    )..repeat(reverse: true);

    final math.Random r = math.Random(42);
    _dust = List<Offset>.generate(
      14,
      (_) => Offset(r.nextDouble(), r.nextDouble()),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _flashController.dispose();
    _matchParticleController.dispose();
    _bgDrift.dispose();
    super.dispose();
  }

  Offset _shakeOffset() {
    // Cheap pseudo-random jitter based on animation value.
    final double t = _shakeController.value;
    final double a = math.sin(t * math.pi * 18);
    final double b = math.cos(t * math.pi * 23);
    return Offset(a * _shakeStrength, b * _shakeStrength);
  }

  List<LuxDustSeed> _buildLuxDustSeeds(MatchParticleFx fx, int seed) =>
      buildLuxDustSeeds(fx, seed);

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameState, ThemeEngine>(
      builder: (context, gameState, themeEngine, _) {
        Color neonColor(int colorId) => themeEngine.colorForId(colorId);
        // Shake trigger
        if (gameState.shakeTick != _lastShakeTick) {
          _lastShakeTick = gameState.shakeTick;
          _shakeStrength = gameState.shakeStrength;
          _shakeController
            ..reset()
            ..forward();
        }

        if (gameState.floatingTick != _lastFloatingTick) {
          _lastFloatingTick = gameState.floatingTick;
          _floating = gameState.floatingTextFx;
        }
        if (gameState.comboFloaterTick != _lastComboFloaterTick) {
          _lastComboFloaterTick = gameState.comboFloaterTick;
          _comboFloater = gameState.comboFloater;
        }
        if (gameState.matchParticleTick != _lastMatchParticleTick) {
          _lastMatchParticleTick = gameState.matchParticleTick;
          _matchParticle = gameState.matchParticleFx;
          if (_matchParticle != null) {
            _luxDustSeeds = _buildLuxDustSeeds(
              _matchParticle!,
              _matchParticle!.id.hashCode,
            );
            _matchParticleController.duration = _matchParticle!.perfectLuxBurst
                ? const Duration(milliseconds: 640)
                : const Duration(milliseconds: 520);
            _matchParticleController.forward(from: 0);
            // Perf: le flash global est désactivé (coûteux + source de “white stuck”).
          } else {
            _luxDustSeeds = const <LuxDustSeed>[];
            _matchParticleController.reset();
          }
        }

        if (gameState.levelUpFlashTick != _lastLevelUpTick) {
          _lastLevelUpTick = gameState.levelUpFlashTick;
          if (_lastLevelUpTick > 0) {
            AudioHandler.instance.playLevelUp();
          }
        }

        return AnimatedBuilder(
          animation: Listenable.merge([
            _shakeController,
            _flashController,
            _matchParticleController,
          ]),
          builder: (context, child) {
            return Transform.translate(offset: _shakeOffset(), child: child);
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF0A0A0F),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const double slotPaddingH = 12;

                  // Universal layout: scale sizes with screen width (mobile/tablet).
                  final double uiScale = (constraints.maxWidth / 420).clamp(
                    0.85,
                    1.25,
                  );
                  final double slotBarHeight = (100 * uiScale).clamp(
                    88.0,
                    130.0,
                  );
                  final double slotSize = (GameState.baseSlotSize * uiScale)
                      .clamp(38.0, 60.0);
                  final double itemSize = slotSize;
                  final double gridGap = (GameState.baseGridGap * uiScale)
                      .clamp(4.0, 10.0);

                  final double width = constraints.maxWidth;
                  final double height = constraints.maxHeight;
                  final double playZoneHeight = (height - slotBarHeight).clamp(
                    0,
                    height,
                  );

                  final Rect playZoneRect = Rect.fromLTWH(
                    0,
                    0,
                    width,
                    playZoneHeight,
                  );

                  // HUD (full width, 2 colonnes) + zone sûre + spawn floor.
                  // High stakes: bandeau objectif au-dessus du score.
                  final double luxBoardTop = gameState.hasPremiumStakeSession
                      ? 40
                      : 10;
                  const double luxSafePadding = 16;
                  const double hudHeight = 110;
                  final double narrativeOracleW = math.min(width * 0.92, 440);
                  final Rect luxBoardRect = Rect.fromLTWH(
                    0,
                    luxBoardTop,
                    width,
                    hudHeight,
                  );
                  final Rect luxSafeRect = luxBoardRect.inflate(luxSafePadding);
                  final double boardSpawnMinY = luxBoardRect.bottom + 50;

                  final double available = (width - (slotPaddingH * 2)).clamp(
                    0,
                    width,
                  );
                  final double gap =
                      (available - (slotSize * GameState.slotCount)) /
                      (GameState.slotCount - 1);
                  final double slotTop =
                      playZoneHeight + (slotBarHeight - slotSize) / 2;

                  final List<Offset> slotTopLefts = List<Offset>.generate(
                    GameState.slotCount,
                    (i) {
                      final double left = slotPaddingH + i * (slotSize + gap);
                      return Offset(left, slotTop);
                    },
                  );

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.read<GameState>().setLayout(
                      playZoneRect: playZoneRect,
                      slotTopLefts: slotTopLefts,
                      luxSafeRect: luxSafeRect,
                      boardSpawnMinY: boardSpawnMinY,
                      itemSize: itemSize,
                      slotSize: slotSize,
                      gridGap: gridGap,
                    );
                  });

                  final List<GameItem> items =
                      [...gameState.boardItems, ...gameState.slotItems]
                        ..sort((a, b) {
                          final int sa = a.isSelected ? 1 : 0;
                          final int sb = b.isSelected ? 1 : 0;
                          return sa.compareTo(sb);
                        });

                  final bool narrativeStep3Dim =
                      gameState.narrativePhase ==
                      NarrativeTutorialPhase.step3Perfect;
                  final Set<String> narrativeTrio = gameState.narrativeTrioIds;

                  return Stack(
                    children: [
                      // Fond : léger drift du centre (premium, sans distraire du jeu).
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _bgDrift,
                            builder: (BuildContext context, Widget? _) {
                              final double t = _bgDrift.value * math.pi * 2;
                              final Alignment center = Alignment(
                                0.038 * math.sin(t),
                                0.10 + 0.028 * math.cos(t * 0.73),
                              );
                              return DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: center,
                                    radius: 1.2,
                                    colors: const <Color>[
                                      Color(0xFF0B1020),
                                      Color(0xFF000000),
                                    ],
                                    stops: const <double>[0.0, 1.0],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: _pulseUp ? 0.2 : 0.4,
                              end: _pulseUp ? 0.4 : 0.2,
                            ),
                            duration: const Duration(seconds: 4),
                            onEnd: () {
                              if (!gameState.criticalFailure) {
                                setState(() => _pulseUp = !_pulseUp);
                              }
                            },
                            builder: (context, pulseT, _) {
                              if (!gameState.hasPremiumStakeSession) {
                                return DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      center: const Alignment(0, 0.10),
                                      radius: 1.2,
                                      colors: [
                                        NeonColors.cyan.withValues(
                                          alpha: pulseT,
                                        ),
                                        const Color(0x00000000),
                                      ],
                                      stops: const [0.0, 1.0],
                                    ),
                                  ),
                                );
                              }
                              final double u = ((pulseT - 0.2) / 0.2).clamp(
                                0.0,
                                1.0,
                              );
                              if (gameState.isRoyalSession) {
                                // Vignette violet néon (bords), plus marquée que l’or.
                                final double edgeA = 0.14 + 0.12 * u;
                                return DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      center: Alignment.center,
                                      radius: 1.42,
                                      colors: [
                                        const Color(0x00000000),
                                        const Color(
                                          0xFF9D50BB,
                                        ).withValues(alpha: edgeA),
                                        const Color(
                                          0xFF6E48AA,
                                        ).withValues(alpha: edgeA * 0.82),
                                      ],
                                      stops: const [0.62, 0.88, 1.0],
                                    ),
                                  ),
                                );
                              }
                              // Vignette dorée sur les bords (centre transparent → or léger).
                              final double edgeA = 0.10 + 0.08 * u;
                              return DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 1.38,
                                    colors: [
                                      const Color(0x00000000),
                                      const Color(
                                        0xFFFFD700,
                                      ).withValues(alpha: edgeA),
                                    ],
                                    stops: const [0.70, 1.0],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // Space dust (very subtle)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: LayoutBuilder(
                            builder: (context, c) {
                              return Stack(
                                children: [
                                  for (final p in _dust)
                                    Positioned(
                                      left: p.dx * c.maxWidth,
                                      top: p.dy * c.maxHeight,
                                      child: Container(
                                        width: 1,
                                        height: 1,
                                        color: Colors.white.withValues(
                                          alpha: 0.06,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      if (gameState.isNarrativeTutorialActive)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: const NarrativeTutorialAmbientLayer(),
                          ),
                        ),
                      AbsorbPointer(
                        absorbing:
                            gameState.criticalFailure ||
                            gameState.isProcessingMatch,
                        child: Column(
                          children: [
                            const Expanded(
                              child: IgnorePointer(child: _PlayZone()),
                            ),
                            _SlotBar(
                              imminentSlotIdxs: gameState.imminentSlotIdxs,
                              accent: gameState.isRoyalSession
                                  ? const Color(0xFF9D50BB)
                                  : gameState.isHighStakesSession
                                  ? const Color(0xFFFFD700)
                                  : NeonColors.cyan,
                              premium: gameState.hasPremiumStakeSession,
                            ),
                          ],
                        ),
                      ),
                      AbsorbPointer(
                        absorbing:
                            gameState.criticalFailure ||
                            gameState.isProcessingMatch,
                        child: RepaintBoundary(
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey<int>(
                              gameState.postNarrativeSpawnFadeTick,
                            ),
                            tween: Tween<double>(
                              begin: gameState.postNarrativeSpawnFadeTick == 0
                                  ? 1.0
                                  : 0.0,
                              end: 1.0,
                            ),
                            duration: gameState.postNarrativeSpawnFadeTick == 0
                                ? Duration.zero
                                : const Duration(milliseconds: 780),
                            curve: Curves.easeOutCubic,
                            builder: (context, double fade, Widget? child) {
                              return Opacity(opacity: fade, child: child);
                            },
                            child: Stack(
                              children: [
                                for (final item in items)
                                  AnimatedPositioned(
                                    key: ValueKey(item.id),
                                    duration: Duration(
                                      milliseconds:
                                          gameState.narrativeGemFlightMs,
                                    ),
                                    curve: Curves.easeInOutCubic,
                                    left: item.position.dx,
                                    top: item.position.dy,
                                    width: itemSize,
                                    height: itemSize,
                                    child: Opacity(
                                      opacity:
                                          narrativeStep3Dim &&
                                              !narrativeTrio.contains(item.id)
                                          ? 0.34
                                          : 1.0,
                                      child: _NarrativeTargetGemPulse(
                                        active: gameState
                                            .narrativeGuideGemShouldPulse(
                                              item.id,
                                            ),
                                        child: FloatingGem(
                                          enabled: gameState.boardItems.any(
                                            (e) => e.id == item.id,
                                          ),
                                          floatPeriodMs: item.floatPeriodMs,
                                          floatPhase: item.floatPhase,
                                          size: itemSize,
                                          child: _GemTapJuice(
                                            isOnBoard: gameState.boardItems.any(
                                              (e) => e.id == item.id,
                                            ),
                                            typeId: item.typeId,
                                            neon: neonColor(item.colorId),
                                            stakeTapTraceColor:
                                                gameState.isHighStakesSession
                                                ? const Color(0xFFFFD700)
                                                : gameState.isRoyalSession
                                                ? const Color(0xFFE49BFF)
                                                : null,
                                            stakeTapParticleBoost:
                                                gameState.isRoyalSession
                                                ? 1.22
                                                : 1.0,
                                            onSelect: () =>
                                                gameState.selectItem(item.id),
                                            child: _ItemFx(
                                              id: item.id,
                                              isRemoving: gameState.removingIds
                                                  .contains(item.id),
                                              kind: gameState.removalKindFor(
                                                item.id,
                                              ),
                                              typeId: item.typeId,
                                              neon: neonColor(item.colorId),
                                              child: _NeonHalo(
                                                color: neonColor(item.colorId),
                                                alert: gameState.alertIds
                                                    .contains(item.id),
                                                lowGlow:
                                                    gameState
                                                        .isTrinityTutorialActive ||
                                                    gameState
                                                        .isNarrativeTutorialActive,
                                                child: _itemWidget(
                                                  item,
                                                  itemSize,
                                                  neonColor(item.colorId),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (gameState.isNarrativeTutorialActive &&
                          !(gameState.narrativePhase ==
                                  NarrativeTutorialPhase.celebration &&
                              gameState.narrativePerfectBannerTick > 0))
                        Positioned(
                          left: (width - narrativeOracleW) * 0.5,
                          width: narrativeOracleW,
                          bottom:
                              slotBarHeight +
                              (22 * uiScale) +
                              6 +
                              MediaQuery.paddingOf(context).bottom,
                          child: NarrativeOracleMessageBar(
                            messageId: gameState.narrativeOracleDockMessageId,
                            accent: gameState.currentSkin.primaryColor,
                            secondary: gameState.currentSkin.secondaryColor,
                            tutorialStepIndex:
                                gameState.narrativeTutorialStepDotIndex,
                          ),
                        ),
                      if (gameState.narrativeRippleCenter != null &&
                          gameState.narrativeRippleTick > 0)
                        NarrativeTapShockwave(
                          key: ValueKey<int>(gameState.narrativeRippleTick),
                          center: gameState.narrativeRippleCenter!,
                        ),
                      if (gameState.narrativePhase ==
                              NarrativeTutorialPhase.celebration &&
                          gameState.narrativePerfectBannerTick > 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: _NarrativePerfectCelebrationBanner(
                              key: ValueKey<int>(
                                gameState.narrativePerfectBannerTick,
                              ),
                            ),
                          ),
                        ),
                      if (gameState.trinityBannerId != TrinityBannerId.none &&
                          !gameState.isNarrativeTutorialActive)
                        Positioned(
                          left: width * 0.10,
                          width: width * 0.80,
                          // Ancrée au-dessus du rack (évite de recouvrir les gemmes).
                          bottom: (slotBarHeight + (16 * uiScale)).clamp(
                            96.0,
                            height * 0.40,
                          ),
                          child: IgnorePointer(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 420),
                              switchInCurve: Curves.easeOutCubic,
                              child: Material(
                                key: ValueKey<int>(
                                  gameState.tutorialBannerTick,
                                ),
                                color: Colors.black.withValues(alpha: 0.60),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    resolveTrinityBanner(
                                      AppLocalizations.of(context)!,
                                      gameState.trinityBannerId,
                                    ),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 0.92,
                                          ),
                                          height: 1.35,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_floating != null &&
                          !(gameState.narrativePhase ==
                                  NarrativeTutorialPhase.celebration &&
                              gameState.narrativePerfectBannerTick > 0))
                        Positioned.fill(
                          child: IgnorePointer(
                            child: _FloatingText(
                              key: ValueKey(_floating!.id),
                              text: _floating!.text,
                              narrativeFloatKey: _floating!.narrativeFloatKey,
                              position: _floating!.position,
                              color: neonColor(_floating!.colorId),
                              spectacularBurst:
                                  _floating!.isNarrativePerfectBurst,
                            ),
                          ),
                        ),
                      if (gameState.narrativeGemGainFx != null)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: _NarrativeGemGainFloater(
                              key: ValueKey<String>(
                                gameState.narrativeGemGainFx!.id,
                              ),
                              from: gameState.narrativeGemGainFx!.from,
                              color: neonColor(
                                gameState.narrativeGemGainFx!.colorId,
                              ),
                            ),
                          ),
                        ),
                      if (_comboFloater != null)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: _ComboFloater(
                              key: ValueKey(_comboFloater!.id),
                              text: _comboFloater!.text,
                              position: _comboFloater!.position,
                              accent: neonColor(2),
                            ),
                          ),
                        ),
                      if (_matchParticle != null)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: LuxDustPainter(
                                  center: _matchParticle!.center,
                                  primary: gameState.currentSkin.primaryColor,
                                  secondary:
                                      gameState.currentSkin.secondaryColor,
                                  t: _matchParticleController.value,
                                  seeds: _luxDustSeeds,
                                  perfectBurst: _matchParticle!.perfectLuxBurst,
                                  flashRadius: itemSize * 0.95,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Menu isolé (haut gauche), en dehors du HUD.
                      Positioned(
                        top: 8,
                        left: 8,
                        child: SafeArea(
                          bottom: false,
                          child: Material(
                            type: MaterialType.transparency,
                            child: IconButton(
                              tooltip: AppLocalizations.of(context)!.gameHudMenuTooltip,
                              onPressed: () async {
                                if (!context.mounted) return;
                                AudioHandler.instance.playMenuClick();
                                context.read<GameState>().setPaused(true);
                                await showDialog<void>(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (context) {
                                    return PauseOverlay(
                                      onContinue: () =>
                                          Navigator.of(context).pop(),
                                      onBackToMenu: () {
                                        Navigator.of(context).pop();
                                        context
                                            .read<GameState>()
                                            .clearSessionStakeForMenu();
                                        context.read<GameState>().resetGame();
                                        Navigator.of(
                                          context,
                                        ).pushReplacementNamed('/main');
                                      },
                                    );
                                  },
                                );
                                if (!context.mounted) return;
                                context.read<GameState>().setPaused(false);
                              },
                              icon: Icon(
                                Icons.menu_rounded,
                                size: 19,
                                color: Colors.white.withValues(alpha: 0.60),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (gameState.hasPremiumStakeSession)
                        Positioned(
                          top: 8,
                          left: 48,
                          right: 12,
                          child: IgnorePointer(
                            child: Center(
                              child: _StakeObjectiveStrip(
                                stake: gameState.sessionStake,
                                gameLevel: gameState.gameLevel,
                              ),
                            ),
                          ),
                        ),
                      // HUD full-width : alignement verrouillé dans `NeonScoreBoard` (Row center).
                      Positioned(
                        left: 0,
                        right: 0,
                        top: luxBoardTop,
                        child: Builder(
                          builder: (context) {
                            final ({
                              double level,
                              double lux,
                              double score,
                              double time,
                            })
                            op = gameState.narrativeHudOpacities;
                            return AnimatedOpacity(
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeOutCubic,
                              opacity:
                                  gameState.isNarrativeTutorialActive &&
                                      gameState.narrativeUiReveal == 0
                                  ? 0.0
                                  : 1.0,
                              child: NeonScoreBoard(
                                gameLevel: gameState.gameLevel,
                                lux: gameState.lux,
                                comboFlashTick: gameState.luxComboFlashTick,
                                luxIntroTick: gameState.narrativeLuxIntroTick,
                                levelUpFlashTick: gameState.levelUpFlashTick,
                                maxWidth: 500,
                                levelOpacity: op.level,
                                luxOpacity: op.lux,
                                scoreColumnOpacity: op.score,
                                timeColumnOpacity: op.time,
                              ),
                            );
                          },
                        ),
                      ),
                      if (gameState.criticalFailure)
                        Positioned.fill(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _GameOverRedFlash(
                                tick: gameState.gameOverFlashTick,
                              ),
                              Builder(
                                builder: (context) {
                                  final GameState gs = gameState;
                                  final ThemeEngine te = context
                                      .watch<ThemeEngine>();
                                  final SessionStakeKind ended =
                                      gs.lastEndedRunStakeKind;
                                  final double? prestigeMult =
                                      ended == SessionStakeKind.highStakes &&
                                          gs.gameLevel >=
                                              GameState.highStakesTargetLevel
                                      ? 1.5
                                      : ended == SessionStakeKind.royal &&
                                            gs.gameLevel >=
                                                GameState.royalTargetLevel
                                      ? 3.0
                                      : null;
                                  final bool isPremiumWin =
                                      gs.lastStakeRewardLuxCoins > 0;
                                  final Color recordAccent =
                                      ended == SessionStakeKind.royal
                                      ? const Color(0xFFE49BFF)
                                      : ended == SessionStakeKind.highStakes
                                      ? const Color(0xFFFFD700)
                                      : te.colorForId(1);
                                  return GameOverOverlay(
                                    rawMatchLuxTotal: gs.runMatchLuxRawTotal,
                                    finalLux: gs.lux,
                                    finalLevel: gs.gameLevel,
                                    endedStakeKind: ended,
                                    prestigeMultiplier: prestigeMult,
                                    stakeRewardLuxCoins:
                                        gs.lastStakeRewardLuxCoins,
                                    isPremiumWin: isPremiumWin,
                                    isPersonalBest: gs.lastGameWasPersonalBest,
                                    recordAccentColor: recordAccent,
                                    sessionStakeFooter:
                                        gs.sessionStakeFooterLine,
                                    onReplay: () async {
                                      final SessionStakeKind stake =
                                          gs.replaySuggestedStake ??
                                          SessionStakeKind.casual;
                                      context.read<GameState>().resetGame();
                                      _shakeController.stop();
                                      _flashController.reset();
                                      if (!context.mounted) return;
                                      Navigator.of(context).pushReplacement(
                                        fadeRoute(
                                          PreparationView(initialStake: stake),
                                        ),
                                      );
                                    },
                                    onMenu: () {
                                      context
                                          .read<GameState>()
                                          .clearSessionStakeForMenu();
                                      context.read<GameState>().resetGame();
                                      Navigator.of(
                                        context,
                                      ).pushReplacementNamed('/main');
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      if (gameState.isLevelTransitionInProgress)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: _LevelUpFlash(
                              tick: gameState.levelUpFlashTick,
                              level: gameState.gameLevel,
                            ),
                          ),
                        ),
                      if (gameState.isLevelTransitionInProgress)
                        const Positioned.fill(
                          child: IgnorePointer(child: _LevelUpLuxBurst()),
                        ),
                      if (!gameState.isTrinityTutorialComplete &&
                          gameState.sequenceTick > 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: _SequenceCompletedFlash(
                              tick: gameState.sequenceTick,
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: _flashController.value == 0,
                          child: AnimatedBuilder(
                            animation: _flashController,
                            builder: (context, _) {
                              final double v = Curves.easeInOutCubic.transform(
                                _flashController.value,
                              );
                              return ColoredBox(
                                color: Colors.white.withValues(alpha: 0.40 * v),
                              );
                            },
                          ),
                        ),
                      ),
                      // Lueur "plafonnier" (haut de l'écran)
                      Positioned(
                        left: 0,
                        top: 0,
                        right: 0,
                        height: 50,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x0DFFFFFF), // white @ 0.05
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget _itemWidget(GameItem item, double size, Color neon) {
  return switch (item.typeId) {
    1 => NeonCrystal(neon: neon, size: size),
    2 => NeonSphere(neon: neon, size: size),
    3 => NeonPyramid(neon: neon, size: size),
    4 => NeonStar(neon: neon, size: size),
    5 => NeonDiamond(neon: neon, size: size),
    6 => NeonPentagon(neon: neon, size: size),
    7 => NeonHexaStar(neon: neon, size: size),
    _ => NeonCrystal(neon: neon, size: size),
  };
}

/// Tactile “pop” + color flash before a board piece commits to the slot queue.
class _GemTapJuice extends StatefulWidget {
  const _GemTapJuice({
    required this.isOnBoard,
    required this.typeId,
    required this.neon,
    required this.onSelect,
    required this.child,
    this.stakeTapTraceColor,
    this.stakeTapParticleBoost = 1.0,
  });

  final bool isOnBoard;
  final int typeId;
  final Color neon;
  final Future<void> Function() onSelect;
  final Widget child;

  /// High Stakes / Royal : liséré + particules au tap (plateau).
  final Color? stakeTapTraceColor;
  final double stakeTapParticleBoost;

  @override
  State<_GemTapJuice> createState() => _GemTapJuiceState();
}

class _GemTapJuiceState extends State<_GemTapJuice>
    with TickerProviderStateMixin {
  late final AnimationController _pop;
  late final CurvedAnimation _popCurved;
  late final AnimationController _goldTrace;
  int _dustSeed = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _popCurved = CurvedAnimation(parent: _pop, curve: Curves.easeOutCubic);
    _goldTrace = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  @override
  void dispose() {
    _popCurved.dispose();
    _pop.dispose();
    _goldTrace.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_busy) return;
    if (!widget.isOnBoard) {
      await widget.onSelect();
      return;
    }
    _busy = true;
    await _pop.forward(from: 0);
    if (!mounted) return;
    await widget.onSelect();
    _pop.reset();
    _busy = false;
  }

  @override
  Widget build(BuildContext context) {
    final Color c = widget.neon;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        // Immediate select feedback on press (not release).
        AudioHandler.instance.playGemSelect();
        AudioHandler.instance.primeMatchPoolOnFirstUserTap();
        HapticsHandler.instance.selectionClick();
        if (widget.stakeTapTraceColor != null && widget.isOnBoard) {
          _dustSeed++;
          _goldTrace.forward(from: 0);
        }
      },
      onTap: _handleTap,
      child: SizedBox.expand(
        child: AnimatedBuilder(
          animation: Listenable.merge([_pop, _goldTrace]),
          builder: (context, child) {
            final double t = _popCurved.value;
            final double scale = 1.0 + 0.2 * t;
            final double flash = (math.sin(math.pi * t) * 0.34).clamp(0.0, 1.0);
            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  child: child,
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: flash,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.42),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.stakeTapTraceColor != null && widget.isOnBoard)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: StakeGemTapFxPainter(
                          typeId: widget.typeId,
                          t: _goldTrace.value,
                          particleSeed: _dustSeed,
                          accentColor: widget.stakeTapTraceColor!,
                          particleBoost: widget.stakeTapParticleBoost,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

class _ItemFx extends StatefulWidget {
  const _ItemFx({
    required this.id,
    required this.isRemoving,
    required this.kind,
    required this.typeId,
    required this.neon,
    required this.child,
  });

  final String id;
  final bool isRemoving;
  final MatchKind? kind;
  final int typeId;
  final Color neon;
  final Widget child;

  @override
  State<_ItemFx> createState() => _ItemFxState();
}

class _ItemFxState extends State<_ItemFx> with TickerProviderStateMixin {
  late final AnimationController _implode;
  late final AnimationController _particles;
  List<Offset>? _sparkOffsets;
  bool _sparkBurstActive = false;

  @override
  void initState() {
    super.initState();
    _implode = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _particles = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _particles.addStatusListener(_onParticlesStatus);
  }

  void _onParticlesStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (!mounted) return;
      setState(() {
        _sparkBurstActive = false;
        _sparkOffsets = null;
      });
      _particles.reset();
    }
  }

  @override
  void didUpdateWidget(covariant _ItemFx oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isRemoving && widget.isRemoving) {
      final int count = widget.kind == MatchKind.perfect ? 16 : 5;
      final double spread = widget.kind == MatchKind.perfect ? 46 : 28;
      final math.Random rnd = math.Random(widget.id.hashCode ^ 0x1a2b3c4d);
      _sparkOffsets = List<Offset>.generate(count, (_) {
        return Offset(
          (rnd.nextDouble() - 0.5) * spread,
          (rnd.nextDouble() - 0.5) * spread,
        );
      });
      _sparkBurstActive = true;
      _implode.forward(from: 0);
      _particles.forward(from: 0);
    }
    if (oldWidget.isRemoving && !widget.isRemoving) {
      _implode.reset();
      _particles.reset();
      _sparkOffsets = null;
      _sparkBurstActive = false;
    }
  }

  @override
  void dispose() {
    _particles.removeStatusListener(_onParticlesStatus);
    _implode.dispose();
    _particles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isRemoving) {
      return widget.child;
    }

    final Color flashColor = widget.neon;
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_implode, _particles]),
      builder: (context, _) {
        final double u = Curves.easeIn.transform(_implode.value);
        final double scale = (1.0 - u).clamp(0.0, 1.0);
        final double opacity = (1.0 - u * 0.92).clamp(0.0, 1.0);
        final double pt = Curves.easeOut.transform(_particles.value);
        final bool perfect = widget.kind == MatchKind.perfect;

        return SizedBox.expand(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: <Widget>[
              Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  child: widget.child,
                ),
              ),
              if (_sparkBurstActive && _sparkOffsets != null)
                for (int i = 0; i < _sparkOffsets!.length; i++)
                  Transform.translate(
                    offset:
                        _sparkOffsets![i] +
                        Offset(0, -(perfect ? 70 : 46) * pt),
                    child: Opacity(
                      opacity: (1 - pt).clamp(0.0, 1.0),
                      child: Container(
                        width: perfect ? 6 : 4,
                        height: perfect ? 6 : 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: flashColor.withValues(alpha: 0.92),
                          boxShadow: [
                            BoxShadow(
                              color: flashColor.withValues(alpha: 0.55),
                              blurRadius: perfect ? 10 : 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _NeonHalo extends StatelessWidget {
  const _NeonHalo({
    required this.color,
    required this.alert,
    required this.child,
    this.lowGlow = false,
  });

  final Color color;
  final bool alert;
  final Widget child;
  final bool lowGlow;

  @override
  Widget build(BuildContext context) {
    final double a = lowGlow ? 0.22 : 0.45;
    final double blur = lowGlow ? 8 : 15;
    final double spread = lowGlow ? 0.0 : 1.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: a),
            blurRadius: blur,
            spreadRadius: spread,
          ),
          if (alert)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.22),
              blurRadius: 10,
              spreadRadius: 0,
            ),
        ],
      ),
      child: child,
    );
  }
}

class FloatingGem extends StatefulWidget {
  const FloatingGem({
    super.key,
    required this.enabled,
    required this.floatPeriodMs,
    required this.floatPhase,
    required this.size,
    required this.child,
  });

  final bool enabled;
  final int floatPeriodMs;
  final double floatPhase;
  final double size;
  final Widget child;

  @override
  State<FloatingGem> createState() => _FloatingGemState();
}

class _FloatingGemState extends State<FloatingGem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.floatPeriodMs),
      value: widget.floatPhase.clamp(0.0, 0.999999),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant FloatingGem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.floatPeriodMs != oldWidget.floatPeriodMs) {
      _c.duration = Duration(milliseconds: widget.floatPeriodMs);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final double t = Curves.easeInOutSine.transform(_c.value); // 0..1
        final double y = (t - 0.5) * 2 * 7.0; // +/- 7px
        final double s = (widget.size > 0) ? widget.size : 60.0;
        return SizedBox(
          width: s,
          height: s,
          child: RepaintBoundary(
            child: Transform.translate(offset: Offset(0, y), child: child!),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// « +1 » qui monte vers la zone score (tutoriel narratif).
class _NarrativeGemGainFloater extends StatefulWidget {
  const _NarrativeGemGainFloater({
    super.key,
    required this.from,
    required this.color,
  });

  final Offset from;
  final Color color;

  @override
  State<_NarrativeGemGainFloater> createState() =>
      _NarrativeGemGainFloaterState();
}

class _NarrativeGemGainFloaterState extends State<_NarrativeGemGainFloater>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size sz = MediaQuery.sizeOf(context);
    final double padT = MediaQuery.paddingOf(context).top;
    final Offset to = Offset(sz.width - 52, padT + 58);
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? child) {
        final double t = Curves.easeOut.transform(_c.value);
        final Offset a = widget.from;
        final Offset mid = Offset(a.dx + (to.dx - a.dx) * 0.45, a.dy - 36);
        final Offset p = Offset.lerp(
          Offset.lerp(a, mid, t)!,
          Offset.lerp(mid, to, t)!,
          t,
        )!;
        final double o = (1.0 - t * 1.08).clamp(0.0, 1.0);
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned(
              left: p.dx,
              top: p.dy,
              child: Opacity(
                opacity: o,
                child: Text(
                  '+1',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: widget.color.withValues(alpha: 0.95),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FloatingText extends StatefulWidget {
  const _FloatingText({
    super.key,
    required this.text,
    this.narrativeFloatKey,
    required this.position,
    required this.color,
    this.spectacularBurst = false,
  });

  final String text;
  final NarrativeFloatingKey? narrativeFloatKey;
  final Offset position;
  final Color color;
  final bool spectacularBurst;

  @override
  State<_FloatingText> createState() => _FloatingTextState();
}

class _FloatingTextState extends State<_FloatingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.spectacularBurst ? 980 : 700),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String displayText = widget.narrativeFloatKey != null
        ? resolveNarrativeFloating(
            AppLocalizations.of(context)!,
            widget.narrativeFloatKey!,
          )
        : widget.text;
    final bool burst = widget.spectacularBurst;
    const Color gold = Color(0xFFFFD700);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final double rawT = Curves.easeOutCubic.transform(_c.value);
            final double t = burst
                ? Curves.elasticOut.transform(_c.value.clamp(0.0, 1.0))
                : rawT;
            final double rise = burst ? 42 : 30;
            final Offset p = widget.position + Offset(0, -rise * rawT);
            final double opacity = (1 - rawT * (burst ? 0.88 : 1.0)).clamp(
              0.0,
              1.0,
            );
            final double scale = burst ? (0.52 + 0.58 * t) : 1.0;
            final TextStyle style = burst
                ? GoogleFonts.montserrat(
                    fontSize: 21,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: gold.withValues(alpha: 0.96),
                    shadows: [
                      Shadow(
                        color: gold.withValues(alpha: 0.75),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                      Shadow(
                        color: gold.withValues(alpha: 0.55),
                        blurRadius: 22,
                      ),
                      Shadow(
                        color: const Color(0xFFFFA000).withValues(alpha: 0.45),
                        blurRadius: 36,
                      ),
                    ],
                  )
                : TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: widget.color.withValues(alpha: 0.95),
                    shadows: [
                      Shadow(
                        color: widget.color.withValues(alpha: 0.55),
                        blurRadius: 12,
                      ),
                    ],
                  );
            return Positioned(
              left: p.dx,
              top: p.dy,
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.centerLeft,
                  child: Text(displayText, style: style),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// LUX Dust a été extrait dans `lib/game/particle_system.dart`.

class _ComboFloater extends StatefulWidget {
  const _ComboFloater({
    super.key,
    required this.text,
    required this.position,
    required this.accent,
  });

  final String text;
  final Offset position;
  final Color accent;

  @override
  State<_ComboFloater> createState() => _ComboFloaterState();
}

class _ComboFloaterState extends State<_ComboFloater>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 780),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final double t = Curves.easeOutCubic.transform(_c.value);
        final double scale = 0.65 + 0.55 * t;
        final double opacity = (1 - t * 0.35).clamp(0.0, 1.0);
        final Offset p = widget.position + Offset(0, -56 * t);
        return Positioned(
          left: p.dx,
          top: p.dy,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.centerLeft,
            child: Text(
              widget.text,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                color: widget.accent.withValues(alpha: 0.96 * opacity),
                shadows: [
                  Shadow(
                    color: widget.accent.withValues(alpha: 0.5 * opacity),
                    blurRadius: 16,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlayZone extends StatelessWidget {
  const _PlayZone();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(key: ValueKey('PlayZone'));
  }
}

class _SlotBar extends StatefulWidget {
  const _SlotBar({
    required this.imminentSlotIdxs,
    required this.accent,
    required this.premium,
  });

  final Set<int> imminentSlotIdxs;
  final Color accent;
  final bool premium;

  @override
  State<_SlotBar> createState() => _SlotBarState();
}

class _SlotBarState extends State<_SlotBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double s = (math.sin(_pulse.value * math.pi * 2) * 0.5 + 0.5);
    final double a = 0.12 + 0.10 * s;
    final double scale = 1.0 + 0.03 * s;
    final Color accent = widget.accent;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xCC1E2228), // semi-transparent, matte
            border: Border(
              top: BorderSide(
                color: accent.withValues(alpha: widget.premium ? 0.42 : 0.3),
                width: 2,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List<Widget>.generate(GameState.slotCount, (index) {
              final bool imminent = widget.imminentSlotIdxs.contains(index);
              return AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  return Transform.scale(
                    scale: imminent ? scale : 1.0,
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0F),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: imminent
                              ? Colors.white.withValues(alpha: 0.28 + a)
                              : Colors.white.withValues(alpha: 0.22),
                          width: imminent ? 1.2 : 1,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: accent.withValues(
                              alpha: imminent ? a * 0.95 : 0.07,
                            ),
                            blurRadius: imminent ? 12 : 8,
                            spreadRadius: imminent ? 0.5 : 0,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Bandeau objectif High Stakes / Royal (haut d’écran).
class _StakeObjectiveStrip extends StatelessWidget {
  const _StakeObjectiveStrip({required this.stake, required this.gameLevel});

  final SessionStakeKind stake;
  final int gameLevel;

  static const Color _gold = Color(0xFFFFD700);
  static const Color _violet = Color(0xFF9D50BB);
  static const Color _neon = Color(0xFFE49BFF);

  @override
  Widget build(BuildContext context) {
    return switch (stake) {
      SessionStakeKind.casual => const SizedBox.shrink(),
      SessionStakeKind.highStakes => _highStakesStrip(context),
      SessionStakeKind.royal => _royalStrip(context),
    };
  }

  Widget _highStakesStrip(BuildContext context) {
    final bool won = gameLevel >= GameState.highStakesTargetLevel;
    final TextStyle base =
        (Theme.of(context).textTheme.labelSmall ??
                const TextStyle(fontSize: 10))
            .copyWith(
              letterSpacing: 2.9,
              fontWeight: FontWeight.w600,
              fontSize: 10.5,
              color: won
                  ? _gold.withValues(alpha: 0.96)
                  : _gold.withValues(alpha: 0.78),
              shadows: won
                  ? <Shadow>[
                      Shadow(
                        color: _gold.withValues(alpha: 0.55),
                        blurRadius: 16,
                      ),
                      const Shadow(color: Color(0x99FFD700), blurRadius: 28),
                      Shadow(
                        color: _gold.withValues(alpha: 0.35),
                        blurRadius: 6,
                      ),
                    ]
                  : <Shadow>[
                      Shadow(
                        color: _gold.withValues(alpha: 0.22),
                        blurRadius: 10,
                      ),
                    ],
            );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _gold.withValues(alpha: won ? 0.48 : 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                won ? 'PARI RÉUSSI : +150 LUX' : 'OBJECTIF : NIVEAU 3',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: base,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 16,
              height: 14,
              child: CustomPaint(
                painter: _MiniCrownPainter(
                  color: _gold.withValues(alpha: won ? 1.0 : 0.85),
                  glow: won,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _royalStrip(BuildContext context) {
    final bool won = gameLevel >= GameState.royalTargetLevel;
    final TextStyle base =
        (Theme.of(context).textTheme.labelSmall ??
                const TextStyle(fontSize: 10))
            .copyWith(
              letterSpacing: 2.6,
              fontWeight: FontWeight.w600,
              fontSize: 10.5,
              color: won
                  ? _neon.withValues(alpha: 0.96)
                  : _neon.withValues(alpha: 0.78),
              shadows: won
                  ? <Shadow>[
                      Shadow(
                        color: _violet.withValues(alpha: 0.55),
                        blurRadius: 16,
                      ),
                      Shadow(
                        color: _neon.withValues(alpha: 0.35),
                        blurRadius: 22,
                      ),
                      Shadow(
                        color: _violet.withValues(alpha: 0.30),
                        blurRadius: 6,
                      ),
                    ]
                  : <Shadow>[
                      Shadow(
                        color: _violet.withValues(alpha: 0.28),
                        blurRadius: 10,
                      ),
                    ],
            );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _violet.withValues(alpha: won ? 0.52 : 0.30)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                won ? 'PARI ROYAL : +1250 LUX' : 'OBJECTIF : NIVEAU 5',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: base,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 14,
              height: 14,
              child: CustomPaint(
                painter: _MiniDiamondPainter(
                  color: _neon.withValues(alpha: won ? 1.0 : 0.82),
                  glow: won,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCrownPainter extends CustomPainter {
  _MiniCrownPainter({required this.color, this.glow = false});

  final Color color;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Path path = Path()
      ..moveTo(w * 0.08, h * 0.72)
      ..lineTo(w * 0.12, h * 0.38)
      ..lineTo(w * 0.28, h * 0.52)
      ..lineTo(w * 0.5, h * 0.12)
      ..lineTo(w * 0.72, h * 0.52)
      ..lineTo(w * 0.88, h * 0.38)
      ..lineTo(w * 0.92, h * 0.72)
      ..close();

    final Paint fill = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);

    if (glow) {
      final Paint g = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(path, g);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniCrownPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.glow != glow;
}

class _MiniDiamondPainter extends CustomPainter {
  _MiniDiamondPainter({required this.color, this.glow = false});

  final Color color;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double w = size.shortestSide * 0.42;
    final Path path = Path()
      ..moveTo(c.dx, c.dy - w)
      ..lineTo(c.dx + w * 0.9, c.dy)
      ..lineTo(c.dx, c.dy + w * 0.88)
      ..lineTo(c.dx - w * 0.9, c.dy)
      ..close();

    final Paint fill = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..strokeJoin = StrokeJoin.miter;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);

    if (glow) {
      final Paint g = Paint()
        ..color = color.withValues(alpha: 0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.05
        ..strokeJoin = StrokeJoin.miter
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawPath(path, g);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniDiamondPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.glow != glow;
}

class _LevelUpFlash extends StatefulWidget {
  const _LevelUpFlash({required this.tick, required this.level});

  final int tick;
  final int level;

  @override
  State<_LevelUpFlash> createState() => _LevelUpFlashState();
}

class _LevelUpFlashState extends State<_LevelUpFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1500),
          )
          ..addStatusListener((AnimationStatus status) {
            if (status == AnimationStatus.completed && mounted) {
              context.read<GameState>().commitLevelTransitionIfAny();
            }
          })
          ..forward();
  }

  @override
  void didUpdateWidget(covariant _LevelUpFlash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tick != oldWidget.tick) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final double t = Curves.easeOutCubic.transform(_c.value);
        final double a = (1 - t).clamp(0.0, 1.0);
        final double pulse = 1.0 + 0.10 * math.sin(_c.value * math.pi);
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: const Color(0xFFFFD24A).withValues(alpha: 0.08 * a),
            ),
            Center(
              child: Opacity(
                opacity: (a * 0.92).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: pulse,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'LEVEL UP!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 44 - 8 * t,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          color: const Color(0xFFFFD24A),
                          shadows: const [
                            Shadow(color: Color(0xFFFFD24A), blurRadius: 22),
                            Shadow(color: Color(0x99FFD24A), blurRadius: 44),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'LEVEL ${widget.level}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LevelUpLuxBurst extends StatefulWidget {
  const _LevelUpLuxBurst();

  @override
  State<_LevelUpLuxBurst> createState() => _LevelUpLuxBurstState();
}

class _LevelUpLuxBurstState extends State<_LevelUpLuxBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<Offset> _dirs;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();

    final math.Random rnd = math.Random(0x51e71);
    _dirs = List<Offset>.generate(26, (_) {
      final double a = rnd.nextDouble() * math.pi * 2;
      final double r = 0.60 + 0.40 * rnd.nextDouble();
      return Offset(math.cos(a) * r, math.sin(a) * r);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final double t = Curves.easeOutCubic.transform(_c.value);
        final double a = (1 - t).clamp(0.0, 1.0);
        final Size s = MediaQuery.sizeOf(context);
        final Offset center = Offset(s.width / 2, s.height / 2);
        final double radius = 220 * t;

        return Stack(
          children: [
            for (final d in _dirs)
              Positioned(
                left: center.dx + d.dx * radius,
                top: center.dy + d.dy * radius,
                child: Opacity(
                  opacity: (a * 0.9).clamp(0.0, 1.0),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00FFFF).withValues(alpha: 0.85),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF00FFFF,
                          ).withValues(alpha: 0.55),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SequenceCompletedFlash extends StatefulWidget {
  const _SequenceCompletedFlash({required this.tick});

  final int tick;

  @override
  State<_SequenceCompletedFlash> createState() =>
      _SequenceCompletedFlashState();
}

class _GameOverRedFlash extends StatefulWidget {
  const _GameOverRedFlash({required this.tick});

  final int tick;

  @override
  State<_GameOverRedFlash> createState() => _GameOverRedFlashState();
}

class _GameOverRedFlashState extends State<_GameOverRedFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant _GameOverRedFlash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tick != oldWidget.tick) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final double t = Curves.easeOutCubic.transform(_c.value);
          final double a = (1 - t).clamp(0.0, 1.0) * 0.65;
          return ColoredBox(
            color: const Color(0xFFFF2A2A).withValues(alpha: a),
          );
        },
      ),
    );
  }
}

/// Pulse discret sur la gemme attendue (tutoriel narratif, sans main).
class _NarrativeTargetGemPulse extends StatefulWidget {
  const _NarrativeTargetGemPulse({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_NarrativeTargetGemPulse> createState() =>
      _NarrativeTargetGemPulseState();
}

class _NarrativeTargetGemPulseState extends State<_NarrativeTargetGemPulse>
    with SingleTickerProviderStateMixin {
  AnimationController? _c;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1100),
      )..repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _NarrativeTargetGemPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _c ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1100),
      )..repeat(reverse: true);
      _c!.forward();
    } else if (!widget.active && oldWidget.active) {
      _c?.dispose();
      _c = null;
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active || _c == null) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _c!,
      builder: (BuildContext context, Widget? child) {
        final double t = Curves.easeInOutSine.transform(_c!.value);
        final double s = 1.0 + 0.045 * t;
        return Transform.scale(
          scale: s,
          filterQuality: FilterQuality.low,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Bannière « PERFECT MATCH » seule : le +500 reste dans le HUD LUX.
class _NarrativePerfectCelebrationBanner extends StatefulWidget {
  const _NarrativePerfectCelebrationBanner({super.key});

  @override
  State<_NarrativePerfectCelebrationBanner> createState() =>
      _NarrativePerfectCelebrationBannerState();
}

class _NarrativePerfectCelebrationBannerState
    extends State<_NarrativePerfectCelebrationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final double u = Curves.easeOutCubic.transform(
              _c.value.clamp(0.0, 1.0),
            );
            final double scale = 0.94 + 0.06 * u;
            return Transform.scale(
              scale: scale,
              filterQuality: FilterQuality.low,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
                  child: Text(
                    AppLocalizations.of(context)!.gameNarrativePerfectMatchBanner,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 21,
                      height: 1.15,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 3.2,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SequenceCompletedFlashState extends State<_SequenceCompletedFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant _SequenceCompletedFlash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tick != oldWidget.tick) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final double t = Curves.easeOutCubic.transform(_c.value);
        final double a = (1 - t).clamp(0.0, 1.0) * 0.9;
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: Colors.white.withValues(alpha: 0.55 * a)),
            Center(
              child: Opacity(
                opacity: a,
                child: Text(
                  'SEQUENCE COMPLETED',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 20 + 8 * (1 - t),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: const Color(0xFF00FFFF),
                    shadows: const [
                      Shadow(color: Color(0xFF00FFFF), blurRadius: 18),
                      Shadow(color: Color(0x6600FFFF), blurRadius: 34),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
