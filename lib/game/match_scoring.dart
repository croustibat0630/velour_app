import '../providers/game_state_types.dart';

/// Règles LUX pures pour un match (hors persistance / UI).
abstract final class MatchScoring {
  MatchScoring._();

  static int baseLuxForBasis(RunBasis basis) => switch (basis) {
        RunBasis.shape => 100,
        RunBasis.color => 150,
        RunBasis.perfect => 500,
      };

  /// Longueur de run ≥ 3 : gain = base × (runCount − 2).
  static int rawLuxGain(RunBasis basis, int runCount) =>
      baseLuxForBasis(basis) * (runCount - 2);

  static double sessionScoreMultiplier(
    SessionStakeKind stake,
    int gameLevel, {
    int highStakesTargetLevel = 3,
    int royalTargetLevel = 5,
  }) {
    return switch (stake) {
      SessionStakeKind.highStakes =>
        gameLevel >= highStakesTargetLevel ? 1.5 : 1.0,
      SessionStakeKind.royal =>
        gameLevel >= royalTargetLevel ? 3.0 : 1.0,
      _ => 1.0,
    };
  }

  static int roundChainedLux(
    int rawGain,
    double sessionMult,
    double chainMult,
  ) =>
      (rawGain * sessionMult * chainMult).round();
}
