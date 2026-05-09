import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:velour_app/l10n/app_localizations.dart';
import 'package:velour_app/main.dart' as app;
import 'package:velour_app/screens/game_screen.dart';
import 'package:velour_app/screens/main_menu_view.dart';
import 'package:velour_app/screens/preparation_view.dart';

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
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('integration binding initialisé', (WidgetTester tester) async {
    expect(IntegrationTestWidgetsFlutterBinding.instance, isNotNull);
  });

  testWidgets('smoke: menu → préparation → partie (GameScreen + PlayZone)', (
    WidgetTester tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await app.main();
    await tester.pump();

    await _pumpUntil(tester, find.byType(MainMenuView));
    expect(find.byType(MainMenuView), findsWidgets);

    final AppLocalizations l10nMenu = AppLocalizations.of(
      tester.element(find.byType(MainMenuView).first),
    )!;

    await tester.tap(find.text(l10nMenu.menuPlay));
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

    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('PlayZone')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
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

Future<void> _pumpFrames(WidgetTester tester, int frames, [int ms = 50]) async {
  for (int i = 0; i < frames; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}
