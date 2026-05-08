import 'dart:math' as math;

import '../services/remote_config_service.dart';

/// Courbure du drain chrono : léger soulagement en zone critique, léger hurry si inaction.
///
/// Paramètres pilotés par [VelourRemoteConfig] (defaults si RC indisponible).
///
/// Reste [GameState] pour le gel Perfect Heat (palier 4) : pas d’accumulation de hurry
/// pendant le freeze — le caller n’applique pas ce module quand le drain est suspendu.
abstract final class TimerTensionLogic {
  TimerTensionLogic._();

  /// Multiplicateur &lt; 1.0 quand la jauge est basse (favorise un sauvetage lisible).
  static double drainMultiplierForBarFraction(double timeBarFraction) {
    final VelourRemoteConfig rc = VelourRemoteConfig.instance;
    final double v = timeBarFraction.clamp(0.0, 1.0);
    if (v < 0.10) return rc.runTimerClutchMultBelow10;
    if (v < 0.20) return rc.runTimerClutchMultBelow20;
    if (v < 0.35) return rc.runTimerClutchMultBelow35;
    return 1.0;
  }

  /// Multiplicateur &gt; 1.0 si le joueur n’a pas agi depuis longtemps (anti-stall).
  static double idleHurryMultiplier({required Duration sinceLastPlayerAction}) {
    final VelourRemoteConfig rc = VelourRemoteConfig.instance;
    final Duration softStart = Duration(seconds: rc.runIdleSoftStartSec);
    final Duration hardStart = Duration(seconds: rc.runIdleHardStartSec);
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
