// Overlays HUD stakes, flashes, narrative celebration — même lib que game_screen.

part of 'game_screen.dart';

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
