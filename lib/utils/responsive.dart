import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Minimal responsive helpers for multiplatform layouts.
class Responsive {
  static Size size(BuildContext context) => MediaQuery.sizeOf(context);

  /// Primary text scale for the app UI (multiplatform-friendly).
  ///
  /// - Includes OS accessibility scaling (`textScaleFactor`)
  /// - Adds a gentle device scale based on shortest side
  /// - Dampens a bit on compact heights to reduce overflows
  static double textScale(BuildContext context) {
    final Size s = size(context);
    final double accessibility = MediaQuery.textScalerOf(context).scale(1.0);
    final double shortest = math.min(s.width, s.height);
    // Baseline around 390dp (phone portrait). Keep it gentle.
    final double device = (shortest / 390.0).clamp(0.90, 1.10);
    // Compact height: slightly reduce to avoid overflow cascades.
    final double compact = compactHeightScale(context);
    final double ui = (device * (compact < 1.0 ? 0.96 : 1.0));
    // Keep accessibility responsive, but avoid layout explosions.
    return (accessibility * ui).clamp(0.90, 1.25);
  }

  /// Vertical spacing scale (gaps/paddings) — tuned for compact heights.
  static double heightScale(BuildContext context) {
    final Size s = size(context);
    // Baseline around 812dp (iPhone X-ish). Keep it conservative.
    final double raw = (s.height / 812.0).clamp(0.80, 1.08);
    final double compact = compactHeightScale(context);
    return (raw * (compact < 1.0 ? 0.94 : 1.0)).clamp(0.78, 1.08);
  }

  /// Caps content width on large screens (desktop/web).
  static double capWidth(BuildContext context, double maxWidth) {
    final double w = size(context).width;
    return math.min(w, maxWidth);
  }

  /// Returns a scale factor for compact heights (e.g. mobile landscape).
  /// Keeps the UI readable while preventing overflows.
  static double compactHeightScale(
    BuildContext context, {
    double threshold = 520,
  }) {
    final double h = size(context).height;
    return (h < threshold) ? 0.8 : 1.0;
  }
}
