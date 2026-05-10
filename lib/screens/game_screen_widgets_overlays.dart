// Flash plein écran Perfect Heat (palier surge).

part of 'game_screen.dart';

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
