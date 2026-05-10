// Flashes montée de niveau + rafale LUX.

part of 'game_screen.dart';

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
