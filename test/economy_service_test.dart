import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velour_app/providers/game_state.dart';
import 'package:velour_app/providers/game_state_local_store.dart';
import 'package:velour_app/services/economy_service.dart';
import 'package:velour_app/services/lux_apply_motifs.dart';

EconomyWelcomeLoad _disk({int lux = 0, bool firstLaunch = false}) {
  return EconomyWelcomeLoad(
    isFirstLaunch: firstLaunch,
    luxCoinsRaw: lux,
    trinityTutorialComplete: true,
    isFirstTimeGame: false,
    activeSkinIdRaw: null,
    unlockedSkinsRaw: null,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'addLuxCoins plafonne les crédits positifs (maxLuxPerPositiveCredit)',
    () async {
      final EconomyService e = EconomyService();
      e.hydrateLuxAndWelcomeFromDisk(_disk(lux: 10));
      e.addLuxCoins(
        EconomyService.maxLuxPerPositiveCredit + 5000,
        luxCloudMotif: LuxApplyMotifs.velourClientSync,
      );
      expect(e.luxCoins, 10 + EconomyService.maxLuxPerPositiveCredit);
    },
  );

  test('addLuxCoins ne plafonne pas les montants négatifs', () async {
    final EconomyService e = EconomyService();
    e.hydrateLuxAndWelcomeFromDisk(_disk(lux: 100));
    e.addLuxCoins(-150, luxCloudMotif: LuxApplyMotifs.shopSkin);
    expect(e.luxCoins, 0);
  });

  test('grantWelcomeLuxIfPending applique welcomeLuxGrant', () async {
    final EconomyService e = EconomyService();
    e.hydrateLuxAndWelcomeFromDisk(_disk(lux: 0, firstLaunch: true));
    expect(e.hasPendingWelcomeGift, isTrue);
    await e.grantWelcomeLuxIfPending();
    expect(e.hasPendingWelcomeGift, isFalse);
    expect(e.luxCoins, EconomyService.welcomeLuxGrant);
    final juice = e.takePendingLuxJuice();
    expect(juice.amount, EconomyService.welcomeLuxGrant);
    expect(juice.silent, isTrue);
  });

  test('mergeBootstrapFromCloud prend le max LUX et high score', () async {
    final EconomyService e = EconomyService();
    e.hydrateLuxAndWelcomeFromDisk(_disk(lux: 40));
    await e.loadHighScoreFromDisk();
    expect(e.highScore, 0);

    await e.mergeBootstrapFromCloud(
      pulled: (
        inventory: null,
        activeSkinId: null,
        cloudLuxCoins: 200,
        cloudHighScore: 500,
      ),
      pendingLux: 150,
      pendingHigh: 400,
    );
    expect(e.luxCoins, 200);
    expect(e.highScore, 500);
  });

  test(
    'mergeBootstrapFromCloud préserve la file pending LUX cloud par motif',
    () async {
      final GameStateLocalStore store = const GameStateLocalStore();
      final EconomyService e = EconomyService(localStore: store);
      e.hydrateLuxAndWelcomeFromDisk(_disk(lux: 40));
      e.addLuxCoins(100, luxCloudMotif: LuxApplyMotifs.stakeReward);
      expect(e.luxCoins, 140);

      await e.mergeBootstrapFromCloud(
        pulled: (
          inventory: null,
          activeSkinId: null,
          cloudLuxCoins: 50,
          cloudHighScore: 10,
        ),
        pendingLux: null,
        pendingHigh: null,
      );

      expect(e.luxCoins, 140);
      expect(e.highScore, 10);

      final Map<String, List<int>> loaded =
          await store.loadPendingLuxByMotifForCloud();
      expect(loaded[LuxApplyMotifs.stakeReward], <int>[100]);
    },
  );

  test('commitRunHighScoreIfBetter notifie le callback une fois', () async {
    final EconomyService e = EconomyService();
    int? seen;
    e.onPersonalBestCommitted = (int v) async {
      seen = v;
    };
    await e.loadHighScoreFromDisk();
    await e.commitRunHighScoreIfBetter(42);
    expect(e.highScore, 42);
    expect(seen, 42);
    await e.commitRunHighScoreIfBetter(30);
    expect(e.highScore, 42);
    expect(seen, 42);
  });

  test('GameState.welcomeLuxGrant aligné sur EconomyService', () {
    expect(GameState.welcomeLuxGrant, EconomyService.welcomeLuxGrant);
  });
}
