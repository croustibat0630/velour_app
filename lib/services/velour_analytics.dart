import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Télémétrie **opt-in** (Firebase Analytics), désactivée par défaut au build.
///
/// Activer uniquement avec consentement légal / politique de confidentialité à jour :
/// `--dart-define=VELOUR_ANALYTICS=true` (voir `docs/STORE_RELEASE_CHECKLIST.md`).
abstract final class VelourAnalytics {
  VelourAnalytics._();

  static const bool enabled = bool.fromEnvironment(
    'VELOUR_ANALYTICS',
    defaultValue: false,
  );

  /// À appeler une fois après [Firebase.initializeApp].
  static Future<void> configureAfterFirebaseInit() async {
    try {
      final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
      await analytics.setAnalyticsCollectionEnabled(enabled);
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.setCustomKey(
          'velour_analytics',
          enabled ? 1 : 0,
        );
      }
      if (enabled) {
        await analytics.logAppOpen();
      }
    } catch (e, st) {
      debugPrint('VelourAnalytics configure failed: $e');
      if (!kDebugMode) {
        await FirebaseCrashlytics.instance.recordError(e, st, fatal: false);
      }
    }
  }

  static void logMenuView() {
    if (!enabled) return;
    unawaited(
      _safeLog(() async {
        await FirebaseAnalytics.instance.logEvent(name: 'velour_menu_view');
      }),
    );
  }

  static void logPrepOpen({required String stakeKind}) {
    if (!enabled) return;
    unawaited(
      _safeLog(() async {
        await FirebaseAnalytics.instance.logEvent(
          name: 'velour_prep_open',
          parameters: <String, Object>{'stake_kind': stakeKind},
        );
      }),
    );
  }

  static void logRunStart({required String stakeKind}) {
    if (!enabled) return;
    unawaited(
      _safeLog(() async {
        await FirebaseAnalytics.instance.logEvent(
          name: 'velour_run_start',
          parameters: <String, Object>{'stake_kind': stakeKind},
        );
      }),
    );
  }

  static Future<void> _safeLog(Future<void> Function() body) async {
    try {
      await body();
    } catch (_) {}
  }
}
