import 'package:flutter/material.dart';

import 'gem_glass_paint.dart';

class NeonPyramid extends StatelessWidget {
  const NeonPyramid({super.key, required this.neon, this.size = 45});

  final double size;
  final Color neon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _NeonPyramidPainter(neon: neon)),
    );
  }
}

class _NeonPyramidPainter extends CustomPainter {
  const _NeonPyramidPainter({required this.neon});

  final Color neon;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Offset c = rect.center;
    final double w = rect.width * 0.82;
    final double h = rect.height * 0.86;

    final Path tri = Path()
      ..moveTo(c.dx, c.dy - h / 2)
      ..lineTo(c.dx - w / 2, c.dy + h / 2)
      ..lineTo(c.dx + w / 2, c.dy + h / 2)
      ..close();

    GemGlassPaint.paintBody(canvas, tri, rect, neon);
    GemGlassPaint.paintNeonEdge(canvas, tri, neon);
  }

  @override
  bool shouldRepaint(covariant _NeonPyramidPainter oldDelegate) => false;
}
