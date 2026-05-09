// Smoke : [GameScreen] se monte avec une session casual, layout réel, plateau initialisé.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velour_app/l10n/app_localizations.dart';
import 'package:velour_app/providers/game_state.dart';
import 'package:velour_app/screens/game_screen.dart';
import 'package:velour_app/theme/theme_engine.dart';

import 'support/firebase_for_tests.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ensureFirebaseTestInitialized();
    final TestDefaultBinaryMessengerBinding b =
        TestDefaultBinaryMessengerBinding.instance;
    for (final String name in <String>[
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers',
    ]) {
      b.defaultBinaryMessenger.setMockMethodCallHandler(
        MethodChannel(name),
        (MethodCall call) async => null,
      );
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('GameScreen boots casual run with PlayZone', (
    WidgetTester tester,
  ) async {
    final GameState gs = GameState();
    await gs.loadEconomyWelcome();
    await gs.loadHighScore();
    expect(gs.beginSession(SessionStakeKind.casual), isTrue);
    gs.startNewRun();

    await tester.pumpWidget(
      ChangeNotifierProvider<GameState>.value(
        value: gs,
        child: ChangeNotifierProvider<ThemeEngine>(
          create: (_) => ThemeEngine(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const GameScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    for (int i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find
              .byKey(const ValueKey<String>('PlayZone'))
              .evaluate()
              .isNotEmpty &&
          (gs.boardItems.isNotEmpty || gs.slotItems.isNotEmpty)) {
        break;
      }
    }

    expect(find.byKey(const ValueKey<String>('PlayZone')), findsOneWidget);
    expect(gs.boardItems.isNotEmpty || gs.slotItems.isNotEmpty, isTrue);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    gs.dispose();
  });
}
