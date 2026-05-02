import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../providers/game_state_types.dart';

class LuxDustSeed {
  const LuxDustSeed({
    required this.direction,
    required this.speed,
    required this.size,
    required this.hex,
    required this.useSecondary,
  });

  final Offset direction;
  final double speed;
  final double size;
  final bool hex;
  final bool useSecondary;
}

List<LuxDustSeed> buildLuxDustSeeds(MatchParticleFx fx, int seed) {
  final math.Random rnd = math.Random(seed ^ 0x71afc93);
  final int n = fx.particleCount.clamp(8, 48);
  return List<LuxDustSeed>.generate(n, (int i) {
    final double angle = rnd.nextDouble() * math.pi * 2;
    final double speed = 26 + rnd.nextDouble() * 68;
    final double size = 1.7 + rnd.nextDouble() * 2.2;
    final bool hex = (i % 3) == 0;
    final double wobble = (rnd.nextDouble() - 0.5) * 0.35;
    final bool useSecondary = (i % 4) == 0;
    return LuxDustSeed(
      direction: Offset(math.cos(angle + wobble), math.sin(angle + wobble)),
      speed: speed,
      size: size,
      hex: hex,
      useSecondary: useSecondary,
    );
  });
}

class LuxDustPainter extends CustomPainter {
  LuxDustPainter({
    required this.center,
    required this.primary,
    required this.secondary,
    required this.t,
    required this.seeds,
    required this.perfectBurst,
    required this.flashRadius,
  });

  final Offset center;
  final Color primary;
  final Color secondary;
  final double t;
  final List<LuxDustSeed> seeds;
  final bool perfectBurst;
  final double flashRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1 || seeds.isEmpty) return;
    final double eased = Curves.easeOutCubic.transform(t);
    final double lifeAlpha =
        math.pow(1.0 - t, 1.25).toDouble().clamp(0.0, 1.0);

    if (perfectBurst) {
      final double flash = (1.0 - t) * 0.45;
      final Paint flashPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withValues(alpha: flash * 0.6);
      canvas.drawCircle(
        center,
        flashRadius * (0.22 + 0.78 * eased),
        flashPaint,
      );
    }

    final Paint p = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        kIsWeb ? 1.3 : 1.9,
      );

    for (final LuxDustSeed seed in seeds) {
      final Offset pos = center + seed.direction * seed.speed * eased;
      final double a = (0.86 * lifeAlpha).clamp(0.0, 1.0);
      final Color c =
          (seed.useSecondary ? secondary : primary).withValues(alpha: 0.82 * a);
      p.color = c;
      if (seed.hex) {
        canvas.drawPath(_hexPath(pos, seed.size), p);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: pos,
            width: seed.size * 1.15,
            height: seed.size * 1.15,
          ),
          p,
        );
      }
    }
  }

  Path _hexPath(Offset c, double radius) {
    final Path path = Path();
    for (int i = 0; i < 6; i++) {
      final double a = (math.pi / 3) * i + math.pi / 6;
      final Offset pt = Offset(
        c.dx + math.cos(a) * radius,
        c.dy + math.sin(a) * radius,
      );
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant LuxDustPainter oldDelegate) =>
      oldDelegate.center != center ||
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary ||
      oldDelegate.t != t ||
      oldDelegate.seeds != seeds ||
      oldDelegate.perfectBurst != perfectBurst ||
      oldDelegate.flashRadius != flashRadius;
}

