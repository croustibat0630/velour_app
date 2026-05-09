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

// LUX Dust a été extrait dans `lib/game/particle_system.dart`.

class _ComboFloater extends StatefulWidget {
  const _ComboFloater({
    super.key,
    required this.chainMult,
    required this.position,
    required this.accent,
  });

  final double chainMult;
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
    final String comboText = AppLocalizations.of(
      context,
    )!.gameFloatCombo(widget.chainMult.toStringAsFixed(1));
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
              comboText,
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
    required this.slotItems,
    required this.accent,
    required this.premium,
  });

  final Set<int> imminentSlotIdxs;
  final List<GameItem> slotItems;
  final Color accent;
  final bool premium;

  @override
  State<_SlotBar> createState() => _SlotBarState();
}

class _SlotBarState extends State<_SlotBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  static const bool _enableBackdropBlur = bool.fromEnvironment(
    'VELOUR_UI_BLUR',
    defaultValue: false,
  );

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  void _syncRackPulse() {
    if (!mounted) return;
    if (velourReduceMotion(context)) {
      _pulse.stop();
      _pulse.value = 0.0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRackPulse();
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
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final Widget bar = RepaintBoundary(
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
            return Semantics(
              label: rackSlotSemanticsLabel(
                l10n,
                index,
                widget.slotItems,
                widget.imminentSlotIdxs,
              ),
              child: AnimatedBuilder(
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
              ),
            );
          }),
        ),
      ),
    );

    if (!_enableBackdropBlur) {
      return bar;
    }
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: bar,
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

/// Plein écran bref quand le palier FEU / Heat augmente — teinte cyan/fuchsia,
/// plus court que le level-up or pour éviter la confusion.
class _PerfectHeatSurgeFlash extends StatefulWidget {
  const _PerfectHeatSurgeFlash({required this.tick, required this.tier});

  final int tick;
  final int tier;

  @override
  State<_PerfectHeatSurgeFlash> createState() => _PerfectHeatSurgeFlashState();
}

class _PerfectHeatSurgeFlashState extends State<_PerfectHeatSurgeFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant _PerfectHeatSurgeFlash oldWidget) {
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
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final double t = Curves.easeOutCubic.transform(_c.value);
        final double a = (1 - t).clamp(0.0, 1.0);
        final double pulse = 1.0 + 0.08 * math.sin(_c.value * math.pi);
        const Color cA = Color(0xFF5CF6FF);
        const Color cB = Color(0xFFFF6FD8);
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Color.lerp(cA, cB, 0.35)!.withValues(alpha: 0.07 * a),
            ),
            Center(
              child: Opacity(
                opacity: (a * 0.94).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: pulse,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.gameHudPerfectHeatSurgeTitle,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 40 - 7 * t,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: cA,
                              shadows: [
                                Shadow(
                                  color: cB.withValues(alpha: 0.55),
                                  blurRadius: 16,
                                ),
                                Shadow(
                                  color: cA.withValues(alpha: 0.45),
                                  blurRadius: 28,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.gameHudPerfectHeatSurgeSubtitle(widget.tier),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                          ),
                        ],
                      ),
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
    final AppLocalizations l10n = AppLocalizations.of(context)!;
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.gameHudLevelUpTitle,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 44 - 8 * t,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: const Color(0xFFFFD24A),
                              shadows: const [
                                Shadow(
                                  color: Color(0xFFFFD24A),
                                  blurRadius: 22,
                                ),
                                Shadow(
                                  color: Color(0x99FFD24A),
                                  blurRadius: 44,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.gameHudLevelUpSubtitle(widget.level),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncNarrativeTargetPulse();
  }

  @override
  void didUpdateWidget(covariant _NarrativeTargetGemPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active && oldWidget.active) {
      _c?.dispose();
      _c = null;
    } else if (widget.active) {
      _syncNarrativeTargetPulse();
    }
  }

  void _syncNarrativeTargetPulse() {
    if (!widget.active) {
      return;
    }
    if (velourReduceMotion(context)) {
      if (_c != null) {
        _c!.dispose();
        _c = null;
      }
      return;
    }
    _c ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (!_c!.isAnimating) {
      _c!.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active || _c == null || velourReduceMotion(context)) {
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
                    AppLocalizations.of(
                      context,
                    )!.gameNarrativePerfectMatchBanner,
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
                  AppLocalizations.of(context)!.gameSequenceCompletedTitle,
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

/// Flash léger palier 5 Perfect Heat (ghost LUX).
class _PerfectHeatGhostFlash extends StatefulWidget {
  const _PerfectHeatGhostFlash({required this.tick});

  final int tick;

  @override
  State<_PerfectHeatGhostFlash> createState() => _PerfectHeatGhostFlashState();
}

class _PerfectHeatGhostFlashState extends State<_PerfectHeatGhostFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
  );

  @override
  void didUpdateWidget(covariant _PerfectHeatGhostFlash oldWidget) {
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
        final double t = Curves.easeOut.transform(_c.value);
        final double a = (1 - t) * 0.075;
        if (a < 0.001) return const SizedBox.shrink();
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.55),
              radius: 0.95,
              colors: [
                const Color(0xFFFFF8E6).withValues(alpha: a),
                const Color(0x00000000),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        );
      },
    );
  }
}
