import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../utils/velour_release_links.dart';

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

  /// Balises Crashlytics pour filtrer les sessions **release/profile** (post-J1).
  ///
  /// Appeler une fois après [FirebaseCrashlytics.setCrashlyticsCollectionEnabled].
  /// Ne pas y mettre l’URL privacy (donnée personnelle) : uniquement un booléen.
  static void tagReleaseSessionForCrashlyticsJ1() {
    if (!_canReport()) return;
    try {
      final FirebaseCrashlytics c = FirebaseCrashlytics.instance;
      c.setCustomKey(
        'velour_privacy_url_configured',
        VelourReleaseLinks.hasPrivacyPolicyUrl,
      );
      c.setCustomKey('velour_release_bootstrap', 1);
      c.log(
        '[VEL_OBS] j1_session_tag privacy_url_configured=${VelourReleaseLinks.hasPrivacyPolicyUrl}',
      );
    } catch (_) {}
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
