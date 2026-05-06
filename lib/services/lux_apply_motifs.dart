/// Motifs autorisés par la callable serveur [velourApplyLuxDelta] (`functions/src/index.ts`).
/// Alignés sur la liste côté Cloud Functions — ne pas renommer sans déployer la CF.
abstract final class LuxApplyMotifs {
  static const String velourClientSync = 'velour_client_sync';
  static const String bootstrapReconcile = 'bootstrap_reconcile';
}
