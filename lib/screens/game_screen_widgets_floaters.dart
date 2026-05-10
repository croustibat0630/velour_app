// Gemme flottante (tutoriel) + floaters « +1 » / texte LUX.

part of 'game_screen.dart';

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
    this.runtimeLuxKind,
    this.runtimeGain,
    this.runtimeChainMult,
    required this.position,
    required this.color,
    this.spectacularBurst = false,
    this.textColorOverride,
    this.appendPerfectHeatNear = false,
  });

  final String text;
  final NarrativeFloatingKey? narrativeFloatKey;
  final RuntimeLuxFloatKind? runtimeLuxKind;
  final int? runtimeGain;
  final String? runtimeChainMult;
  final Offset position;
  final Color color;
  final bool spectacularBurst;
  final Color? textColorOverride;
  final bool appendPerfectHeatNear;

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
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    String displayText = widget.narrativeFloatKey != null
        ? resolveNarrativeFloating(l10n, widget.narrativeFloatKey!)
        : (widget.runtimeLuxKind != null && widget.runtimeGain != null)
        ? resolveRuntimeLuxFloat(
            l10n,
            widget.runtimeLuxKind!,
            widget.runtimeGain!,
            widget.runtimeChainMult,
          )
        : widget.text;
    if (widget.appendPerfectHeatNear) {
      displayText += l10n.gameHudPerfectHeatNearFloater;
    }
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
                    color: (widget.textColorOverride ?? widget.color)
                        .withValues(alpha: 0.95),
                    shadows: widget.textColorOverride != null
                        ? <Shadow>[
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.92),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.55),
                              blurRadius: 8,
                            ),
                            Shadow(
                              color: (widget.textColorOverride ?? widget.color)
                                  .withValues(alpha: 0.45),
                              blurRadius: 10,
                            ),
                          ]
                        : <Shadow>[
                            Shadow(
                              color: (widget.textColorOverride ?? widget.color)
                                  .withValues(alpha: 0.55),
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
