import 'dart:math' as math;

import '../services/remote_config_service.dart';
import 'board_spawn_logic.dart';

/// Politique « flow » plateau : ajuste les probas de spawn selon Perfect Heat et tension temps.
///
/// Seuils paliers / clamp : [VelourRemoteConfig] (Firebase Remote Config).
abstract final class BoardFlowPolicy {
  BoardFlowPolicy._();

  /// Probabilité de complétion de paire au rack (remplace [BoardSpawnLogic.spawnCompletionBiasChance] contextuel).
  ///
  /// - Haute chaleur : moins de « cadeaux » pour pousser le skill.
  /// - Bas chrono + chaleur faible : un peu plus d’aide pour éviter une mort RNG.
  static double slotCompletionBiasChance({
    required int heatTierClamp0to5,
    required double timeBarFraction,
  }) {
    final VelourRemoteConfig rc = VelourRemoteConfig.instance;
    final int h = heatTierClamp0to5.clamp(0, 5);
    final double t = timeBarFraction.clamp(0.0, 1.0);
    double p = BoardSpawnLogic.spawnCompletionBiasChance;
    if (h >= 5) {
      p = rc.boardFlowBiasT5;
    } else if (h >= 4) {
      p = rc.boardFlowBiasT4;
    } else if (h >= 3) {
      p = rc.boardFlowBiasT3;
    }
    if (h <= 2 && t < 0.22) {
      p = math.max(p, rc.boardFlowRescueFloor);
    }
    return p.clamp(rc.boardFlowBiasClampMin, rc.boardFlowBiasClampMax);
  }

  /// Tirage de forme plus « équilibré » quand la chaleur est haute (évite l’uniforme pur).
  static bool useUnderrepresentedShapePick(int heatTierClamp0to5) =>
      heatTierClamp0to5.clamp(0, 5) >=
      VelourRemoteConfig.instance.boardFlowUnderrepMinHeat;
}
