import 'package:flutter/material.dart';
import 'package:velour_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/game_state.dart';
import 'screens/game_screen.dart';
import 'screens/leaderboard_view.dart';
import 'screens/main_menu_view.dart';
import 'screens/splash_screen.dart';
import 'screens/settings_view.dart';
import 'screens/stats_view.dart';
import 'screens/shop_view.dart';
import 'theme/theme_engine.dart';
import 'widgets/lux_iap_binding.dart';
import 'widgets/ui/welcome_gift_global_layer.dart';
import 'widgets/ui/lux_cloud_notice_global_layer.dart';
import 'utils/route_transition_observer.dart';
import 'utils/session_trace_navigator_observer.dart';
import 'utils/velour_route_observer.dart';
import 'services/app_settings.dart';
import 'services/velour_app_engagement_tracker.dart';

/// Racine Material + providers (hors bootstrap Firebase / polices).
class VelourApp extends StatelessWidget {
  const VelourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameState()),
        ChangeNotifierProvider(create: (_) => ThemeEngine()),
      ],
      // Perf : ne pas reconstruire MaterialApp sur chaque notify GameState (économie LUX,
      // matchs, etc.). GameScreen et les autres vues s’abonnent elles-mêmes via watch/select.
      child: Consumer<ThemeEngine>(
        builder: (BuildContext context, ThemeEngine te, _) {
          return Selector<GameState, ({Color primary, Color secondary})>(
            selector: (_, GameState gs) => (
              primary: gs.currentSkin.primaryColor,
              secondary: gs.currentSkin.secondaryColor,
            ),
            builder: (BuildContext context, skin, _) {
              final Color p = skin.primary;
              final Color s = skin.secondary;
              if (te.skinPrimaryOverride != p ||
                  te.skinSecondaryOverride != s) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  te.applySkinColors(primary: p, secondary: s);
                });
              }
              return ListenableBuilder(
                listenable: AppSettings.instance.localePreference,
                builder: (BuildContext context, Widget? _) {
                  return LuxIapBinding(
                    child: MaterialApp(
                      locale: AppSettings.materialLocaleFor(
                        AppSettings.instance.localePreference.value,
                      ),
                      onGenerateTitle: (BuildContext context) =>
                          AppLocalizations.of(context)?.appTitle ?? 'Velour',
                      localizationsDelegates:
                          AppLocalizations.localizationsDelegates,
                      supportedLocales: AppLocalizations.supportedLocales,
                      debugShowCheckedModeBanner: false,
                      builder: (context, child) {
                        return VelourAppEngagementBinder(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              child ?? const SizedBox.shrink(),
                              const WelcomeGiftGlobalLayer(),
                              const LuxCloudNoticeGlobalLayer(),
                            ],
                          ),
                        );
                      },
                      theme: ThemeData.dark().copyWith(
                        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
                        textTheme: GoogleFonts.montserratTextTheme(
                          ThemeData.dark().textTheme,
                        ),
                      ),
                      home: const SplashScreen(),
                      navigatorObservers: <NavigatorObserver>[
                        VelourAnalyticsNavigatorObserver(),
                        RouteTransitionObserver(),
                        SessionTraceNavigatorObserver(),
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
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
