// Bandeau stakes + peintures mini + flash surge Perfect Heat — même lib que game_screen.

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
