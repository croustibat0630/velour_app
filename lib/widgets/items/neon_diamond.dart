import 'package:flutter/material.dart';

import 'gem_glass_paint.dart';

class NeonDiamond extends StatelessWidget {
  const NeonDiamond({super.key, required this.neon, this.size = 45});

  final double size;
  final Color neon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _NeonDiamondPainter(neon: neon)),
    );
  }
}

class _NeonDiamondPainter extends CustomPainter {
  const _NeonDiamondPainter({required this.neon});

  final Color neon;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Offset c = rect.center;
    final double w = rect.width * 0.84;
    final double h = rect.height * 0.84;

    final Path diamond = Path()
      ..moveTo(c.dx, c.dy - h / 2)
      ..lineTo(c.dx + w / 2, c.dy)
      ..lineTo(c.dx, c.dy + h / 2)
      ..lineTo(c.dx - w / 2, c.dy)
      ..close();

    GemGlassPaint.paintBody(canvas, diamond, rect, neon);
    GemGlassPaint.paintNeonEdge(canvas, diamond, neon);
  }

  @override
  bool shouldRepaint(covariant _NeonDiamondPainter oldDelegate) => false;
}
