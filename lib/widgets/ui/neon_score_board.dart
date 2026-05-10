import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:velour_app/l10n/app_localizations.dart';

import '../../game/perfect_heat_logic.dart';
import '../../providers/game_state.dart';
import '../../services/haptics_handler.dart';
import '../../utils/responsive.dart';
import '../../utils/velour_accessibility.dart';
import 'neon_timer_bar.dart';

/// Ligne montant LUX du HUD (animations + SFX sur delta).
class NeonLuxCaption extends StatefulWidget {
  const NeonLuxCaption({
    super.key,
    required this.lux,
    this.fontSize = 26,
    this.comboFlashTick = 0,

    /// Tutoriel narratif : incrémenté au 1er gain — intro fade + scale easeOutBack (≠ combo).
    this.luxIntroTick = 0,
  });

  final int lux;
  final double fontSize;
  final int comboFlashTick;
  final int luxIntroTick;

  @override
  State<NeonLuxCaption> createState() => _NeonLuxCaptionState();
}

class _NeonLuxCaptionState extends State<NeonLuxCaption>
    with TickerProviderStateMixin {
  late final AnimationController _glow;
  late final AnimationController _comboFlash;
  late final AnimationController _punch;
  late final AnimationController _luxIntro;
  late final Animation<double> _luxIntroScale;
  late final Animation<double> _luxIntroFade;

  bool _luxIntroHapticFired = false;
  double _luxIntroScaleMax = 1.0;
  bool _reduceMotion = false;

  static const Color _cyan = Color(0xFF00FFFF);
  static const Color _comboWhite = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _comboFlash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _punch = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _luxIntro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..value = 1.0;
    // Scale : léger rebond fin (tube néon qui se stabilise). Fade : sans overshoot.
    _luxIntroScale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _luxIntro, curve: Curves.easeOutBack));
    _luxIntroFade = CurvedAnimation(
      parent: _luxIntro,
      curve: Curves.easeOutCubic,
    );
    _luxIntroScale.addListener(_luxIntroScalePeakListener);
    _luxIntro.addStatusListener(_luxIntroCompletedFallback);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool next = velourReduceMotion(context);
    if (next != _reduceMotion) {
      _reduceMotion = next;
    }
    _syncGlowRepeat();
  }

  void _syncGlowRepeat() {
    if (!mounted) return;
    if (_reduceMotion) {
      _glow.stop();
      _glow.value = 0.5;
    } else if (!_glow.isAnimating) {
      _glow.repeat();
    }
  }

  void _luxIntroScalePeakListener() {
    if (!mounted || _luxIntroHapticFired) return;
    if (!_luxIntro.isAnimating) return;
    final double s = _luxIntroScale.value;
    if (s > _luxIntroScaleMax) {
      _luxIntroScaleMax = s;
    } else if (s < _luxIntroScaleMax - 0.0015) {
      HapticsHandler.instance.selectionClick();
      _luxIntroHapticFired = true;
    }
  }

  void _luxIntroCompletedFallback(AnimationStatus status) {
    if (!mounted || _luxIntroHapticFired) return;
    if (status == AnimationStatus.completed) {
      HapticsHandler.instance.selectionClick();
      _luxIntroHapticFired = true;
    }
  }

  @override
  void didUpdateWidget(covariant NeonLuxCaption oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.comboFlashTick != oldWidget.comboFlashTick &&
        widget.comboFlashTick > 0) {
      _comboFlash.forward(from: 0);
    }
    if (widget.luxIntroTick != oldWidget.luxIntroTick &&
        widget.luxIntroTick > 0) {
      _luxIntroHapticFired = false;
      _luxIntroScaleMax = 0.85;
      _luxIntro.forward(from: 0);
    }

    final int delta = widget.lux - oldWidget.lux;
    if (delta > 0) {
      // IMPORTANT: Audio for match/perfect is triggered structurally from `GameState`
      // based on the match kind (perfect vs normal). Never from score delta.
      _punch.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _luxIntroScale.removeListener(_luxIntroScalePeakListener);
    _luxIntro.removeStatusListener(_luxIntroCompletedFallback);
    _glow.dispose();
    _comboFlash.dispose();
    _punch.dispose();
    _luxIntro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        _glow,
        _comboFlash,
        _punch,
        _luxIntro,
      ]),
      builder: (BuildContext context, Widget? _) {
        return FadeTransition(
          opacity: _luxIntroFade,
          child: ScaleTransition(
            scale: _luxIntroScale,
            alignment: Alignment.centerRight,
            child: _luxValuePulseLayer(context),
          ),
        );
      },
    );
  }

  /// Pulse court quand le montant LUX change (inchangé).
  Widget _luxValuePulseLayer(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool idleZero = widget.lux == 0;
    final double glowA = 0.6 + 0.2 * math.cos(_glow.value * 2 * math.pi);
    final double comboT = Curves.easeInOutCubic.transform(_comboFlash.value);
    final double whiteMix = math.sin(math.pi * comboT);

    final Color luxColor = Color.lerp(_cyan, _comboWhite, whiteMix)!;
    final double effGlowA = glowA * (1 - whiteMix) + 0.8 * whiteMix;
    final double readabilityA = 0.22 + 0.10 * whiteMix;
    final double zeroDim = idleZero ? 0.38 : 1.0;
    final double fs = widget.fontSize * (idleZero ? 0.82 : 1.0);

    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.lux),
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: _reduceMotion ? 0 : 100),
      curve: Curves.easeOut,
      builder: (context, t, child) {
        final double bump = (t < 0.5) ? (t / 0.5) : ((1 - t) / 0.5);
        final double bumpScale = idleZero ? 0.02 : 0.06;
        final double scale = 1.0 + (bumpScale * bump);
        return Transform.scale(
          scale: scale,
          alignment: Alignment.centerRight,
          filterQuality: FilterQuality.high,
          child: child,
        );
      },
      child: Transform.scale(
        scale: idleZero ? 1.0 : _punchScale,
        alignment: Alignment.centerRight,
        filterQuality: FilterQuality.high,
        child: Semantics(
          label: idleZero
              ? '${l10n.gameHudLuxThisRun}, ${l10n.gameHudLuxAmount(widget.lux)}'
              : l10n.gameHudLuxAmount(widget.lux),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (idleZero)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      l10n.gameHudLuxThisRun,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: (fs * 0.38).clamp(8.0, 11.0),
                        height: 1.0,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.38),
                      ),
                    ),
                  ),
                Text(
                  l10n.gameHudLuxAmount(widget.lux),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: fs,
                    height: 0.95,
                    letterSpacing: idleZero ? 0.65 : 0.9,
                    fontWeight: FontWeight.w600,
                    color: luxColor.withValues(alpha: idleZero ? 0.44 : 1.0),
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(
                          alpha: readabilityA * (idleZero ? 0.75 : 1.0),
                        ),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                      Shadow(
                        color: luxColor.withValues(
                          alpha:
                              (effGlowA * (1 - whiteMix) + 0.95 * whiteMix) *
                              zeroDim,
                        ),
                        blurRadius:
                            (6 + 8 * whiteMix) * (idleZero ? 0.55 : 1.0),
                      ),
                      Shadow(
                        color: const Color(0xFF00FFFF).withValues(
                          alpha:
                              (effGlowA * 0.72) *
                              (1 - 0.85 * whiteMix) *
                              zeroDim,
                        ),
                        blurRadius: idleZero ? 8 : 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double get _punchScale {
    final double punchT = Curves.easeOutCubic.transform(_punch.value);
    return 1.0 + 0.16 * math.sin(punchT * math.pi);
  }
}

/// HUD : Row (LV à gauche) + colonne stats à droite.
class NeonScoreBoard extends StatelessWidget {
  const NeonScoreBoard({
    super.key,
    required this.gameLevel,
    required this.lux,
    this.comboFlashTick = 0,
    this.luxIntroTick = 0,
    this.levelUpFlashTick = 0,
    this.maxWidth = 500,
    this.levelOpacity = 1.0,
    this.luxOpacity = 1.0,
    this.scoreColumnOpacity = 1.0,
    this.timeColumnOpacity = 1.0,
  });

  final int gameLevel;
  final int lux;
  final int comboFlashTick;
  final int luxIntroTick;
  final int levelUpFlashTick;

  /// Largeur max sur desktop/web (pour rester au-dessus du plateau).
  final double maxWidth;

  /// Tutoriel narratif : opacités par zone (défaut 1).
  final double levelOpacity;
  final double luxOpacity;
  final double scoreColumnOpacity;
  final double timeColumnOpacity;

  static const double hudPadH = 20;
  static const double barThickness = 4;

  static const Color _cyan = Color(0xFF00FFFF);
  static const Color _levelBlue = Color(0xFF4FAAFF);
  static const Color _levelGold = Color(0xFFFFD24A);

  Widget _flatTrack({
    required double progress,
    required double thickness,
    required Color fill,
  }) {
    final double p = progress.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, c) {
        final double trackW = c.maxWidth;
        final double fillW = math.max(1.0, trackW * p);
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: thickness,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: Colors.white.withValues(alpha: 0.10)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: fillW,
                    height: thickness,
                    child: ColoredBox(color: fill),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final GameState gs = context.watch<GameState>();
    final double progress = gs.scoreProgress.clamp(0.0, 1.0);

    final double scaleH = Responsive.heightScale(context);
    final double scaleT = Responsive.textScale(context);

    final TextStyle levelStyle = GoogleFonts.montserrat(
      fontSize: (18 * scaleT).clamp(14.0, 20.0),
      letterSpacing: 2.0,
      fontWeight: FontWeight.w500,
      height: 0.95,
      color: _levelBlue,
      shadows: [
        Shadow(color: _levelBlue.withValues(alpha: 0.18), blurRadius: 6),
      ],
    );

    final TextStyle barLabelStyle = GoogleFonts.montserrat(
      fontSize: (10 * scaleT).clamp(9.0, 12.0),
      letterSpacing: 0.75,
      fontWeight: FontWeight.w600,
      color: Colors.white.withValues(alpha: 0.9),
      height: 1.0,
    );

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, c) {
          final double screenW = MediaQuery.sizeOf(context).width;
          final double w = math.min(maxWidth, screenW);

          // Keep inner padding and avoid edge collisions.
          final double innerW = math.max(0.0, w - 2 * hudPadH);

          // Right stats column wants a stable width for readable bars.
          final double rightW = (innerW * 0.62).clamp(220.0, 360.0);

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: w,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: hudPadH),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Opacity(
                      opacity: levelOpacity,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Semantics(
                          label:
                              '${l10n.gameHudLevelTag} ${l10n.gameHudLevelShort(gameLevel)}',
                          child: _LevelPulseText(
                            tick: levelUpFlashTick,
                            text: l10n.gameHudLevelShort(gameLevel),
                            baseStyle: levelStyle,
                            gold: _levelGold,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: rightW,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Opacity(
                            opacity: luxOpacity,
                            child: NeonLuxCaption(
                              lux: lux,
                              fontSize: (26 * scaleT).clamp(18.0, 30.0),
                              comboFlashTick: comboFlashTick,
                              luxIntroTick: luxIntroTick,
                            ),
                          ),
                          SizedBox(height: 12 * scaleH),
                          Opacity(
                            opacity: scoreColumnOpacity,
                            child: Semantics(
                              label:
                                  '${l10n.gameHudScore}: '
                                  '${(progress * 100).round()}%',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _HudBarLabel(
                                    text: l10n.gameHudScore,
                                    style: barLabelStyle,
                                  ),
                                  const SizedBox(height: 2),
                                  _flatTrack(
                                    progress: progress,
                                    thickness: barThickness,
                                    fill: _cyan,
                                  ),
                                  SizedBox(height: 3 * scaleH),
                                  _ForgeSurvivalHud(gameState: gs),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 5 * scaleH),
                          Opacity(
                            opacity: timeColumnOpacity,
                            child: ValueListenableBuilder<double>(
                              valueListenable: gs.timeBar,
                              builder: (context, timerV, _) {
                                return AnimatedBuilder(
                                  animation: gs,
                                  builder: (context, _) {
                                    final bool resolutionCue =
                                        gs.isMatchResolutionActive &&
                                        timerV <= 0.20;
                                    return Semantics(
                                      label: resolutionCue
                                          ? '${l10n.gameHudTime}: '
                                                '${(timerV * 100).round()}%. '
                                                '${l10n.gameHudTimeResolvingA11y}'
                                          : '${l10n.gameHudTime}: '
                                                '${(timerV * 100).round()}%',
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _HudBarLabel(
                                            text: l10n.gameHudTime,
                                            style: barLabelStyle,
                                          ),
                                          const SizedBox(height: 2),
                                          _MatchResolutionChronoCue(
                                            active: resolutionCue,
                                            child: _PerfectHeatFreezeHighlight(
                                              freezeTick:
                                                  gs.perfectHeatFreezeTick,
                                              child: NeonTimerBar(
                                                value: timerV,
                                                height: barThickness * 2,
                                                skinPrimary:
                                                    gs.currentSkin.primaryColor,
                                              ),
                                            ),
                                          ),
                                          if (gs.perfectHeatMechanicsActive)
                                            _PerfectHeatHudRow(
                                              gameState: gs,
                                              l10n: l10n,
                                              scaleT: scaleT,
                                              scaleH: scaleH,
                                              barThickness: barThickness,
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Sablier + œil : charges Réserve chrono / Clémence (pulse si sauvetage imminent).
class _ForgeSurvivalHud extends StatefulWidget {
  const _ForgeSurvivalHud({required this.gameState});

  final GameState gameState;

  @override
  State<_ForgeSurvivalHud> createState() => _ForgeSurvivalHudState();
}

class _ForgeSurvivalHudState extends State<_ForgeSurvivalHud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  static const Color _chronoAccent = Color(0xFF00FFFF);

  static bool _anyPrewarn(GameState gs) =>
      gs.isForgeChronoSalvagePrewarn || gs.isForgeMercySalvagePrewarn;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncForgePulse();
  }

  @override
  void didUpdateWidget(covariant _ForgeSurvivalHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncForgePulse();
  }

  void _syncForgePulse() {
    if (!mounted) return;
    final bool now = _anyPrewarn(widget.gameState);
    if (!now) {
      _pulse
        ..stop()
        ..value = 0;
      return;
    }
    if (velourReduceMotion(context)) {
      _pulse.stop();
      _pulse.value = 0.5;
      return;
    }
    if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GameState gs = widget.gameState;
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[gs.timeBar, gs, _pulse]),
      builder: (BuildContext context, Widget? _) {
        final int chrono = gs.chronoPulseCharges;
        final int mercy = gs.mercySalvageCharges;
        if (chrono <= 0 && mercy <= 0) {
          return const SizedBox.shrink();
        }
        final AppLocalizations l10n = AppLocalizations.of(context)!;
        final bool dimmed = !gs.canForgeRunConsumablesApply;
        final double t = _pulse.value;
        final double chronoPulse = gs.isForgeChronoSalvagePrewarn
            ? (1.0 + 0.14 * math.sin(t * 2 * math.pi))
            : 1.0;
        final double mercyPulse = gs.isForgeMercySalvagePrewarn
            ? (1.0 + 0.14 * math.sin(t * 2 * math.pi + 1.1))
            : 1.0;
        final double chronoGlow = gs.isForgeChronoSalvagePrewarn
            ? (0.35 + 0.45 * t)
            : 0.0;
        final double mercyGlow = gs.isForgeMercySalvagePrewarn
            ? (0.35 + 0.45 * t)
            : 0.0;

        return Opacity(
          opacity: dimmed ? 0.42 : 1.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              if (chrono > 0) ...<Widget>[
                _ForgeSurvivalChip(
                  icon: Icons.hourglass_top_rounded,
                  count: chrono,
                  accent: _chronoAccent,
                  scale: chronoPulse,
                  glowT: chronoGlow,
                  semanticsLabel: l10n.gameHudForgeChronoA11y(chrono),
                ),
                if (mercy > 0) const SizedBox(width: 8),
              ],
              if (mercy > 0)
                _ForgeSurvivalChip(
                  icon: Icons.visibility_rounded,
                  count: mercy,
                  accent: const Color(0xFFFF6B4A),
                  scale: mercyPulse,
                  glowT: mercyGlow,
                  semanticsLabel: l10n.gameHudForgeMercyA11y(mercy),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ForgeSurvivalChip extends StatelessWidget {
  const _ForgeSurvivalChip({
    required this.icon,
    required this.count,
    required this.accent,
    required this.scale,
    required this.glowT,
    required this.semanticsLabel,
  });

  final IconData icon;
  final int count;
  final Color accent;
  final double scale;
  final double glowT;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final double scaleT = Responsive.textScale(context);
    final TextStyle countStyle = GoogleFonts.montserrat(
      fontSize: (11 * scaleT).clamp(9.0, 13.0),
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: Colors.white.withValues(alpha: 0.88),
      height: 1.0,
    );

    return Semantics(
      label: semanticsLabel,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.black.withValues(alpha: 0.38),
            border: Border.all(
              color: accent.withValues(alpha: 0.38 + 0.35 * glowT),
              width: 1.1,
            ),
            boxShadow: <BoxShadow>[
              if (glowT > 0.01)
                BoxShadow(
                  color: accent.withValues(alpha: 0.22 * glowT),
                  blurRadius: 14 + 10 * glowT,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  icon,
                  size: (17 * scaleT).clamp(14.0, 20.0),
                  color: accent.withValues(alpha: 0.92),
                ),
                const SizedBox(width: 5),
                Text('×$count', style: countStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Libellé SCORE / TEMPS : ne doit pas empiéter sur les barres — largeur colonne bornée.
class _HudBarLabel extends StatelessWidget {
  const _HudBarLabel({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Align(
        alignment: Alignment.centerRight,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: style,
          ),
        ),
      ),
    );
  }
}

class _LevelPulseText extends StatefulWidget {
  const _LevelPulseText({
    required this.tick,
    required this.text,
    required this.baseStyle,
    required this.gold,
  });

  final int tick;
  final String text;
  final TextStyle baseStyle;
  final Color gold;

  @override
  State<_LevelPulseText> createState() => _LevelPulseTextState();
}

class _LevelPulseTextState extends State<_LevelPulseText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void didUpdateWidget(covariant _LevelPulseText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tick != oldWidget.tick && widget.tick > 0) {
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
        final double tri = (t < 0.5) ? (t / 0.5) : ((1 - t) / 0.5);
        final double scale = 1.0 + 0.5 * tri;
        final Color c = Color.lerp(widget.baseStyle.color, widget.gold, tri)!;
        return Transform.scale(
          scale: scale,
          alignment: Alignment.centerLeft,
          filterQuality: FilterQuality.high,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              widget.text,
              textAlign: TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: widget.baseStyle.copyWith(
                color: c,
                shadows: <Shadow>[
                  ...(widget.baseStyle.shadows ?? const <Shadow>[]),
                  Shadow(
                    color: c.withValues(alpha: 0.30 * tri),
                    blurRadius: 14,
                  ),
                  Shadow(
                    color: c.withValues(alpha: 0.22 * tri),
                    blurRadius: 32,
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

/// Anneau cyan bref quand le palier 4 fige le drain chrono.
class _PerfectHeatFreezeHighlight extends StatefulWidget {
  const _PerfectHeatFreezeHighlight({
    required this.freezeTick,
    required this.child,
  });

  final int freezeTick;
  final Widget child;

  @override
  State<_PerfectHeatFreezeHighlight> createState() =>
      _PerfectHeatFreezeHighlightState();
}

class _PerfectHeatFreezeHighlightState
    extends State<_PerfectHeatFreezeHighlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void didUpdateWidget(covariant _PerfectHeatFreezeHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.freezeTick != oldWidget.freezeTick && widget.freezeTick > 0) {
      _ring.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ring,
      builder: (context, _) {
        final double u = Curves.easeOut.transform(_ring.value);
        final double edgeA = (1.0 - u) * 0.55;
        if (edgeA < 0.015 && _ring.isCompleted) {
          return widget.child;
        }
        return Stack(
          fit: StackFit.passthrough,
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFF7CF9FF).withValues(alpha: edgeA),
                      width: 1.1,
                    ),
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

/// Pulse ambre discret sur la jauge TEMPS quand le combo se résout avec peu de temps restant
/// (évite la sensation de « jeu figé » sans affaiblir le verrou d’input).
class _MatchResolutionChronoCue extends StatefulWidget {
  const _MatchResolutionChronoCue({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_MatchResolutionChronoCue> createState() =>
      _MatchResolutionChronoCueState();
}

class _MatchResolutionChronoCueState extends State<_MatchResolutionChronoCue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
  );

  @override
  void initState() {
    super.initState();
    // Ne pas appeler [_syncPulse] ici : [velourReduceMotion] lit [MediaQuery]
    // avant la fin de [initState] ([didChangeDependencies] suffit).
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant _MatchResolutionChronoCue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      _syncPulse();
    }
  }

  void _syncPulse() {
    if (!mounted) return;
    if (!widget.active) {
      _pulse
        ..stop()
        ..reset();
      return;
    }
    if (velourReduceMotion(context)) {
      _pulse.stop();
      _pulse.value = 0.5;
      return;
    }
    if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final double u = Curves.easeInOut.transform(_pulse.value);
        final double a = 0.24 + 0.50 * u;
        return Container(
          padding: const EdgeInsets.all(1.4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0xFFFFB74D).withValues(alpha: a),
              width: 1.05,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(
                  0xFFFF8A34,
                ).withValues(alpha: 0.14 + 0.20 * u),
                blurRadius: 10,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Jauge 5 segments + compteur prestige au-delà du palier 5.
class _PerfectHeatHudRow extends StatelessWidget {
  const _PerfectHeatHudRow({
    required this.gameState,
    required this.l10n,
    required this.scaleT,
    required this.scaleH,
    required this.barThickness,
  });

  final GameState gameState;
  final AppLocalizations l10n;
  final double scaleT;
  final double scaleH;
  final double barThickness;

  /// Palier 1→5 : rose néon → corail → ambre → or → pic blanc-doré.
  static const List<Color> _heatSegmentLit = <Color>[
    Color(0xFFFF4D9D),
    Color(0xFFFF6A4A),
    Color(0xFFFFB02E),
    Color(0xFFFFE24D),
    Color(0xFFFFF2B8),
  ];

  static const Color _prestigeGold = Color(0xFFFFEA9B);

  @override
  Widget build(BuildContext context) {
    final GameState gs = gameState;
    final int tier = gs.perfectHeatTier;
    final bool rebound = gs.perfectHeatReboundAvailable && tier == 0;
    final int consec = gs.perfectHeatConsecutivePerfects;
    final double segH = math.max(3.0, barThickness * 0.9);
    final Color dimTrack = const Color(0xFF1E2D45).withValues(alpha: 0.72);

    final int tierC = tier.clamp(0, 5);
    final int luxPctHud = PerfectHeatLogic.luxBonusPercent(tierC.clamp(1, 5));
    final String multHud = PerfectHeatLogic.perfectLuxMultiplierLabel(
      tierC.clamp(1, 5),
    );
    final bool showHudBonus = !rebound && tier >= 2 && luxPctHud > 0;
    final bool showHudTier1Neutral = !rebound && tier == 1;
    final TextStyle perfectHeatTier1MultCaptionStyle = GoogleFonts.montserrat(
      fontSize: (7.5 * scaleT).clamp(6.5, 9.0),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
      color: Colors.white.withValues(alpha: 0.52),
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );
    final TextStyle perfectHeatBonusByBarStyle = GoogleFonts.montserrat(
      fontSize: (8.2 * scaleT).clamp(7.0, 10.2),
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
      color: const Color(0xFFFFE082).withValues(alpha: 0.96),
      shadows: [
        Shadow(
          color: const Color(0xFFFF8A34).withValues(alpha: 0.38),
          blurRadius: 6,
        ),
        Shadow(
          color: Colors.black.withValues(alpha: 0.55),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(top: 5 * scaleH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.gameHudPerfectHeatLabel,
                        style: GoogleFonts.montserrat(
                          fontSize: (9 * scaleT).clamp(8.0, 11.0),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.4,
                          color: Colors.white.withValues(alpha: 0.58),
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.55),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      if (tier >= 5 && consec > 5)
                        Text(
                          ' ×$consec',
                          style: GoogleFonts.montserrat(
                            fontSize: (9 * scaleT).clamp(8.0, 11.0),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: _prestigeGold.withValues(alpha: 0.92),
                            shadows: [
                              Shadow(
                                color: const Color(
                                  0xFFFFB74D,
                                ).withValues(alpha: 0.35),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2 * scaleH),
          SizedBox(
            width: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: List<Widget>.generate(5, (int i) {
                      final bool lit = tier > 0 && i < tier;
                      final Color hot = _heatSegmentLit[i];
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: i == 0 ? 0 : 2),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                color: lit
                                    ? hot.withValues(alpha: 0.55)
                                    : Colors.white.withValues(alpha: 0.06),
                                width: 0.8,
                              ),
                              color: lit
                                  ? hot.withValues(alpha: 0.94)
                                  : dimTrack,
                              boxShadow: lit
                                  ? <BoxShadow>[
                                      BoxShadow(
                                        color: hot.withValues(alpha: 0.48),
                                        blurRadius: 6,
                                        spreadRadius: 0.2,
                                      ),
                                      BoxShadow(
                                        color: hot.withValues(alpha: 0.22),
                                        blurRadius: 14,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: SizedBox(height: segH),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                if (showHudTier1Neutral)
                  Padding(
                    padding: EdgeInsets.only(left: 5 * scaleH),
                    child: Text(
                      multHud,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: perfectHeatTier1MultCaptionStyle,
                    ),
                  )
                else if (showHudBonus)
                  Padding(
                    padding: EdgeInsets.only(left: 5 * scaleH),
                    child: Text(
                      l10n.gameHudPerfectHeatHudBonus(luxPctHud, multHud),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: perfectHeatBonusByBarStyle,
                    ),
                  ),
              ],
            ),
          ),
          if (rebound)
            Padding(
              padding: EdgeInsets.only(top: 3 * scaleH),
              child: Text(
                l10n.gameHudPerfectHeatRebound,
                style: GoogleFonts.montserrat(
                  fontSize: (9 * scaleT).clamp(8.0, 11.0),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: const Color(0xFFFFCC80).withValues(alpha: 0.96),
                  shadows: [
                    Shadow(
                      color: const Color(0xFFFF6E40).withValues(alpha: 0.45),
                      blurRadius: 10,
                    ),
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
