import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:velour_app/l10n/app_localizations.dart';
import 'package:velour_app/main.dart' as app;
import 'package:velour_app/screens/game_screen.dart';
import 'package:velour_app/screens/leaderboard_view.dart';
import 'package:velour_app/screens/main_menu_view.dart';
import 'package:velour_app/screens/preparation_view.dart';
import 'package:velour_app/screens/settings_view.dart';
import 'package:velour_app/screens/shop_view.dart';
import 'package:velour_app/services/audio_handler.dart';
import 'package:velour_app/widgets/ui/pause_overlay.dart';
import 'package:velour_app/widgets/ui/universal_back_button.dart';

/// Smoke `integration_test` (app réelle : Firebase, audio, polices).
///
/// **CI GitHub** : `.github/workflows/flutter_ci.yml` utilise un **simulateur iOS**
/// (`-d <UDID>`) — le desktop macOS (`-d macos`) échoue souvent sur le runner
/// (`open` / foreground, voir flutter/flutter#176850).
///
/// **Local** : `flutter test integration_test/smoke_test.dart -d macos` si tu
/// préfères le binaire desktop ; ou `-d <UDID>` comme en CI pour coller à App Store.
///
/// **Nettoyage Xcode** (à l’occasion) : `flutter clean`, puis supprimer le dossier
/// DerivedData du projet dans Xcode (ou `~/Library/Developer/Xcode/DerivedData`)
/// avant de rouvrir le simulateur.
///
/// **Réseau** : [app.main] précharge les polices via `google_fonts` (HTTPS). Le binaire
/// macOS debug doit avoir l’entitlement sandbox `com.apple.security.network.client`
/// (`macos/Runner/DebugProfile.entitlements`) pour que les requêtes sortantes passent.
///
/// **Harness** : `velourRunAppStartup()` (`lib/velour_bootstrap.dart`, appelé depuis
/// `lib/main.dart`) n’installe pas les handlers Crashlytics globaux sous un binding de
/// test (`integration_test` / `flutter test`), pour ne pas écraser celui du framework.
bool get _velourGithubCi {
  try {
    return Platform.environment['CI'] == 'true' ||
        Platform.environment['GITHUB_ACTIONS'] == 'true';
  } catch (_) {
    return false;
  }
}

int _ciSteps(int local, int github) => _velourGithubCi ? github : local;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Un seul [testWidgets] + un seul [app.main] : évite les callbacks tardifs (ex.
  /// welcome LUX) qui survivent au teardown et touchent un [EconomyService] disposé.
  testWidgets('smoke: binding → menu → réglages → shop → classement → '
      'préparation → jeu → pause → reprise → pause → menu', (
    WidgetTester tester,
  ) async {
    expect(IntegrationTestWidgetsFlutterBinding.instance, isNotNull);

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await app.main();
    await tester.pump();
    // Splash + `bootstrapCloudAfterLocalLoad` / prefs : le runner GitHub est souvent
    // plus lent qu’une machine locale (budget QA widget ~22 s insuffisant).
    await _pumpUntil(
      tester,
      find.byType(MainMenuView),
      maxSteps: _ciSteps(220, 700),
    );

    await _reachClassicPlayZone(tester);
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('PlayZone')), findsOneWidget);

    final AppLocalizations l10nGame = AppLocalizations.of(
      tester.element(find.byType(GameScreen).first),
    )!;

    final Finder hudMenuBtn = find.byTooltip(l10nGame.gameHudMenuTooltip);
    await tester.ensureVisible(hudMenuBtn);
    await tester.tap(hudMenuBtn);
    await _pumpUntil(
      tester,
      find.byType(PauseOverlay),
      maxSteps: _ciSteps(120, 320),
    );

    final Finder pauseResume = find.text(l10nGame.pauseResume);
    await tester.ensureVisible(pauseResume);
    await tester.tap(pauseResume);
    await _pumpUntilAbsent(
      tester,
      find.byType(PauseOverlay),
      maxSteps: _ciSteps(120, 320),
    );

    await tester.ensureVisible(hudMenuBtn);
    await tester.tap(hudMenuBtn);
    await _pumpUntil(
      tester,
      find.byType(PauseOverlay),
      maxSteps: _ciSteps(120, 320),
    );

    final Finder pauseToMenu = find.text(l10nGame.pauseBackToMenu);
    await tester.ensureVisible(pauseToMenu);
    await tester.tap(pauseToMenu);
    await _pumpUntil(
      tester,
      find.byType(MainMenuView),
      maxSteps: _ciSteps(220, 420),
    );

    expect(find.byType(MainMenuView), findsWidgets);

    await _drainDeferredPlatformWork(tester);
    // Évite l’échec CI : `FramePositionUpdater` (audioplayers) après disposal du binding.
    await AudioHandler.instance.stopMusic();
    try {
      await AudioHandler.instance.dispose();
    } catch (_) {}
    final int settleFrames = _ciSteps(24, 96);
    for (int i = 0; i < settleFrames; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final Object? pending = tester.takeException();
    if (pending != null) {
      // ignore: avoid_print
      print('[VelourSmoke] takeException: $pending');
    }
    expect(
      pending,
      isNull,
      reason: 'Async exceptions after game teardown (CI?)',
    );
  });
}

/// Laisse partir timers / micro-tâches (IAP, Firestore) avant [takeException].
Future<void> _drainDeferredPlatformWork(WidgetTester tester) async {
  const Duration step = Duration(milliseconds: 100);
  final int steps = _ciSteps(40, 90);
  for (int i = 0; i < steps; i++) {
    await tester.pump(step);
  }
}

Future<void> _reachClassicPlayZone(WidgetTester tester) async {
  await _pumpUntil(tester, find.byType(MainMenuView), maxSteps: 100);
  expect(find.byType(MainMenuView), findsWidgets);

  final AppLocalizations l10nMenu = AppLocalizations.of(
    tester.element(find.byType(MainMenuView).first),
  )!;

  await tester.tap(find.text(l10nMenu.menuSettings));
  await _pumpUntil(
    tester,
    find.byType(SettingsView),
    maxSteps: _ciSteps(120, 300),
  );
  expect(find.byType(SettingsView), findsOneWidget);
  // Laisse finir la transition de route ; macOS CI peut être plus lent.
  await _pumpFrames(tester, 24, 50);
  // Ne pas taper l’Icon interne : avec matchTextDirection / Transform (hit tests
  // découplés), getCenter peut sortir du viewport étroit (ex. 390×844).
  final Finder settingsBack = find.descendant(
    of: find.byType(SettingsView),
    matching: find.byType(UniversalBackButton),
  );
  await tester.ensureVisible(settingsBack);
  await tester.tap(settingsBack);
  await _pumpUntil(
    tester,
    find.byType(MainMenuView),
    maxSteps: _ciSteps(120, 280),
  );
  // macOS / transitions : la route peut rester une frame dans l’arbre après pop.
  await _pumpUntilAbsent(
    tester,
    find.byType(SettingsView),
    maxSteps: _ciSteps(120, 220),
  );
  expect(find.byType(MainMenuView), findsWidgets);

  final AppLocalizations l10nMenu2 = AppLocalizations.of(
    tester.element(find.byType(MainMenuView).first),
  )!;

  await tester.tap(find.text(l10nMenu2.menuShop));
  await _pumpUntil(tester, find.byType(ShopView), maxSteps: _ciSteps(120, 300));
  expect(find.byType(ShopView), findsOneWidget);
  final AppLocalizations l10nShopFromMenu = AppLocalizations.of(
    tester.element(find.byType(ShopView).first),
  )!;
  final Finder shopBack = find.byTooltip(l10nShopFromMenu.shopBackTooltip);
  await tester.ensureVisible(shopBack);
  await tester.tap(shopBack);
  await _pumpUntil(
    tester,
    find.byType(MainMenuView),
    maxSteps: _ciSteps(120, 280),
  );
  await _pumpUntilAbsent(
    tester,
    find.byType(ShopView),
    maxSteps: _ciSteps(80, 180),
  );
  expect(find.byType(MainMenuView), findsWidgets);

  final AppLocalizations l10nMenuLb = AppLocalizations.of(
    tester.element(find.byType(MainMenuView).first),
  )!;
  await tester.tap(find.text(l10nMenuLb.menuLeaderboard));
  await _pumpUntil(
    tester,
    find.byType(LeaderboardView),
    maxSteps: _ciSteps(220, 400),
  );
  expect(find.byType(LeaderboardView), findsOneWidget);
  final Finder lbBack = find.descendant(
    of: find.byType(LeaderboardView),
    matching: find.byType(UniversalBackButton),
  );
  await tester.ensureVisible(lbBack);
  await tester.tap(lbBack);
  await _pumpUntil(
    tester,
    find.byType(MainMenuView),
    maxSteps: _ciSteps(120, 280),
  );
  await _pumpUntilAbsent(
    tester,
    find.byType(LeaderboardView),
    maxSteps: _ciSteps(80, 180),
  );
  expect(find.byType(MainMenuView), findsWidgets);

  final AppLocalizations l10nMenu3 = AppLocalizations.of(
    tester.element(find.byType(MainMenuView).first),
  )!;

  await tester.tap(find.text(l10nMenu3.menuPlay));
  await _pumpUntil(
    tester,
    find.byType(PreparationView),
    maxSteps: _ciSteps(120, 260),
  );
  expect(find.byType(PreparationView), findsOneWidget);

  final AppLocalizations l10nPrep = AppLocalizations.of(
    tester.element(find.byType(PreparationView).first),
  )!;

  await tester.tap(find.text(l10nPrep.prepModeCasualTitle));
  await _pumpFrames(tester, 8);

  await tester.tap(find.text(l10nPrep.prepConfirm));
  await _pumpUntil(
    tester,
    find.byKey(const ValueKey<String>('PlayZone')),
    maxSteps: _ciSteps(200, 520),
  );
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int maxSteps = 220,
  Duration step = const Duration(milliseconds: 100),
}) async {
  for (int i = 0; i < maxSteps; i++) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('finder still empty after ${maxSteps * step.inMilliseconds}ms: $finder');
}

Future<void> _pumpUntilAbsent(
  WidgetTester tester,
  Finder finder, {
  int maxSteps = 120,
  Duration step = const Duration(milliseconds: 50),
}) async {
  for (int i = 0; i < maxSteps; i++) {
    await tester.pump(step);
    if (finder.evaluate().isEmpty) {
      return;
    }
  }
  fail(
    'finder still present after ${maxSteps * step.inMilliseconds}ms: $finder',
  );
}

Future<void> _pumpFrames(WidgetTester tester, int frames, [int ms = 50]) async {
  for (int i = 0; i < frames; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}
