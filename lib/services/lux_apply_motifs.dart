/// Motifs autorisés par la callable serveur [velourApplyLuxDelta] (`functions/src/index.ts`).
/// Alignés sur la liste côté Cloud Functions — ne pas renommer sans déployer la CF.
abstract final class LuxApplyMotifs {
  /// Tampon client historique / secours (plafonds larges côté serveur).
  static const String velourClientSync = 'velour_client_sync';

  /// Régularisation solde après bootstrap (`FirestoreService.reconcileBootstrapLuxAgainstSnapshot`).
  static const String bootstrapReconcile = 'bootstrap_reconcile';

  static const String welcomeGrant = 'welcome_grant';

  static const String shopSkin = 'shop_skin';

  /// Forge : assurance Oracle, prime royale, chrono, sauvetage — débits boutique.
  static const String shopForgeConsumable = 'shop_forge_consumable';

  /// Mise High Stakes / Royal au lancement de session.
  static const String stakeAnte = 'stake_ante';

  /// Gain LUX fin de run (mise premium réussie, bonus prime royale inclus côté client).
  static const String stakeReward = 'stake_reward';

  /// Remboursement partiel assurance Oracle après échec premium.
  static const String oracleInsuranceRefund = 'oracle_insurance_refund';

  /// Crédit LUX « pack » hors IAP serveur (ex. simulation boutique debug).
  static const String vaultSoftCredit = 'vault_soft_credit';

  /// Ordre de vidage des tampons cloud (déterministe).
  static const List<String> cloudDrainOrder = <String>[
    stakeAnte,
    shopSkin,
    shopForgeConsumable,
    oracleInsuranceRefund,
    stakeReward,
    welcomeGrant,
    vaultSoftCredit,
    velourClientSync,
  ];
}
