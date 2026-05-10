// Séquence Trinity complétée, game over rouge, flash ghost Perfect Heat.

part of 'game_screen.dart';

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
