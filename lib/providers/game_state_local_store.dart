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
  });

  final bool isFirstLaunch;
  final int luxCoinsRaw;
  final bool trinityTutorialComplete;
  final bool isFirstTimeGame;
  final String? activeSkinIdRaw;
  final List<String>? unlockedSkinsRaw;
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
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> persistLuxCoins(int luxCoins) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(GameStatePrefs.luxCoins, luxCoins);
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
