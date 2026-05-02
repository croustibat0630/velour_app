import 'package:flutter/material.dart';

import 'gem_glass_paint.dart';

class NeonSphere extends StatelessWidget {
  const NeonSphere({
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
      child: CustomPaint(painter: _NeonSpherePainter(neon: neon)),
    );
  }
}

class _NeonSpherePainter extends CustomPainter {
  const _NeonSpherePainter({required this.neon});

  final Color neon;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Offset c = rect.center;
    final double r = rect.shortestSide * 0.46;
    final Path disc = Path()..addOval(Rect.fromCircle(center: c, radius: r));

    GemGlassPaint.paintBody(canvas, disc, rect, neon);
    GemGlassPaint.paintNeonEdge(canvas, disc, neon);
  }

  @override
  bool shouldRepaint(covariant _NeonSpherePainter oldDelegate) => false;
}

