import 'dart:math' as math;

/// Courbure du drain chrono : léger soulagement en zone critique, léger hurry si inaction.
///
/// Reste [GameState] pour le gel Perfect Heat (palier 4) : pas d’accumulation de hurry
/// pendant le freeze — le caller n’applique pas ce module quand le drain est suspendu.
abstract final class TimerTensionLogic {
  TimerTensionLogic._();

  /// Multiplicateur &lt; 1.0 quand la jauge est basse (favorise un sauvetage lisible).
  static double drainMultiplierForBarFraction(double timeBarFraction) {
    final double v = timeBarFraction.clamp(0.0, 1.0);
    if (v < 0.10) return 0.88;
    if (v < 0.20) return 0.94;
    if (v < 0.35) return 0.98;
    return 1.0;
  }

  /// Multiplicateur &gt; 1.0 si le joueur n’a pas agi depuis longtemps (anti-stall).
  static double idleHurryMultiplier({
    required Duration sinceLastPlayerAction,
    Duration softStart = const Duration(seconds: 5),
    Duration hardStart = const Duration(seconds: 12),
  }) {
    final double s = sinceLastPlayerAction.inMilliseconds / 1000.0;
    final double soft = softStart.inMilliseconds / 1000.0;
    final double hard = hardStart.inMilliseconds / 1000.0;
    if (s <= soft) return 1.0;
    if (s <= hard) {
      final double t = ((s - soft) / (hard - soft)).clamp(0.0, 1.0);
      return 1.0 + 0.05 * t;
    }
    final double extra = math.min(6.0, s - hard);
    return 1.05 + 0.03 * (1.0 - math.exp(-extra / 4.0));
  }
}
