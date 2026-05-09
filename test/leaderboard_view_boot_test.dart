import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velour_app/l10n/app_localizations.dart';
import 'package:velour_app/providers/game_state.dart';
import 'package:velour_app/screens/leaderboard_view.dart';
import 'package:velour_app/theme/theme_engine.dart';

import 'support/firebase_for_tests.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ensureFirebaseTestInitialized();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('LeaderboardView mounts with Firebase test harness', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: <ChangeNotifierProvider<dynamic>>[
          ChangeNotifierProvider<GameState>(create: (_) => GameState()),
          ChangeNotifierProvider<ThemeEngine>(create: (_) => ThemeEngine()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LeaderboardView(),
        ),
      ),
    );
    await tester.pump();
    for (int i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
