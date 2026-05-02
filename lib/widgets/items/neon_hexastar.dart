import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'gem_glass_paint.dart';

/// 6-branch star (12 points) — visually distinct from the 5-point star.
class NeonHexaStar extends StatelessWidget {
  const NeonHexaStar({
    super.key,
    required this.neon,
    this.size = 45,
  });

  final double size;
  final Color neon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _NeonHexaStarPainter(neon: neon)),
    );
  }
}

class _NeonHexaStarPainter extends CustomPainter {
  const _NeonHexaStarPainter({required this.neon});

  final Color neon;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Offset c = rect.center;
    final double s = rect.shortestSide;
    final double outer = s * 0.48;
    final double inner = outer * 0.46;

    final Path star = Path();
    // 12-point outline: alternating radii -> 6-branch star.
    for (int i = 0; i < 12; i++) {
      final double r = (i.isEven) ? outer : inner;
      final double a = -math.pi / 2 + i * (math.pi / 6);
      final Offset p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      if (i == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
    }
    star.close();

    GemGlassPaint.paintBody(canvas, star, rect, neon);
    GemGlassPaint.paintNeonEdge(canvas, star, neon);
  }

  @override
  bool shouldRepaint(covariant _NeonHexaStarPainter oldDelegate) => false;
}

