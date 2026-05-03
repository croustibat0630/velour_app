import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'gem_glass_paint.dart';

class NeonStar extends StatelessWidget {
  const NeonStar({super.key, required this.neon, this.size = 45});

  final double size;
  final Color neon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _NeonStarPainter(neon: neon)),
    );
  }
}

class _NeonStarPainter extends CustomPainter {
  const _NeonStarPainter({required this.neon});

  final Color neon;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Offset c = rect.center;
    final double s = rect.shortestSide;
    // Fills the 45×45 jewel box with margin for the 2px neon stroke.
    final double outer = s * 0.48;
    final double inner = outer * 0.38196601125; // regular pentagram ratio

    final Path star = Path();
    for (int i = 0; i < 10; i++) {
      final double r = (i.isEven) ? outer : inner;
      final double a = -math.pi / 2 + i * math.pi / 5;
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
  bool shouldRepaint(covariant _NeonStarPainter oldDelegate) => false;
}
