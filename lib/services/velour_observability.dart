import 'dart:developer' as developer;

/// Journalisation structurée des erreurs réseau / Firebase (côté client).
///
/// Ne remplace pas Crashlytics ; centralise les logs pour filtrage (`name:`) et extension
/// future (export vers backend, taux d’erreur, etc.).
abstract final class VelourObservability {
  static const String _logName = 'velour.firestore';

  static void logFirestoreFailure(
    String operation, {
    required Object error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    final String ctx = context.entries
        .map((e) => '${e.key}=${e.value}')
        .join(' ');
    developer.log(
      ctx.isEmpty
          ? '$operation failed: $error'
          : '$operation failed: $error | $ctx',
      name: _logName,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
