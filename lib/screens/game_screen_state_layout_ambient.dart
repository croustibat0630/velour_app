// Fonds animés + poussière + calque ambiant tutoriel narratif (sous le plateau).

part of 'game_screen.dart';

extension _GameScreenStateLayoutAmbient on _GameScreenState {
  List<Widget> buildScreenLayoutAmbientLayers({
    required BuildContext context,
    required GameState gameState,
    required bool reduceMotion,
    required double width,
    required double height,
  }) {
    return <Widget>[
      // Fond : léger drift du centre (premium, sans distraire du jeu).
      Positioned.fill(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _bgDrift,
            builder: (BuildContext context, Widget? _) {
              final double t = _bgDrift.value * math.pi * 2;
              final Alignment center = Alignment(
                0.038 * math.sin(t),
                0.10 + 0.028 * math.cos(t * 0.73),
              );
              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: center,
                    radius: 1.2,
                    colors: const <Color>[Color(0xFF0B1020), Color(0xFF000000)],
                    stops: const <double>[0.0, 1.0],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      Positioned.fill(
        child: IgnorePointer(
          child: TweenAnimationBuilder<double>(
            tween: Tween(
              begin: _pulseUp ? 0.2 : 0.4,
              end: _pulseUp ? 0.4 : 0.2,
            ),
            duration: reduceMotion ? Duration.zero : const Duration(seconds: 4),
            onEnd: () {
              if (!gameState.criticalFailure) {
                _toggleBackgroundPulseForAmbient();
              }
            },
            builder: (context, pulseT, _) {
              if (!gameState.hasPremiumStakeSession) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, 0.10),
                      radius: 1.2,
                      colors: [
                        NeonColors.cyan.withValues(alpha: pulseT),
                        const Color(0x00000000),
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                );
              }
              final double u = ((pulseT - 0.2) / 0.2).clamp(0.0, 1.0);
              if (gameState.isRoyalSession) {
                // Vignette violet néon (bords), plus marquée que l’or.
                final double edgeA = 0.14 + 0.12 * u;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.42,
                      colors: [
                        const Color(0x00000000),
                        const Color(0xFF9D50BB).withValues(alpha: edgeA),
                        const Color(0xFF6E48AA).withValues(alpha: edgeA * 0.82),
                      ],
                      stops: const [0.62, 0.88, 1.0],
                    ),
                  ),
                );
              }
              // Vignette dorée sur les bords (centre transparent → or léger).
              final double edgeA = 0.10 + 0.08 * u;
              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.38,
                    colors: [
                      const Color(0x00000000),
                      const Color(0xFFFFD700).withValues(alpha: edgeA),
                    ],
                    stops: const [0.70, 1.0],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      // Space dust (very subtle)
      Positioned.fill(
        child: IgnorePointer(
          child: LayoutBuilder(
            builder: (context, c) {
              return Stack(
                children: [
                  for (final p in _dust)
                    Positioned(
                      left: p.dx * c.maxWidth,
                      top: p.dy * c.maxHeight,
                      child: Container(
                        width: 1,
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
      if (gameState.isNarrativeTutorialActive)
        Positioned.fill(
          child: IgnorePointer(child: const NarrativeTutorialAmbientLayer()),
        ),
    ];
  }
}
