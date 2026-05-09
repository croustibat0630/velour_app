import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:velour_app/l10n/app_localizations.dart';
import 'package:velour_app/providers/game_state.dart';
import 'package:velour_app/widgets/ui/game_over_overlay.dart';

void main() {
  testWidgets('GameOverOverlay exposes title and CTAs to semantics', (
    WidgetTester tester,
  ) async {
    final GameState gs = GameState();
    addTearDown(gs.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<GameState>.value(
        value: gs,
        child: MaterialApp(
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MediaQuery(
            // Avoid pumpAndSettle timeout: overlay badge pulse respects reduce motion.
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: GameOverOverlay(
                rawMatchLuxTotal: 120,
                finalLux: 120,
                careerHighScore: 500,
                finalLevel: 2,
                endedStakeKind: SessionStakeKind.casual,
                prestigeMultiplier: null,
                stakeRewardLuxCoins: 0,
                isPremiumWin: false,
                isPersonalBest: false,
                recordAccentColor: const Color(0xFF00FFFF),
                onReplay: () async {},
                onMenu: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('SESSION COMPLETE'), findsOneWidget);
    expect(find.bySemanticsLabel('PLAY AGAIN'), findsOneWidget);
    expect(find.bySemanticsLabel('MAIN MENU'), findsOneWidget);
  });
}
