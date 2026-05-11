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

  /// Ouverture de l’écran boutique (Coffre-Fort + Forge).
  static void logShopView() {
    if (!enabled) return;
    unawaited(
      _safeLog(() async {
        await FirebaseAnalytics.instance.logEvent(name: 'velour_shop_view');
      }),
    );
  }

  /// Début du flux d’achat coffre-fort (tap sur une carte pack).
  static void logShopVaultBuyStart({
    required String productId,
    required int luxAmount,
  }) {
    if (!enabled) return;
    unawaited(
      _safeLog(() async {
        await FirebaseAnalytics.instance.logEvent(
          name: 'velour_shop_vault_buy_start',
          parameters: <String, Object>{
            'product_id': productId,
            'lux_amount': luxAmount,
          },
        );
      }),
    );
  }

  /// Fin du flux d’achat côté client (`LuxIapService.buyVaultConsumable`).
  ///
  /// [outcome] : valeurs stables pour requêtes (`success`, `cancelled`, …).
  /// [errorCode] : uniquement pour `outcome == error` (ex. `offline`) — tronqué.
  /// Fin de run (chrono épuisé ou impasse plateau) — une fois la mise résolue.
  ///
  /// [stake_kind] : `casual` / `highStakes` / `royal` (même vocabulaire que `velour_run_start`).
  /// [end_reason] : `timer` | `deadlock`.
  /// [stake_footer] : résultat mise premium (`none`, `high_stakes_fail`, …).
  static void logRunEnd({
    required String stakeKind,
    required int level,
    required String endReason,
    required String stakeFooter,
    required int personalBest,
    required int runLux,
  }) {
    if (!enabled) return;
    unawaited(
      _safeLog(() async {
        await FirebaseAnalytics.instance.logEvent(
          name: 'velour_run_end',
          parameters: <String, Object>{
            'stake_kind': stakeKind,
            'level': level,
            'end_reason': endReason,
            'stake_footer': stakeFooter,
            'personal_best': personalBest,
            'run_lux': runLux,
          },
        );
      }),
    );
  }

  static void logShopVaultBuyOutcome({
    required String productId,
    required String outcome,
    String? errorCode,
  }) {
    if (!enabled) return;
    unawaited(
      _safeLog(() async {
        final Map<String, Object> parameters = <String, Object>{
          'product_id': productId,
          'outcome': outcome,
        };
        final String? code = errorCode;
        if (code != null && code.isNotEmpty) {
          parameters['error_code'] = code.length > 40
              ? code.substring(0, 40)
              : code;
        }
        await FirebaseAnalytics.instance.logEvent(
          name: 'velour_shop_vault_buy_outcome',
          parameters: parameters,
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
