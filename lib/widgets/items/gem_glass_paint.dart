import 'package:flutter/material.dart';

/// Shared “Blue Cyan” glass language: empty dark core + identical diagonal sheen + neon rim.
abstract final class GemGlassPaint {
  GemGlassPaint._();

  static const Color core = Color(0xFF0A0A0A);
  static const double edgeWidth = 2;

  /// Subtle inner volume (white -> transparent). Kept light so it reads as glass, not fog.
  static Shader volumeShader(Rect bounds, Color neon) {
    return RadialGradient(
      // Slightly off-center hotspot for “cut glass” feel.
      center: Alignment(-0.28, -0.34),
      radius: 1.05,
      colors: [
        Colors.white.withValues(alpha: 0.18),
        // Very subtle tint so glass “belongs” to the neon color.
        Color.lerp(Colors.white, neon, 0.22)!.withValues(alpha: 0.07),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: [0.0, 0.42, 1.0],
    ).createShader(bounds);
  }

  /// Same diagonal sheen on every shape (white → transparent), clipped to the gem silhouette.
  /// Peak opacity ~0.14 so the neon rim stays dominant (“jewel”, not milky glass).
  static Shader sheenShader(Rect bounds, Color neon) {
    return LinearGradient(
      begin: const Alignment(-0.92, -0.98),
      end: const Alignment(0.88, 0.92),
      colors: [
        Color.lerp(Colors.white, neon, 0.12)!.withValues(alpha: 0.14),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.52],
    ).createShader(bounds);
  }

  static void paintSheen(Canvas canvas, Rect bounds, Color neon) {
    // A soft-edged diagonal “band” (not a hard line): gradient + tiny blur.
    final Paint p = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(-0.95, -0.95),
        end: const Alignment(0.95, 0.95),
        colors: [
          Colors.white.withValues(alpha: 0.00),
          Color.lerp(Colors.white, neon, 0.08)!.withValues(alpha: 0.10),
          // slightly stronger center highlight (was 0.18)
          Color.lerp(Colors.white, neon, 0.12)!.withValues(alpha: 0.22),
          Color.lerp(Colors.white, neon, 0.08)!.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: 0.00),
        ],
        stops: const [0.0, 0.34, 0.50, 0.66, 1.0],
      ).createShader(bounds)
      ..blendMode = BlendMode.screen
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);

    canvas.drawRect(bounds, p);
  }

  static void paintBody(Canvas canvas, Path silhouette, Rect bounds, Color neon) {
    canvas.drawPath(silhouette, Paint()..color = core);
    canvas.save();
    canvas.clipPath(silhouette);
    canvas.drawRect(
      bounds,
      Paint()..shader = volumeShader(bounds, neon),
    );
    // soft diagonal sheen
    paintSheen(canvas, bounds, neon);
    canvas.restore();
  }

  static void paintNeonEdge(Canvas canvas, Path silhouette, Color neon) {
    canvas.drawPath(
      silhouette,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = edgeWidth
        ..color = neon,
    );
  }
}
