import 'dart:async';

import 'package:flutter/material.dart';
import 'package:velour_app/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/game_state.dart';
import 'screens/game_screen.dart';
import 'screens/leaderboard_view.dart';
import 'screens/main_menu_view.dart';
import 'screens/splash_screen.dart';
import 'screens/settings_view.dart';
import 'screens/stats_view.dart';
import 'screens/shop_view.dart';
import 'theme/theme_engine.dart';
import 'widgets/ui/welcome_gift_global_layer.dart';
import 'utils/route_transition_observer.dart';
import 'utils/velour_route_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Indispensable
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Web stability: prefer long-polling over unstable websocket/QUIC paths.
  // These flags are no-ops on mobile/desktop, but help Chrome on flaky networks.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  runApp(const VelourApp());
}

class VelourApp extends StatelessWidget {
  const VelourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final GameState gs = GameState();
            unawaited(gs.loadEconomyWelcome());
            unawaited(gs.loadHighScore());
            return gs;
          },
        ),
        ChangeNotifierProvider(create: (_) => ThemeEngine()),
      ],
      child: Consumer2<GameState, ThemeEngine>(
        builder: (context, gs, te, _) {
          // Applique le skin post-frame (évite notify pendant build).
          final Color p = gs.currentSkin.primaryColor;
          final Color s = gs.currentSkin.secondaryColor;
          if (te.skinPrimaryOverride != p || te.skinSecondaryOverride != s) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              te.applySkinColors(primary: p, secondary: s);
            });
          }
          return MaterialApp(
            onGenerateTitle: (BuildContext context) =>
                AppLocalizations.of(context)?.appTitle ?? 'Velour',
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  child ?? const SizedBox.shrink(),
                  const WelcomeGiftGlobalLayer(),
                ],
              );
            },
            theme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: const Color(0xFF0A0A0F),
              textTheme:
                  GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme),
            ),
            home: const SplashScreen(),
            navigatorObservers: [
              RouteTransitionObserver(),
              velourRouteObserver,
            ],
            routes: {
              '/main': (_) => const MainMenuView(),
              '/game': (_) => const GameScreen(),
              '/leaderboard': (_) => const LeaderboardView(),
              '/shop': (_) => const ShopView(),
              '/settings': (_) => const SettingsView(),
              '/stats': (_) => const StatsView(),
            },
          );
        },
      ),
    );
  }
}
