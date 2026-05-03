import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:velour_app/l10n/app_localizations.dart';
import 'package:velour_app/screens/splash_screen.dart';
import 'package:velour_app/theme/theme_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Splash: spam maybePop pendant chargement', (
    WidgetTester tester,
  ) async {
    final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeEngine>(
        create: (_) => ThemeEngine(),
        child: MaterialApp(
          navigatorKey: navKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SplashScreen(),
        ),
      ),
    );
    await tester.pump();

    for (int i = 0; i < 200; i++) {
      navKey.currentState?.maybePop();
      await tester.pump(const Duration(milliseconds: 1));
    }

    expect(tester.takeException(), isNull);
  });
}
