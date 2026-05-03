/// Paramètres du chrono et du délai de résolution match (logique pure).
abstract final class RunTimerLogic {
  RunTimerLogic._();

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
