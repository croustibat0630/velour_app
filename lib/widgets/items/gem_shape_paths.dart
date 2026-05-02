import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Chemins de contour alignés sur les painters des gemmes (`NeonCrystal`, etc.).
/// Utilisé pour le feedback tactile High Stakes (liséré géométrique).
class GemShapePaths {
  GemShapePaths._();

  static Path outline(int typeId, Size size) {
    switch (typeId) {
      case 1:
        return _hexagon(size);
      case 2:
        return _circle(size);
      case 3:
        return _triangle(size);
      case 4:
        return _star5(size);
      case 5:
        return _diamond(size);
      case 6:
        return _pentagon(size);
      case 7:
        return _star6(size);
      default:
        return _hexagon(size);
    }
  }

  static Path _hexagon(Size size) {
    final Rect rect = Offset.zero & size;
    final Offset c = rect.center;
    final double r = rect.shortestSide * 0.46;
    final Path p = Path();
    for (int i = 0; i < 6; i++) {
      final double a = (-math.pi / 2) + i * (math.pi / 3);
      final Offset pt = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    p.close();
    return p;
  }

  static Path _circle(Size size) {
    final Rect rect = Offset.zero & size;
    final Offset c = rect.center;
    final double r = rect.shortestSide * 0.46;
    return Path()..addOval(Rect.fromCircle(center: c, radius: r));
  }

  static Path _triangle(Size size) {
    final Rect rect = Offset.zero & size;
    final Offset c = rect.center;
    final double w = rect.width * 0.82;
    final double h = rect.height * 0.86;
    return Path()
      ..moveTo(c.dx, c.dy - h / 2)
      ..lineTo(c.dx - w / 2, c.dy + h / 2)
      ..lineTo(c.dx + w / 2, c.dy + h / 2)
      ..close();
  }

  static Path _star5(Size size) {
    final Rect rect = Offset.zero & size;
    final Offset c = rect.center;
    final double s = rect.shortestSide;
    final double outer = s * 0.48;
    final double inner = outer * 0.38196601125;
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
    return star;
  }

  static Path _diamond(Size size) {
    final Rect rect = Offset.zero & size;
    final Offset c = rect.center;
    final double w = rect.width * 0.84;
    final double h = rect.height * 0.84;
    return Path()
      ..moveTo(c.dx, c.dy - h / 2)
      ..lineTo(c.dx + w / 2, c.dy)
      ..lineTo(c.dx, c.dy + h / 2)
      ..lineTo(c.dx - w / 2, c.dy)
      ..close();
  }

  static Path _pentagon(Size size) {
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
    return pent;
  }

  static Path _star6(Size size) {
    final Rect rect = Offset.zero & size;
    final Offset c = rect.center;
    final double s = rect.shortestSide;
    final double outer = s * 0.48;
    final double inner = outer * 0.46;
    final Path star = Path();
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
    return star;
  }
}

/// Liséré néon + micro-particules (tap High Stakes / Royal).
class StakeGemTapFxPainter extends CustomPainter {
  StakeGemTapFxPainter({
    required this.typeId,
    required this.t,
    required this.particleSeed,
    required this.accentColor,
    this.particleBoost = 1.0,
  });

  final int typeId;
  /// 0 → 1
  final double t;
  final int particleSeed;
  final Color accentColor;
  final double particleBoost;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0.001) return;
    final Path path = GemShapePaths.outline(typeId, size);
    final double u = Curves.easeOut.transform(t.clamp(0.0, 1.0));
    final double alpha = (1.0 - u) * 0.95;
    final double wStroke = 1.05 + (1.0 - u) * 1.15;

    final Paint glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = wStroke + 2.8 * (1.0 - u)
      ..strokeJoin = StrokeJoin.round
      ..color = accentColor.withValues(alpha: alpha * 0.32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = wStroke
      ..strokeJoin = StrokeJoin.round
      ..color = accentColor.withValues(alpha: alpha);

    canvas.drawPath(path, glow);
    canvas.drawPath(path, stroke);

    final Rect rect = Offset.zero & size;
    final Offset c = rect.center;
    final math.Random rnd = math.Random(particleSeed);
    final int n = (10 * particleBoost).round().clamp(8, 14);
    for (int i = 0; i < n; i++) {
      final double ang = rnd.nextDouble() * math.pi * 2;
      final double speed = (10 + rnd.nextDouble() * 18) * particleBoost;
      final Offset dir = Offset(math.cos(ang), math.sin(ang));
      final Offset o = c + dir * speed * u;
      final double dotA =
          alpha * (0.35 + rnd.nextDouble() * 0.45) * (1.0 - u) * particleBoost;
      final double rr = (1.2 + rnd.nextDouble() * 1.4) * (1.0 - u * 0.85);
      canvas.drawCircle(
        o,
        rr,
        Paint()..color = accentColor.withValues(alpha: dotA.clamp(0.0, 1.0)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant StakeGemTapFxPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.typeId != typeId ||
        oldDelegate.particleSeed != particleSeed ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.particleBoost != particleBoost;
  }
}
