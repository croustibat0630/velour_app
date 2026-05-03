/// Plafonds LUX partagés client / chunk callable (garder aligné avec
/// `functions/src/index.ts` — `MAX_POSITIVE_LUX_DELTA`).
abstract final class LuxCreditLimits {
  /// Crédit positif max par appel [EconomyService.addLuxCoins] et par chunk
  /// [FirestoreService.chunkLuxDeltaForCallable] / CF `velourApplyLuxDelta`.
  /// Doit couvrir le plus gros pack Coffre-fort (5000 LUX) avec marge.
  static const int maxPositiveCreditPerApply = 10000;
}
