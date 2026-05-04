/// Hooks d’observabilité (no-op en production — pas de sortie console).
abstract final class VelourObservability {
  static void logEconomySecurity(
    String event, {
    Map<String, Object?> data = const {},
  }) {}

  static void logFirestoreFailure(
    String operation, {
    required Object error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {}
}
