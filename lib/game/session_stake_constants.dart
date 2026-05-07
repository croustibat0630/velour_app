import '../services/remote_config_service.dart';

/// Source unique : objectifs de niveau et gains LUX des mises premium.
///
/// Utilisée par [GameState], [resolveSessionStakeOnGameOver], [MatchScoring] et l’UI.
abstract final class SessionStakeConstants {
  SessionStakeConstants._();

  static const int defaultHighStakesWinLux = 150;
  static const int defaultHighStakesTargetLevel = 3;

  static const int defaultRoyalAnteLux = 250;
  static const int defaultRoyalWinLux = 1250;
  static const int defaultRoyalTargetLevel = 5;

  static int get highStakesWinLux =>
      VelourRemoteConfig.instance.highStakesWinLux;
  static int get highStakesTargetLevel =>
      VelourRemoteConfig.instance.highStakesTargetLevel;

  static int get royalAnteLux => VelourRemoteConfig.instance.royalAnteLux;
  static int get royalWinLux => VelourRemoteConfig.instance.royalWinLux;
  static int get royalTargetLevel =>
      VelourRemoteConfig.instance.royalTargetLevel;
}
