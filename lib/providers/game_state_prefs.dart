/// Clés [SharedPreferences] utilisées par [GameState] (économie, tutoriels, skins).
abstract final class GameStatePrefs {
  static const String trinityTutorialComplete =
      'velour_trinity_tutorial_complete';
  static const String isFirstTimeGame = 'velour_is_first_time_game';
  static const String firstLaunch = 'velour_is_first_launch';
  static const String luxCoins = 'velour_lux_coins';
  static const String activeSkinId = 'velour_active_skin_id';
  static const String unlockedSkins = 'velour_unlocked_skins';
  static const String highScore = 'velour_high_score';

  /// Charges d’assurance Oracle (0…3) — boutique / fin de partie premium.
  static const String oracleInsuranceCharges = 'velour_forge_oracle_insurance';

  /// Prime royale : +bonus LUX sur la prochaine victoire Royal (consommé au gain).
  static const String royalVictoryBountyPending =
      'velour_forge_royal_bounty_pending';
}
