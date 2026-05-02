import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'gem_glass_paint.dart';

class NeonPentagon extends StatelessWidget {
  const NeonPentagon({
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
      child: CustomPaint(painter: _NeonPentagonPainter(neon: neon)),
    );
  }
}

class _NeonPentagonPainter extends CustomPainter {
  const _NeonPentagonPainter({required this.neon});

  final Color neon;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Offset c = rect.center;
    final double r = rect.shortestSide * 0.48;

    final Path pent = Path();
    for (int i = 0; i < 5; i++) {
      final double a = (-math.pi / 2) + i * (2 * math.pi / 5);
      final Offset p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      if (i == 0) {
        pent.moveTo(p.dx, p.dy);
      } else {
        pent.lineTo(p.dx, p.dy);
      }
    }
    pent.close();

    GemGlassPaint.paintBody(canvas, pent, rect, neon);
    GemGlassPaint.paintNeonEdge(canvas, pent, neon);
  }

  @override
  bool shouldRepaint(covariant _NeonPentagonPainter oldDelegate) => false;
}
