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
import 'package:velour_app/widgets/ui/pause_overlay.dart';
import 'package:velour_app/widgets/ui/universal_back_button.dart';

/// Smoke `integration_test` (app réelle : Firebase, audio, polices).
///
/// **Simulateur iOS** : si Xcode plante (`SDKStatCaches` manquant, etc.), lancer
/// explicitement sur desktop : `flutter test integration_test/smoke_test.dart -d macos`.
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

    await _reachClassicPlayZone(tester);
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('PlayZone')), findsOneWidget);

    final AppLocalizations l10nGame = AppLocalizations.of(
      tester.element(find.byType(GameScreen).first),
    )!;

    await tester.tap(find.byTooltip(l10nGame.gameHudMenuTooltip));
    await _pumpUntil(tester, find.byType(PauseOverlay), maxSteps: 120);

    await tester.tap(find.text(l10nGame.pauseResume));
    await _pumpUntilAbsent(tester, find.byType(PauseOverlay), maxSteps: 120);

    await tester.tap(find.byTooltip(l10nGame.gameHudMenuTooltip));
    await _pumpUntil(tester, find.byType(PauseOverlay), maxSteps: 120);

    await tester.tap(find.text(l10nGame.pauseBackToMenu));
    await _pumpUntil(tester, find.byType(MainMenuView), maxSteps: 220);

    expect(find.byType(MainMenuView), findsWidgets);

    await _drainDeferredPlatformWork(tester);
    expect(tester.takeException(), isNull);
  });
}

/// Laisse partir timers / micro-tâches (IAP, Firestore) avant [takeException].
Future<void> _drainDeferredPlatformWork(WidgetTester tester) async {
  const Duration step = Duration(milliseconds: 100);
  const int steps = 40;
  for (int i = 0; i < steps; i++) {
    await tester.pump(step);
  }
}

Future<void> _reachClassicPlayZone(WidgetTester tester) async {
  await _pumpUntil(tester, find.byType(MainMenuView));
  expect(find.byType(MainMenuView), findsWidgets);

  final AppLocalizations l10nMenu = AppLocalizations.of(
    tester.element(find.byType(MainMenuView).first),
  )!;

  await tester.tap(find.text(l10nMenu.menuSettings));
  await _pumpUntil(tester, find.byType(SettingsView), maxSteps: 120);
  expect(find.byType(SettingsView), findsOneWidget);

  await tester.tap(
    find.descendant(
      of: find.byType(SettingsView),
      matching: find.byIcon(Icons.arrow_back_rounded),
    ),
  );
  await _pumpUntil(tester, find.byType(MainMenuView), maxSteps: 120);
  // macOS / transitions : la route peut rester une frame dans l’arbre après pop.
  await _pumpUntilAbsent(tester, find.byType(SettingsView), maxSteps: 120);
  expect(find.byType(MainMenuView), findsWidgets);

  final AppLocalizations l10nMenu2 = AppLocalizations.of(
    tester.element(find.byType(MainMenuView).first),
  )!;

  await tester.tap(find.text(l10nMenu2.menuShop));
  await _pumpUntil(tester, find.byType(ShopView), maxSteps: 120);
  expect(find.byType(ShopView), findsOneWidget);
  final AppLocalizations l10nShopFromMenu = AppLocalizations.of(
    tester.element(find.byType(ShopView).first),
  )!;
  await tester.tap(find.byTooltip(l10nShopFromMenu.shopBackTooltip));
  await _pumpUntil(tester, find.byType(MainMenuView), maxSteps: 120);
  await _pumpUntilAbsent(tester, find.byType(ShopView), maxSteps: 80);
  expect(find.byType(MainMenuView), findsWidgets);

  final AppLocalizations l10nMenuLb = AppLocalizations.of(
    tester.element(find.byType(MainMenuView).first),
  )!;
  await tester.tap(find.text(l10nMenuLb.menuLeaderboard));
  await _pumpUntil(tester, find.byType(LeaderboardView), maxSteps: 220);
  expect(find.byType(LeaderboardView), findsOneWidget);
  await tester.tap(
    find.descendant(
      of: find.byType(LeaderboardView),
      matching: find.byType(UniversalBackButton),
    ),
  );
  await _pumpUntil(tester, find.byType(MainMenuView), maxSteps: 120);
  await _pumpUntilAbsent(tester, find.byType(LeaderboardView), maxSteps: 80);
  expect(find.byType(MainMenuView), findsWidgets);

  final AppLocalizations l10nMenu3 = AppLocalizations.of(
    tester.element(find.byType(MainMenuView).first),
  )!;

  await tester.tap(find.text(l10nMenu3.menuPlay));
  await _pumpUntil(tester, find.byType(PreparationView), maxSteps: 120);
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
    maxSteps: 200,
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
