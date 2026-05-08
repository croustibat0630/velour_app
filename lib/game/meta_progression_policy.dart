import 'dart:math' as math;

/// Courbe de progression LUX / niveau + léger DDA sur le débit observé.
///
/// [perfEmaLuxPerMinute] : EMA du gain LUX par minute entre résolutions de match
/// (initialiser ~ [neutralLuxPerMinute] pour ne pas biaiser le début de run).
abstract final class MetaProgressionPolicy {
  MetaProgressionPolicy._();

  /// Valeur neutre au reset (évite un DDA extrême avant le 1er match).
  static const double neutralLuxPerMinute = 280.0;

  static double emaLuxPerMinute({
    required double previousEma,
    required double sampleLuxPerMinute,
    double alpha = 0.14,
  }) {
    final double a = alpha.clamp(0.01, 0.5);
    return previousEma * (1.0 - a) + sampleLuxPerMinute * a;
  }

  /// LUX requis pour déclencher la transition de niveau (segment courant).
  ///
  /// - [waveStrength] : respiration sinusoïdale légère (~±5 %).
  /// - DDA : joueur au-dessus de la cible EMA → besoin un peu plus haut ; en dessous → soulagement.
  static int luxRequiredForNextLevel({
    required int gameLevel,
    required double perfEmaLuxPerMinute,
    double waveStrength = 0.055,
    double ddaStrength = 0.042,
  }) {
    final int level = gameLevel.clamp(1, 999);
    final int base = (level * 1500 * 1.2).round();
    final double wave =
        1.0 + waveStrength * math.sin((level - 1) * math.pi / 3.5);
    final double centered =
        ((perfEmaLuxPerMinute - neutralLuxPerMinute) / 420.0).clamp(-1.0, 1.0);
    final double dda = 1.0 + ddaStrength * centered;
    final double combined = base * wave * dda;
    final int need = combined.round();
    final int minNeed = (base * 0.92).round();
    final int maxNeed = (base * 1.10).round();
    return need.clamp(minNeed, maxNeed);
  }
}
