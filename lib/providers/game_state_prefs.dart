/// Clés [SharedPreferences] utilisées par [GameState] (économie, tutoriels, skins).
abstract final class GameStatePrefs {
  static const String trinityTutorialComplete =
      'velour_trinity_tutorial_complete';
  static const String isFirstTimeGame = 'velour_is_first_time_game';
  static const String firstLaunch = 'velour_is_first_launch';
  static const String luxCoins = 'velour_lux_coins';

  /// Dernier jour UTC où le bonus LUX quotidien a été réclamé (`yyyy-MM-dd`).
  static const String lastDailyLuxClaimUtcDay = 'velour_last_daily_lux_claim_utc_day';
  static const String activeSkinId = 'velour_active_skin_id';
  static const String unlockedSkins = 'velour_unlocked_skins';
  static const String highScore = 'velour_high_score';

  /// Tampon cloud LUX (par motif) en attente d’envoi à la callable.
  /// JSON map `{ motif: intDelta }` (deltas signés).
  static const String pendingLuxByMotifJson = 'velour_pending_lux_by_motif_json';

  /// Charges d’assurance Oracle (0…3) — boutique / fin de partie premium.
  static const String oracleInsuranceCharges = 'velour_forge_oracle_insurance';

  /// Prime royale : +bonus LUX sur la prochaine victoire Royal (consommé au gain).
  static const String royalVictoryBountyPending =
      'velour_forge_royal_bounty_pending';

  /// Recharge chrono automatique quand le temps tombe à zéro (0…2).
  static const String forgeChronoPulseCharges =
      'velour_forge_chrono_pulse_charges';

  /// Sauvetage impasse : rack plein sans triple (0…2).
  static const String forgeMercySalvageCharges =
      'velour_forge_mercy_salvage_charges';
}
