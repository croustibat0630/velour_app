// Partie « widgets privés » de la bibliothèque [game_screen] (même unité de compilation).
part of 'game_screen.dart';

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
    required this.semanticsLabel,
    required this.isOnBoard,
    required this.typeId,
    required this.neon,
    required this.onSelect,
    required this.child,
    this.stakeTapTraceColor,
    this.stakeTapParticleBoost = 1.0,
  });

  /// VoiceOver / TalkBack (forme + couleur).
  final String semanticsLabel;

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
    if (velourReduceMotion(context)) {
      await widget.onSelect();
      if (mounted) {
        _busy = false;
      }
      return;
    }
    await _pop.forward(from: 0);
    if (!mounted) return;
    await widget.onSelect();
    _pop.reset();
    _busy = false;
  }

  @override
  Widget build(BuildContext context) {
    final Color c = widget.neon;
    final bool rm = velourReduceMotion(context);
    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          // Immediate select feedback on press (not release).
          AudioHandler.instance.playGemSelect();
          AudioHandler.instance.primeMatchPoolOnFirstUserTap();
          HapticsHandler.instance.selectionClick();
          if (!rm && widget.stakeTapTraceColor != null && widget.isOnBoard) {
            _dustSeed++;
            _goldTrace.forward(from: 0);
          }
        },
        onTap: _handleTap,
        child: SizedBox.expand(
          child: AnimatedBuilder(
            animation: Listenable.merge([_pop, _goldTrace]),
            builder: (context, child) {
              final double t = rm ? 0.0 : _popCurved.value;
              final double scale = rm ? 1.0 : (1.0 + 0.2 * t);
              final double flash = rm
                  ? 0.0
                  : (math.sin(math.pi * t) * 0.34).clamp(0.0, 1.0);
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
                  if (!rm &&
                      widget.stakeTapTraceColor != null &&
                      widget.isOnBoard)
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
