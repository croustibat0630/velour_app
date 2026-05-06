import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

export 'velour_obs_codes.dart';

/// Télémétrie erreurs (Crashlytics) hors builds debug — les logs debug restent via [VelourAuditLog].
///
/// Préférer des codes stables ([VelourObsCodes]) en premier argument pour faciliter le tri en prod.
abstract final class VelourObservability {
  static bool _canReport() {
    if (kDebugMode) return false;
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Événements économie / anti-abus (texte seul — évite de spammer les « non-fatal » Crashlytics).
  static void logEconomySecurity(
    String event, {
    Map<String, Object?> data = const {},
  }) {
    if (!_canReport()) return;
    try {
      FirebaseCrashlytics.instance.log(
        '[VEL_OBS] economy_security $event data=$data',
      );
    } catch (_) {}
  }

  static void logFirestoreFailure(
    String operation, {
    required Object error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    if (!_canReport()) return;
    try {
      FirebaseCrashlytics.instance.log(
        '[VEL_OBS] firestore_failure code=$operation ctx=$context err=$error',
      );
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace ?? StackTrace.current,
        fatal: false,
        reason: operation,
      );
    } catch (_) {}
  }

  /// Erreurs client (IAP, persistance store, etc.) sans passer par Firestore.
  static void recordClientFailure(
    String code,
    Object error, [
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  ]) {
    if (!_canReport()) return;
    try {
      FirebaseCrashlytics.instance.log(
        '[VEL_OBS] client_failure code=$code ctx=$context err=$error',
      );
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace ?? StackTrace.current,
        fatal: false,
        reason: code,
      );
    } catch (_) {}
  }
}
