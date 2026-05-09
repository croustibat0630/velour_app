// Parcours QA automatisé : splash → menu → réglages → préparation → retour,
// puis changements de viewport (tablette / paysage compact).
// Logs stdout préfixés [VelourQA] pour filtrage (`flutter test ... 2>&1 | rg VelourQA`).
//
// Note : le menu utilise une animation répétée ; on évite [pumpAndSettle] tant
// que [MainMenuView] est la route visible (il ne « settle » jamais).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velour_app/l10n/app_localizations.dart';
import 'package:velour_app/main.dart';
import 'package:velour_app/providers/game_state.dart';
import 'package:velour_app/screens/main_menu_view.dart';
import 'package:velour_app/screens/preparation_view.dart';
import 'package:velour_app/screens/settings_view.dart';
import 'package:velour_app/theme/theme_engine.dart';

void _qa(String message) {
  // ignore: avoid_print
  print('[VelourQA] $message');
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
}

Future<void> _pumpThroughSplash(WidgetTester tester) async {
  _qa('waiting for splash → main menu (bootstrap cloud, max ~22s)');
  await tester.pump();
  await _pumpUntil(tester, find.byType(MainMenuView));
}

Future<void> _pumpFrames(WidgetTester tester, int frames, [int ms = 50]) async {
  for (int i = 0; i < frames; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

Future<void> _setViewport(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  await tester.pump();
  _qa('viewport ${size.width.toInt()}x${size.height.toInt()}');
}

AppLocalizations _l10nOnMenu(WidgetTester tester) {
  final Element menuEl = tester.element(find.byType(MainMenuView).first);
  return AppLocalizations.of(menuEl)!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('QA: splash, menu, settings, prep, responsive sizes', (
    WidgetTester tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await _setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(
      MultiProvider(
        providers: <ChangeNotifierProvider<dynamic>>[
          ChangeNotifierProvider<GameState>(create: (_) => GameState()),
          ChangeNotifierProvider<ThemeEngine>(create: (_) => ThemeEngine()),
        ],
        child: const VelourApp(),
      ),
    );
    await tester.pump();

    await _pumpThroughSplash(tester);

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(MainMenuView), findsWidgets);
    _qa('main menu visible');

    AppLocalizations l10n = _l10nOnMenu(tester);
    _qa('locale menuPlay="${l10n.menuPlay}" settings="${l10n.menuSettings}"');

    await tester.tap(find.text(l10n.menuSettings));
    await _pumpUntil(tester, find.byType(SettingsView), maxSteps: 80);
    expect(find.byType(SettingsView), findsOneWidget);
    _qa('settings open');

    await tester.tap(
      find.descendant(
        of: find.byType(SettingsView),
        matching: find.byIcon(Icons.arrow_back_rounded),
      ),
    );
    await _pumpFrames(tester, 50);
    expect(find.byType(SettingsView), findsNothing);
    expect(find.byType(MainMenuView), findsWidgets);
    _qa('back to menu from settings');

    l10n = _l10nOnMenu(tester);
    await tester.tap(find.text(l10n.menuPlay));
    await _pumpUntil(tester, find.byType(PreparationView), maxSteps: 80);
    expect(find.byType(PreparationView), findsOneWidget);
    _qa('preparation (session setup) open');

    await tester.tap(
      find.descendant(
        of: find.byType(PreparationView),
        matching: find.byIcon(Icons.arrow_back_rounded),
      ),
    );
    await _pumpFrames(tester, 50);
    expect(find.byType(PreparationView), findsNothing);
    expect(find.byType(MainMenuView), findsWidgets);
    _qa('back to menu from preparation');

    await _setViewport(tester, const Size(1024, 768));
    await _pumpFrames(tester, 30);
    expect(find.byType(MainMenuView), findsWidgets);
    _qa('tablet-ish viewport: menu still laid out');

    await _setViewport(tester, const Size(844, 390));
    await _pumpFrames(tester, 30);
    expect(find.byType(MainMenuView), findsWidgets);
    _qa('compact-height landscape: menu still laid out');

    expect(tester.takeException(), isNull);
    _qa('done (no pending test exception)');
  });
}
