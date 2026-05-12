import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Remote Config Velour (tuning runtime).
///
/// Objectif: pouvoir ajuster rétention/économie sans rebuild (Forge, stakes, gifts).
/// Les getters sont **synchrones** et retombent sur des valeurs par défaut si
/// Remote Config n’est pas initialisé (tests, offline, ou échec réseau).
class VelourRemoteConfig {
  VelourRemoteConfig._();

  static final VelourRemoteConfig instance = VelourRemoteConfig._();

  static bool _looksLikeInstallationsKeychainHarnessFailure(Object e) {
    final String s = e.toString().toLowerCase();
    return s.contains('secitemadd') ||
        s.contains('-34018') ||
        s.contains('installations token') ||
        s.contains('com.gul.keychain') ||
        s.contains('com.firebase.installations');
  }

  static const String kWelcomeLuxGrant = 'welcome_lux_grant';
  static const String kDailyLuxBonus = 'daily_lux_bonus';
  static const String kHighStakesWinLux = 'high_stakes_win_lux';
  static const String kHighStakesTargetLevel = 'high_stakes_target_level';
  static const String kRoyalAnteLux = 'royal_ante_lux';
  static const String kRoyalWinLux = 'royal_win_lux';
  static const String kRoyalTargetLevel = 'royal_target_level';

  /// Tuning chrono : multiplicateurs ×100 (ex. 88 → drain 88 % du nominal sous 10 % jauge).
  static const String kRunTimerClutchMult10 = 'run_timer_clutch_mult_10';
  static const String kRunTimerClutchMult20 = 'run_timer_clutch_mult_20';
  static const String kRunTimerClutchMult35 = 'run_timer_clutch_mult_35';
  static const String kRunIdleSoftSec = 'run_idle_soft_sec';
  static const String kRunIdleHardSec = 'run_idle_hard_sec';

  /// Spawn / Perfect Heat : paliers Heat et clamp biais complétion (×100 = probabilité).
  static const String kBoardFlowUnderrepMinHeat =
      'board_flow_underrep_min_heat';
  static const String kBoardFlowBiasT5Pct = 'board_flow_bias_t5_pct';
  static const String kBoardFlowBiasT4Pct = 'board_flow_bias_t4_pct';
  static const String kBoardFlowBiasT3Pct = 'board_flow_bias_t3_pct';
  static const String kBoardFlowRescueFloorPct = 'board_flow_rescue_floor_pct';
  static const String kBoardFlowBiasClampMinPct =
      'board_flow_bias_clamp_min_pct';
  static const String kBoardFlowBiasClampMaxPct =
      'board_flow_bias_clamp_max_pct';

  /// Méta niveau : permille pour forces &lt; 1 ; EMA alpha = permille / 1000.
  static const String kMetaWavePermille = 'meta_wave_permille';
  static const String kMetaDdaPermille = 'meta_dda_permille';
  static const String kMetaNeutralEmaLuxPerMin = 'meta_neutral_ema_lux_per_min';
  static const String kMetaEmaAlphaPermille = 'meta_ema_alpha_permille';
  static const String kMetaDdaDivisor = 'meta_dda_divisor';

  static const Map<String, Object> _defaults = <String, Object>{
    kWelcomeLuxGrant: 250,
    kDailyLuxBonus: 50,
    kHighStakesWinLux: 150,
    kHighStakesTargetLevel: 3,
    kRoyalAnteLux: 250,
    kRoyalWinLux: 1250,
    kRoyalTargetLevel: 5,
    kRunTimerClutchMult10: 88,
    kRunTimerClutchMult20: 94,
    kRunTimerClutchMult35: 98,
    kRunIdleSoftSec: 5,
    kRunIdleHardSec: 12,
    kBoardFlowUnderrepMinHeat: 4,
    kBoardFlowBiasT5Pct: 20,
    kBoardFlowBiasT4Pct: 24,
    kBoardFlowBiasT3Pct: 27,
    kBoardFlowRescueFloorPct: 36,
    kBoardFlowBiasClampMinPct: 8,
    kBoardFlowBiasClampMaxPct: 45,
    kMetaWavePermille: 55,
    kMetaDdaPermille: 42,
    kMetaNeutralEmaLuxPerMin: 280,
    kMetaEmaAlphaPermille: 140,
    kMetaDdaDivisor: 420,
  };

  FirebaseRemoteConfig? _rc;

  Future<void> init() async {
    try {
      final FirebaseRemoteConfig rc = FirebaseRemoteConfig.instance;
      _rc = rc;
      await rc.setDefaults(_defaults);
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 6),
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(hours: 1),
        ),
      );

      // Best-effort: ne pas bloquer le lancement du jeu.
      final bool activated = await rc.fetchAndActivate().timeout(
        const Duration(seconds: 6),
        onTimeout: () {
          debugPrint(
            '[VelourRemoteConfig] fetchAndActivate timed out after 6s; '
            'embedded defaults apply until the next successful fetch.',
          );
          return false;
        },
      );
      if (!activated) {
        debugPrint(
          '[VelourRemoteConfig] fetchAndActivate returned false (no new config '
          'or fetch skipped); values may stay on defaults or a prior activation.',
        );
      }
    } catch (e, st) {
      debugPrint(
        '[VelourRemoteConfig] init failed, using embedded defaults: $e',
      );
      if (!_looksLikeInstallationsKeychainHarnessFailure(e)) {
        debugPrint('$st');
      } else {
        debugPrint(
          '[VelourRemoteConfig] stack trace omitted (Installations / keychain '
          'harness — embedded defaults apply).',
        );
      }
    }
  }

  int _int(String key, int fallback) {
    final FirebaseRemoteConfig? rc = _rc;
    if (rc == null) return fallback;
    try {
      final int v = rc.getInt(key);
      if (v == 0 && fallback != 0) {
        // RC returns 0 for missing keys; treat as fallback.
        return fallback;
      }
      return v;
    } catch (_) {
      return fallback;
    }
  }

  int get welcomeLuxGrant =>
      _int(kWelcomeLuxGrant, _defaults[kWelcomeLuxGrant]! as int);
  int get dailyLuxBonus =>
      _int(kDailyLuxBonus, _defaults[kDailyLuxBonus]! as int);

  int get highStakesWinLux =>
      _int(kHighStakesWinLux, _defaults[kHighStakesWinLux]! as int);
  int get highStakesTargetLevel =>
      _int(kHighStakesTargetLevel, _defaults[kHighStakesTargetLevel]! as int);

  int get royalAnteLux => _int(kRoyalAnteLux, _defaults[kRoyalAnteLux]! as int);
  int get royalWinLux => _int(kRoyalWinLux, _defaults[kRoyalWinLux]! as int);
  int get royalTargetLevel =>
      _int(kRoyalTargetLevel, _defaults[kRoyalTargetLevel]! as int);

  // --- Run timer tension (clutch + idle hurry) ---

  double get runTimerClutchMultBelow10 =>
      _int(
        kRunTimerClutchMult10,
        _defaults[kRunTimerClutchMult10]! as int,
      ).clamp(50, 99) /
      100.0;

  double get runTimerClutchMultBelow20 =>
      _int(
        kRunTimerClutchMult20,
        _defaults[kRunTimerClutchMult20]! as int,
      ).clamp(50, 99) /
      100.0;

  double get runTimerClutchMultBelow35 =>
      _int(
        kRunTimerClutchMult35,
        _defaults[kRunTimerClutchMult35]! as int,
      ).clamp(50, 100) /
      100.0;

  int get runIdleSoftStartSec =>
      _int(kRunIdleSoftSec, _defaults[kRunIdleSoftSec]! as int).clamp(2, 45);

  int get runIdleHardStartSec {
    final int soft = runIdleSoftStartSec;
    final int raw = _int(kRunIdleHardSec, _defaults[kRunIdleHardSec]! as int);
    final int lo = soft + 1;
    const int hi = 90;
    if (lo > hi) {
      return hi;
    }
    return raw.clamp(lo, hi);
  }

  // --- Board flow (Heat spawn) ---

  int get boardFlowUnderrepMinHeat => _int(
    kBoardFlowUnderrepMinHeat,
    _defaults[kBoardFlowUnderrepMinHeat]! as int,
  ).clamp(1, 5);

  double get boardFlowBiasT5 =>
      _int(
        kBoardFlowBiasT5Pct,
        _defaults[kBoardFlowBiasT5Pct]! as int,
      ).clamp(5, 50) /
      100.0;

  double get boardFlowBiasT4 =>
      _int(
        kBoardFlowBiasT4Pct,
        _defaults[kBoardFlowBiasT4Pct]! as int,
      ).clamp(5, 50) /
      100.0;

  double get boardFlowBiasT3 =>
      _int(
        kBoardFlowBiasT3Pct,
        _defaults[kBoardFlowBiasT3Pct]! as int,
      ).clamp(5, 50) /
      100.0;

  double get boardFlowRescueFloor =>
      _int(
        kBoardFlowRescueFloorPct,
        _defaults[kBoardFlowRescueFloorPct]! as int,
      ).clamp(10, 50) /
      100.0;

  double get boardFlowBiasClampMin =>
      _int(
        kBoardFlowBiasClampMinPct,
        _defaults[kBoardFlowBiasClampMinPct]! as int,
      ).clamp(3, 25) /
      100.0;

  double get boardFlowBiasClampMax =>
      _int(
        kBoardFlowBiasClampMaxPct,
        _defaults[kBoardFlowBiasClampMaxPct]! as int,
      ).clamp(20, 60) /
      100.0;

  // --- Meta progression (level curve + DDA) ---

  double get metaWaveStrength =>
      _int(
        kMetaWavePermille,
        _defaults[kMetaWavePermille]! as int,
      ).clamp(0, 80) /
      1000.0;

  double get metaDdaStrength =>
      _int(kMetaDdaPermille, _defaults[kMetaDdaPermille]! as int).clamp(0, 55) /
      1000.0;

  double get metaNeutralLuxPerMinute => _int(
    kMetaNeutralEmaLuxPerMin,
    _defaults[kMetaNeutralEmaLuxPerMin]! as int,
  ).clamp(50, 800).toDouble();

  double get metaEmaAlpha =>
      _int(
        kMetaEmaAlphaPermille,
        _defaults[kMetaEmaAlphaPermille]! as int,
      ).clamp(20, 400) /
      1000.0;

  int get metaDdaCenterDivisor =>
      _int(kMetaDdaDivisor, _defaults[kMetaDdaDivisor]! as int).clamp(120, 900);
}
