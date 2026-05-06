import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'game_state_prefs.dart';

/// Données brutes lues depuis le disque pour [GameState.loadEconomyWelcome].
class EconomyWelcomeLoad {
  const EconomyWelcomeLoad({
    required this.isFirstLaunch,
    required this.luxCoinsRaw,
    required this.trinityTutorialComplete,
    required this.isFirstTimeGame,
    required this.activeSkinIdRaw,
    required this.unlockedSkinsRaw,
    this.lastDailyLuxClaimUtcDay,
  });

  final bool isFirstLaunch;
  final int luxCoinsRaw;
  final bool trinityTutorialComplete;
  final bool isFirstTimeGame;
  final String? activeSkinIdRaw;
  final List<String>? unlockedSkinsRaw;

  /// `yyyy-MM-dd` UTC ou null si jamais réclamé.
  final String? lastDailyLuxClaimUtcDay;
}

/// Persistance locale ([SharedPreferences]) pour l’économie, skins et scores.
class GameStateLocalStore {
  const GameStateLocalStore();

  Future<EconomyWelcomeLoad?> loadEconomyWelcome() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return EconomyWelcomeLoad(
        isFirstLaunch: prefs.getBool(GameStatePrefs.firstLaunch) ?? true,
        luxCoinsRaw: prefs.getInt(GameStatePrefs.luxCoins) ?? 0,
        trinityTutorialComplete:
            prefs.getBool(GameStatePrefs.trinityTutorialComplete) ?? false,
        isFirstTimeGame: prefs.getBool(GameStatePrefs.isFirstTimeGame) ?? true,
        activeSkinIdRaw: prefs.getString(GameStatePrefs.activeSkinId),
        unlockedSkinsRaw: prefs.getStringList(GameStatePrefs.unlockedSkins),
        lastDailyLuxClaimUtcDay: prefs.getString(
          GameStatePrefs.lastDailyLuxClaimUtcDay,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> persistLastDailyLuxClaimUtcDay(String ymdUtc) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(GameStatePrefs.lastDailyLuxClaimUtcDay, ymdUtc);
    } catch (_) {}
  }

  Future<void> persistLuxCoins(int luxCoins) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(GameStatePrefs.luxCoins, luxCoins);
    } catch (_) {}
  }

  Future<Map<String, List<int>>> loadPendingLuxByMotifForCloud() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(GameStatePrefs.pendingLuxByMotifJson);
      if (raw == null || raw.isEmpty) return <String, List<int>>{};
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, List<int>>{};
      final Map<String, List<int>> out = <String, List<int>>{};
      for (final MapEntry entry in decoded.entries) {
        final Object? k0 = entry.key;
        final Object? v0 = entry.value;
        if (k0 is! String) continue;
        // Nouveau format: { motif: [int, int, ...] }
        if (v0 is List) {
          final List<int> q = <int>[];
          for (final Object? e in v0) {
            if (e is! num) continue;
            final int v = e.toInt();
            if (v == 0) continue;
            q.add(v);
          }
          if (q.isEmpty) continue;
          out[k0] = q;
          continue;
        }
        // Ancien format (migration): { motif: intSum }
        if (v0 is num) {
          final int v = v0.toInt();
          if (v == 0) continue;
          out[k0] = <int>[v];
        }
      }
      return out;
    } catch (_) {
      return <String, List<int>>{};
    }
  }

  Future<void> persistPendingLuxByMotifForCloud(
    Map<String, List<int>> pending,
  ) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (pending.isEmpty) {
        await prefs.remove(GameStatePrefs.pendingLuxByMotifJson);
        return;
      }
      final Map<String, List<int>> clean = <String, List<int>>{};
      for (final MapEntry<String, List<int>> e in pending.entries) {
        final String k = e.key;
        final List<int> v = e.value;
        if (k.isEmpty || v.isEmpty) continue;
        final List<int> q = <int>[];
        for (final int d in v) {
          if (d == 0) continue;
          q.add(d);
        }
        if (q.isEmpty) continue;
        clean[k] = q;
      }
      if (clean.isEmpty) {
        await prefs.remove(GameStatePrefs.pendingLuxByMotifJson);
        return;
      }
      await prefs.setString(
        GameStatePrefs.pendingLuxByMotifJson,
        jsonEncode(clean),
      );
    } catch (_) {}
  }

  Future<void> persistSkinsLocal({
    required String activeSkinId,
    required List<String> unlockedSkins,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(GameStatePrefs.activeSkinId, activeSkinId);
      await prefs.setStringList(GameStatePrefs.unlockedSkins, unlockedSkins);
    } catch (_) {}
  }

  Future<void> persistWelcomeGrant(int luxCoins) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(GameStatePrefs.luxCoins, luxCoins);
      await prefs.setBool(GameStatePrefs.firstLaunch, false);
    } catch (_) {}
  }

  Future<void> debugResetFirstLaunchWelcome() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(GameStatePrefs.firstLaunch, true);
      await prefs.setInt(GameStatePrefs.luxCoins, 0);
      await prefs.remove(GameStatePrefs.pendingLuxByMotifJson);
    } catch (_) {}
  }

  Future<void> clearAll() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}
  }

  Future<int> loadHighScoreOrZero() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getInt(GameStatePrefs.highScore) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> persistHighScore(int highScore) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(GameStatePrefs.highScore, highScore);
    } catch (_) {}
  }

  Future<void> persistTrinityTutorialComplete() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(GameStatePrefs.trinityTutorialComplete, true);
    } catch (_) {}
  }

  Future<void> persistNarrativeTutorialComplete() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(GameStatePrefs.isFirstTimeGame, false);
      await prefs.setBool(GameStatePrefs.trinityTutorialComplete, true);
    } catch (_) {}
  }

  Future<
    ({
      int insuranceCharges,
      bool royalBounty,
      int chronoPulseCharges,
      int mercySalvageCharges,
    })
  >
  loadForgeShop() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int charges =
          (prefs.getInt(GameStatePrefs.oracleInsuranceCharges) ?? 0).clamp(
            0,
            99,
          );
      final bool royal =
          prefs.getBool(GameStatePrefs.royalVictoryBountyPending) ?? false;
      final int chrono =
          (prefs.getInt(GameStatePrefs.forgeChronoPulseCharges) ?? 0).clamp(
            0,
            99,
          );
      final int mercy =
          (prefs.getInt(GameStatePrefs.forgeMercySalvageCharges) ?? 0).clamp(
            0,
            99,
          );
      return (
        insuranceCharges: charges,
        royalBounty: royal,
        chronoPulseCharges: chrono,
        mercySalvageCharges: mercy,
      );
    } catch (_) {
      return (
        insuranceCharges: 0,
        royalBounty: false,
        chronoPulseCharges: 0,
        mercySalvageCharges: 0,
      );
    }
  }

  Future<void> persistForgeShop({
    required int insuranceCharges,
    required bool royalVictoryBountyPending,
    required int chronoPulseCharges,
    required int mercySalvageCharges,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        GameStatePrefs.oracleInsuranceCharges,
        insuranceCharges.clamp(0, 99),
      );
      await prefs.setBool(
        GameStatePrefs.royalVictoryBountyPending,
        royalVictoryBountyPending,
      );
      await prefs.setInt(
        GameStatePrefs.forgeChronoPulseCharges,
        chronoPulseCharges.clamp(0, 99),
      );
      await prefs.setInt(
        GameStatePrefs.forgeMercySalvageCharges,
        mercySalvageCharges.clamp(0, 99),
      );
    } catch (_) {}
  }
}
