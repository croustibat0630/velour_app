import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velour_app/l10n/app_localizations.dart';
import 'package:velour_app/providers/game_state.dart';
import 'package:velour_app/screens/shop_view.dart';
import 'package:velour_app/theme/theme_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('ShopView mounts with providers (vault UI)', (
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
          home: const ShopView(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(ShopView), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
