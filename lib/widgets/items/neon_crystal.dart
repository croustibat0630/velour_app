import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'gem_glass_paint.dart';

class NeonCrystal extends StatelessWidget {
  const NeonCrystal({super.key, required this.neon, this.size = 45});

  final double size;
  final Color neon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _NeonCrystalPainter(neon: neon)),
    );
  }
}

class _NeonCrystalPainter extends CustomPainter {
  const _NeonCrystalPainter({required this.neon});

  final Color neon;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Path hex = _hexagonPath(rect);
    GemGlassPaint.paintBody(canvas, hex, rect, neon);
    GemGlassPaint.paintNeonEdge(canvas, hex, neon);
  }

  List<Offset> _hexagonPoints(Rect rect) {
    final Offset c = rect.center;
    final double r = rect.shortestSide * 0.46;

    return List<Offset>.generate(6, (int i) {
      final double a = (-math.pi / 2) + i * (math.pi / 3);
      return Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
    });
  }

  Path _hexagonPath(Rect rect) {
    final List<Offset> pts = _hexagonPoints(rect);
    return Path()
      ..moveTo(pts[0].dx, pts[0].dy)
      ..lineTo(pts[1].dx, pts[1].dy)
      ..lineTo(pts[2].dx, pts[2].dy)
      ..lineTo(pts[3].dx, pts[3].dy)
      ..lineTo(pts[4].dx, pts[4].dy)
      ..lineTo(pts[5].dx, pts[5].dy)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _NeonCrystalPainter oldDelegate) => false;
}
