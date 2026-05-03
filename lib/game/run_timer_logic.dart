import 'dart:math' as math;

import '../providers/game_state_types.dart';

/// Paramètres du chrono et du délai de résolution match (logique pure).
abstract final class RunTimerLogic {
  RunTimerLogic._();

  static double modeBaseSpeedMultiplier(SessionStakeKind stake) =>
      switch (stake) {
        SessionStakeKind.casual => 1.0,
        SessionStakeKind.highStakes => 1.2,
        SessionStakeKind.royal => 1.4,
      };

  static double levelSpeedMultiplier(int gameLevel) {
    final int level = gameLevel.clamp(1, 999);
    return math.pow(1.15, level - 1).toDouble();
  }

  /// Mise (casual / HS / Royal) × courbe par niveau (×1.15 par palier).
  static double difficultySpeedMultiplier({
    required SessionStakeKind stake,
    required int gameLevel,
  }) =>
      modeBaseSpeedMultiplier(stake) * levelSpeedMultiplier(gameLevel);

  /// Vidage de la jauge temps par seconde (niveau 1 casual ≈ 33 s pour vider 1.0).
  static double timeDrainPerSecond({
    required double baseTimeDrainPerSecond,
    required SessionStakeKind stake,
    required int gameLevel,
  }) =>
      baseTimeDrainPerSecond *
      difficultySpeedMultiplier(stake: stake, gameLevel: gameLevel);

  /// Remboursement chrono après un match (réduit ~5 % par niveau).
  static double matchTimeRefund({
    required double baseMatchTimeRefund,
    required int gameLevel,
  }) =>
      baseMatchTimeRefund * math.pow(0.95, gameLevel - 1);

  /// Prochaine valeur de la jauge après un tick de `dtSeconds`.
  static double nextTimeBarAfterTick({
    required double currentValue,
    required double timeDrainPerSecond,
    required double dtSeconds,
  }) =>
      (currentValue - timeDrainPerSecond * dtSeconds).clamp(0.0, 1.0);

  /// Délai avant résolution d’un match : resserre avec la difficulté ; Royal −20 %.
  static Duration effectiveMatchDelay({
    required Duration baseMatchDelay,
    required double difficultySpeedMultiplier,
    required bool isRoyalSession,
  }) {
    final double royalT = isRoyalSession ? 0.80 : 1.0;
    final double mult = difficultySpeedMultiplier;
    final int ms = (baseMatchDelay.inMilliseconds * royalT / mult)
        .round()
        .clamp(120, baseMatchDelay.inMilliseconds);
    return Duration(milliseconds: ms);
  }
}
