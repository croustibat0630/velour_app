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

  /// Mise consommée + nouvelle run mintée ; même `run_instance_id` que le prochain `velour_run_start`.
  static void logPrepLaunchConfirmed({
    required String stakeKind,
    String? runInstanceId,
  }) {
    if (!enabled) return;
    unawaited(
      _safeLog(() async {
        await FirebaseAnalytics.instance.logEvent(
          name: 'velour_prep_launch_confirmed',
          parameters: _withRunInstanceId(<String, Object>{
            'stake_kind': stakeKind,
          }, runInstanceId),
        );
      }),
    );
  }

  static void logLeaderboardView({String? runInstanceId}) {
    if (!enabled) return;
    unawaited(
      _safeLog(() async {
        final String? id = runInstanceId;
        final Map<String, Object>? params = (id != null && id.isNotEmpty)
            ? <String, Object>{'run_instance_id': id}
            : null;
        await FirebaseAnalytics.instance.logEvent(
          name: 'velour_leaderboard_view',
          parameters: params,
        );
      }),
    );
  }

  static void logStatsView({String? runInstanceId}) {
    if (!enabled) return;
    unawaited(
      _safeLog(() async {
        final String? id = runInstanceId;
        final Map<String, Object>? params = (id != null && id.isNotEmpty)
            ? <String, Object>{'run_instance_id': id}
            : null;
        await FirebaseAnalytics.instance.logEvent(
          name: 'velour_stats_view',
          parameters: params,
        );
      }),
    );
  }

  /// Résultat d’une tentative de réclamation du bonus LUX quotidien (menu).
  /// Ouverture des paramètres ([SettingsView]).
  static void logSettingsView({String? runInstanceId}) {
    if (!enabled) return;
    unawaited(
      _safeLog(() async {
        final String? id = runInstanceId;
        final Map<String, Object>? params = (id != null && id.isNotEmpty)
            ? <String, Object>{'run_instance_id': id}
            : null;
        await FirebaseAnalytics.instance.logEvent(
          name: 'velour_settings_view',
          parameters: params,
        );
      }),
    );
  }

  /// Résultat d’un achat Forge (LUX) depuis la boutique.
  ///
  /// [forge_item] : `chrono_pulse` / `mercy_salvage` / `oracle_insurance` / `royal_bounty`.
  static void logForgePurchaseOutcome({
    required String forgeItem,
    required String outcome,
    String? runInstanceId,
  }) {
    if (!enabled) return;
    unawaited(
      _safeLog(() async {
        await FirebaseAnalytics.instance.logEvent(
          name: 'velour_forge_purchase_outcome',
          parameters: _withRunInstanceId(<String, Object>{
            'forge_item': forgeItem,
            'outcome': outcome,
          }, runInstanceId),
        );
      }),
    );
  }

  static void logDailyLuxBonusOutcome({
    required String outcome,
    String? runInstanceId,
  }) {
    if (!enabled) return;
    unawaited(
      _safeLog(() async {
        await FirebaseAnalytics.instance.logEvent(
          name: 'velour_daily_lux_bonus_outcome',
          parameters: _withRunInstanceId(<String, Object>{
            'outcome': outcome,
          }, runInstanceId),
        );
      }),
    );
  }

  static Map<String, Object> _withRunInstanceId(
    Map<String, Object> parameters,
    String? runInstanceId,
  ) {
    final String? id = runInstanceId;
    if (id == null || id.isEmpty) return parameters;
    return <String, Object>{...parameters, 'run_instance_id': id};
  }

  static void logRunStart({required String stakeKind, String? runInstanceId}) {
    if (!enabled) return;
    unawaited(
      _safeLog(() async {
        await FirebaseAnalytics.instance.logEvent(
          name: 'velour_run_start',
          parameters: _withRunInstanceId(<String, Object>{
            'stake_kind': stakeKind,
          }, runInstanceId),
        );
      }),
    );
  }

  /// Ouverture de l’écran boutique (Coffre-Fort + Forge).
  static void logShopView({String? runInstanceId}) {
    if (!enabled) return;
    unawaited(
      _safeLog(() async {
        final String? id = runInstanceId;
        final Map<String, Object>? params = (id != null && id.isNotEmpty)
            ? <String, Object>{'run_instance_id': id}
            : null;
        await FirebaseAnalytics.instance.logEvent(
          name: 'velour_shop_view',
          parameters: params,
        );
      }),
    );
  }

  /// Début du flux d’achat coffre-fort (tap sur une carte pack).
  static void logShopVaultBuyStart({
    required String productId,
    required int luxAmount,
    String? runInstanceId,
  }) {
    if (!enabled) return;
    unawaited(
      _safeLog(() async {
        await FirebaseAnalytics.instance.logEvent(
          name: 'velour_shop_vault_buy_start',
          parameters: _withRunInstanceId(<String, Object>{
            'product_id': productId,
            'lux_amount': luxAmount,
          }, runInstanceId),
        );
      }),
    );
  }

  /// Fin de run (chrono épuisé ou impasse plateau) — une fois la mise résolue.
  ///
  /// [stake_kind] : `casual` / `highStakes` / `royal` (même vocabulaire que `velour_run_start`).
  /// [end_reason] : `timer` | `deadlock`.
  /// [stake_footer] : résultat mise premium (`none`, `high_stakes_fail`, …).
  /// [runInstanceId] : corrélation boutique / funnels (voir [GameState.analyticsRunInstanceId]).
  /// Fin de run — inclut [runDurationSec] (temps depuis [GameState.startGame]).
  static void logRunEnd({
    required String stakeKind,
    required int level,
    required String endReason,
    required String stakeFooter,
    required int personalBest,
    required int runLux,
    required int runDurationSec,
    String? runInstanceId,
  }) {
    if (!enabled) return;
    unawaited(
      _safeLog(() async {
        await FirebaseAnalytics.instance.logEvent(
          name: 'velour_run_end',
          parameters: _withRunInstanceId(<String, Object>{
            'stake_kind': stakeKind,
            'level': level,
            'end_reason': endReason,
            'stake_footer': stakeFooter,
            'personal_best': personalBest,
            'run_lux': runLux,
            'run_duration_sec': runDurationSec.clamp(0, 86400),
          }, runInstanceId),
        );
      }),
    );
  }

  /// Début d’un segment **premier plan** (complète `session_start` / `user_engagement`).
  static void logAppForegroundStart({required String routeName}) {
    if (!enabled) return;
    unawaited(
      _safeLog(() async {
        await FirebaseAnalytics.instance.logEvent(
          name: 'velour_app_foreground_start',
          parameters: <String, Object>{'route': _truncateParam(routeName)},
        );
      }),
    );
  }

  /// Temps passé au premier plan avant pause / arrière-plan / fermeture.
  static void logAppForegroundEnd({
    required int durationSec,
    required String lifecycle,
    required String routeName,
  }) {
    if (!enabled) return;
    unawaited(
      _safeLog(() async {
        await FirebaseAnalytics.instance.logEvent(
          name: 'velour_app_foreground_end',
          parameters: <String, Object>{
            'duration_sec': durationSec.clamp(1, 86400),
            'lifecycle': lifecycle,
            'route': _truncateParam(routeName),
          },
        );
      }),
    );
  }

  static String _truncateParam(String value) {
    if (value.length <= 100) return value;
    return value.substring(0, 100);
  }

  /// Fin du flux d’achat côté client (`LuxIapService.buyVaultConsumable`).
  ///
  /// [outcome] : valeurs stables pour requêtes (`success`, `cancelled`, …).
  /// [errorCode] : uniquement pour `outcome == error` (ex. `offline`) — tronqué.
  static void logShopVaultBuyOutcome({
    required String productId,
    required String outcome,
    String? errorCode,
    String? runInstanceId,
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
          parameters: _withRunInstanceId(parameters, runInstanceId),
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
