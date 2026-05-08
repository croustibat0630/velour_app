import 'dart:math' as math;

import '../services/remote_config_service.dart';

/// Courbe de progression LUX / niveau + léger DDA sur le débit observé.
///
/// [perfEmaLuxPerMinute] : EMA du gain LUX par minute entre résolutions de match
/// (initialiser ~ [neutralLuxPerMinute] pour ne pas biaiser le début de run).
///
/// Forces vague / DDA / neutre / alpha : [VelourRemoteConfig].
abstract final class MetaProgressionPolicy {
  MetaProgressionPolicy._();

  /// Valeur neutre au reset (évite un DDA extrême avant le 1er match).
  static double get neutralLuxPerMinute =>
      VelourRemoteConfig.instance.metaNeutralLuxPerMinute;

  static double emaLuxPerMinute({
    required double previousEma,
    required double sampleLuxPerMinute,
    double? alpha,
  }) {
    final double a = (alpha ?? VelourRemoteConfig.instance.metaEmaAlpha).clamp(
      0.01,
      0.5,
    );
    return previousEma * (1.0 - a) + sampleLuxPerMinute * a;
  }

  /// LUX requis pour déclencher la transition de niveau (segment courant).
  ///
  /// - Vague sinusoïdale + DDA pilotés par Remote Config.
  static int luxRequiredForNextLevel({
    required int gameLevel,
    required double perfEmaLuxPerMinute,
  }) {
    final VelourRemoteConfig rc = VelourRemoteConfig.instance;
    final double waveStrength = rc.metaWaveStrength;
    final double ddaStrength = rc.metaDdaStrength;
    final int level = gameLevel.clamp(1, 999);
    final int base = (level * 1500 * 1.2).round();
    final double wave =
        1.0 + waveStrength * math.sin((level - 1) * math.pi / 3.5);
    final double neutral = rc.metaNeutralLuxPerMinute;
    final double centered =
        ((perfEmaLuxPerMinute - neutral) / rc.metaDdaCenterDivisor.toDouble())
            .clamp(-1.0, 1.0);
    final double dda = 1.0 + ddaStrength * centered;
    final double combined = base * wave * dda;
    final int need = combined.round();
    final int minNeed = (base * 0.92).round();
    final int maxNeed = (base * 1.10).round();
    return need.clamp(minNeed, maxNeed);
  }
}
