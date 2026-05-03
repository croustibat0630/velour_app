import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:velour_app/l10n/app_localizations.dart';
import 'package:velour_app/l10n/narrative_messages.dart';

import '../../providers/game_state_types.dart';

/// Texte Oracle lisible sur tout fond : léger contour sans ShaderMask.
class _OracleStrokedLabel extends StatelessWidget {
  const _OracleStrokedLabel({required this.message, required this.fillStyle});

  final String message;
  final TextStyle fillStyle;

  @override
  Widget build(BuildContext context) {
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = const Color(0xFF050812).withValues(alpha: 0.58);
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Text(
          message,
          textAlign: TextAlign.center,
          maxLines: 6,
          style: fillStyle.copyWith(foreground: stroke),
        ),
        Text(
          message,
          textAlign: TextAlign.center,
          maxLines: 6,
          style: fillStyle,
        ),
      ],
    );
  }
}

/// Fond radial bleu nuit → noir, pulsation lente (ambiance « moteur / grimoire »).
class NarrativeTutorialAmbientLayer extends StatefulWidget {
  const NarrativeTutorialAmbientLayer({super.key});

  @override
  State<NarrativeTutorialAmbientLayer> createState() =>
      _NarrativeTutorialAmbientLayerState();
}

class _NarrativeTutorialAmbientLayerState
    extends State<NarrativeTutorialAmbientLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
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
        final double w = math.sin(_c.value * math.pi * 2) * 0.5 + 0.5;
        final double innerA = 0.42 + 0.14 * w;
        final double midA = 0.22 + 0.08 * w;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.15),
              radius: 1.35 + 0.08 * w,
              colors: [
                Color.lerp(
                  const Color(0xFF0A1530),
                  const Color(0xFF152A55),
                  w,
                )!.withValues(alpha: innerA),
                const Color(0xFF03050C).withValues(alpha: midA),
                const Color(0xFF000000).withValues(alpha: 0.92),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Instructions de l’Oracle : dock au-dessus du rack, néon + fondu / slide.
/// Les interactions traversent la barre ([IgnorePointer]) pour ne pas bloquer
/// les taps sur le plateau — affichage lecture seule.
class NarrativeOracleMessageBar extends StatelessWidget {
  const NarrativeOracleMessageBar({
    super.key,
    required this.messageId,
    required this.accent,
    required this.secondary,
    this.tutorialStepIndex,

    /// `true` : ancrage bas + ombre vers le haut (évite de masquer les gemmes).
    this.dockToBottom = true,
  });

  final OracleDockMessageId messageId;
  final Color accent;
  final Color secondary;

  /// 0–2 : progression des trois leçons (forme / couleur / parfait).
  final int? tutorialStepIndex;
  final bool dockToBottom;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String message =
        resolveOracleDockMessage(l10n, messageId);
    if (message.isEmpty) return const SizedBox.shrink();

    final TextStyle oracleStyle = GoogleFonts.montserrat(
      fontSize: 14,
      height: 1.38,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.85,
      color: Colors.white,
    );

    final Offset slideBegin = dockToBottom
        ? const Offset(0, 0.07)
        : const Offset(0, 0.06);
    final List<BoxShadow> dockShadows = <BoxShadow>[
      BoxShadow(
        color: accent.withValues(alpha: 0.16),
        blurRadius: 26,
        spreadRadius: -5,
        offset: const Offset(0, -8),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.42),
        blurRadius: 20,
        offset: const Offset(0, -10),
      ),
    ];
    final List<BoxShadow> topShadows = <BoxShadow>[
      BoxShadow(
        color: accent.withValues(alpha: 0.14),
        blurRadius: 28,
        spreadRadius: -6,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.45),
        blurRadius: 22,
        offset: const Offset(0, 12),
      ),
    ];

    return IgnorePointer(
      ignoring: true,
      child: SafeArea(
        top: !dockToBottom,
        bottom: dockToBottom,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              // Largeur déjà bornée par le [Positioned] parent (jeu) — on remplit l’espace utile.
              final double maxOracleW = c.maxWidth;
              return Align(
                alignment: dockToBottom
                    ? Alignment.bottomCenter
                    : Alignment.topCenter,
                child: SizedBox(
                  width: maxOracleW,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 480),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (Widget child, Animation<double> anim) {
                      return FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: slideBegin,
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: anim,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: child,
                        ),
                      );
                    },
                    child: Material(
                      key: ValueKey<String>(
                        '${tutorialStepIndex ?? -1}|$messageId',
                      ),
                      color: Colors.transparent,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Color.lerp(
                              accent,
                              Colors.white,
                              0.42,
                            )!.withValues(alpha: 0.45),
                            width: 0.6,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF10152A).withValues(alpha: 0.88),
                              const Color(0xFF060812).withValues(alpha: 0.94),
                            ],
                          ),
                          boxShadow: dockToBottom ? dockShadows : topShadows,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (tutorialStepIndex != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List<Widget>.generate(3, (int i) {
                                    final bool on =
                                        i <= (tutorialStepIndex ?? -1);
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        left: i == 0 ? 0 : 5,
                                      ),
                                      child: Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: on
                                              ? Color.lerp(
                                                  accent,
                                                  Colors.white,
                                                  0.25,
                                                )!.withValues(alpha: 0.92)
                                              : Colors.white.withValues(
                                                  alpha: 0.18,
                                                ),
                                          boxShadow: on
                                              ? <BoxShadow>[
                                                  BoxShadow(
                                                    color: accent.withValues(
                                                      alpha: 0.35,
                                                    ),
                                                    blurRadius: 6,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            _OracleStrokedLabel(
                              message: message,
                              fillStyle: oracleStyle,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Onde de choc discrète sous le doigt (tutoriel narratif).
class NarrativeTapShockwave extends StatefulWidget {
  const NarrativeTapShockwave({super.key, required this.center});

  final Offset center;

  @override
  State<NarrativeTapShockwave> createState() => _NarrativeTapShockwaveState();
}

class _NarrativeTapShockwaveState extends State<NarrativeTapShockwave>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.center.dx - 80,
      top: widget.center.dy - 80,
      width: 160,
      height: 160,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final double t = Curves.easeOut.transform(_c.value);
            final double r = 18 + 52 * t;
            final double a = (1 - t) * 0.55;
            return CustomPaint(
              painter: _RingPainter(radius: r, alpha: a),
            );
          },
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.radius, required this.alpha});

  final double radius;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width * 0.5, size.height * 0.5);
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..color = Color.lerp(
        const Color(0xFF00FFFF),
        const Color(0xFFFFD700),
        0.35,
      )!.withValues(alpha: alpha);
    canvas.drawCircle(c, radius, p);
    final Paint p2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: alpha * 0.45);
    canvas.drawCircle(c, radius * 0.72, p2);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.alpha != alpha;
}
