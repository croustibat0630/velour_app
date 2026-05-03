import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velour_app/providers/game_state_local_store.dart';
import 'package:velour_app/providers/game_state_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const GameStateLocalStore store = GameStateLocalStore();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('loadEconomyWelcome : valeurs par défaut si prefs vides', () async {
    final EconomyWelcomeLoad? r = await store.loadEconomyWelcome();
    expect(r, isNotNull);
    expect(r!.isFirstLaunch, isTrue);
    expect(r.luxCoinsRaw, 0);
    expect(r.trinityTutorialComplete, isFalse);
    expect(r.isFirstTimeGame, isTrue);
    expect(r.activeSkinIdRaw, isNull);
    expect(r.unlockedSkinsRaw, isNull);
  });

  test('loadEconomyWelcome : reflète les prefs mockées', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      GameStatePrefs.firstLaunch: false,
      GameStatePrefs.luxCoins: 120,
      GameStatePrefs.trinityTutorialComplete: true,
      GameStatePrefs.isFirstTimeGame: false,
      GameStatePrefs.activeSkinId: 'neon_cyan',
      GameStatePrefs.unlockedSkins: <String>['standard', 'neon_cyan'],
    });
    final EconomyWelcomeLoad? r = await store.loadEconomyWelcome();
    expect(r, isNotNull);
    expect(r!.isFirstLaunch, isFalse);
    expect(r.luxCoinsRaw, 120);
    expect(r.trinityTutorialComplete, isTrue);
    expect(r.isFirstTimeGame, isFalse);
    expect(r.activeSkinIdRaw, 'neon_cyan');
    expect(r.unlockedSkinsRaw, <String>['standard', 'neon_cyan']);
  });

  test('persistLuxCoins puis relecture', () async {
    await store.persistLuxCoins(77);
    final SharedPreferences p = await SharedPreferences.getInstance();
    expect(p.getInt(GameStatePrefs.luxCoins), 77);
  });

  test('persistHighScore puis loadHighScoreOrZero', () async {
    await store.persistHighScore(9001);
    expect(await store.loadHighScoreOrZero(), 9001);
  });

  test('persistWelcomeGrant : LUX + premier lancement terminé', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      GameStatePrefs.firstLaunch: true,
      GameStatePrefs.luxCoins: 0,
    });
    await store.persistWelcomeGrant(250);
    final SharedPreferences p = await SharedPreferences.getInstance();
    expect(p.getInt(GameStatePrefs.luxCoins), 250);
    expect(p.getBool(GameStatePrefs.firstLaunch), isFalse);
  });

  test('persistNarrativeTutorialComplete', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      GameStatePrefs.isFirstTimeGame: true,
      GameStatePrefs.trinityTutorialComplete: false,
    });
    await store.persistNarrativeTutorialComplete();
    final SharedPreferences p = await SharedPreferences.getInstance();
    expect(p.getBool(GameStatePrefs.isFirstTimeGame), isFalse);
    expect(p.getBool(GameStatePrefs.trinityTutorialComplete), isTrue);
  });

  test('clearAll efface les clés', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      GameStatePrefs.luxCoins: 50,
      GameStatePrefs.highScore: 100,
    });
    await store.clearAll();
    final SharedPreferences p = await SharedPreferences.getInstance();
    expect(p.getInt(GameStatePrefs.luxCoins), isNull);
    expect(p.getInt(GameStatePrefs.highScore), isNull);
  });
}
