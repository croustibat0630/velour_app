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

  static const String kWelcomeLuxGrant = 'welcome_lux_grant';
  static const String kDailyLuxBonus = 'daily_lux_bonus';
  static const String kHighStakesWinLux = 'high_stakes_win_lux';
  static const String kHighStakesTargetLevel = 'high_stakes_target_level';
  static const String kRoyalAnteLux = 'royal_ante_lux';
  static const String kRoyalWinLux = 'royal_win_lux';
  static const String kRoyalTargetLevel = 'royal_target_level';

  static const Map<String, Object> _defaults = <String, Object>{
    kWelcomeLuxGrant: 250,
    kDailyLuxBonus: 50,
    kHighStakesWinLux: 150,
    kHighStakesTargetLevel: 3,
    kRoyalAnteLux: 250,
    kRoyalWinLux: 1250,
    kRoyalTargetLevel: 5,
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
      await rc.fetchAndActivate().timeout(
        const Duration(seconds: 6),
        onTimeout: () => false,
      );
    } catch (_) {
      // Silent: defaults will be used.
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
}
