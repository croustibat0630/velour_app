// Basic boot test: même arbre que `main.dart` (providers requis par SplashScreen / menu).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:velour_app/main.dart';
import 'package:velour_app/providers/game_state.dart';
import 'package:velour_app/theme/theme_engine.dart';

void main() {
  testWidgets('Velour app boots', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: <ChangeNotifierProvider<dynamic>>[
          ChangeNotifierProvider<GameState>(create: (_) => GameState()),
          ChangeNotifierProvider<ThemeEngine>(create: (_) => ThemeEngine()),
        ],
        child: const VelourApp(),
      ),
    );
    // Splash (≥2s) + transition menu.
    await tester.pump(const Duration(seconds: 4));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
