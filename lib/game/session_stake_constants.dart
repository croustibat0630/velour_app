/// Source unique : objectifs de niveau et gains LUX des mises premium.
///
/// Utilisée par [GameState], [resolveSessionStakeOnGameOver], [MatchScoring] et l’UI.
abstract final class SessionStakeConstants {
  SessionStakeConstants._();

  static const int highStakesWinLux = 150;
  static const int highStakesTargetLevel = 3;

  static const int royalAnteLux = 250;
  static const int royalWinLux = 1250;
  static const int royalTargetLevel = 5;
}
