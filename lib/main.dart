import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:velour_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/app_settings.dart';
import 'services/velour_audio_platform.dart';
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
import 'utils/route_transition_observer.dart';
import 'utils/velour_route_observer.dart';

/// Active App Check après [Firebase.initializeApp].
///
/// - **Web** : debug **et profile** (`!kReleaseMode`) → [WebDebugProvider] ; release →
///   `ReCaptchaEnterpriseProvider` si `VELOUR_APP_CHECK_WEB_SITE_KEY` est passé en
///   `--dart-define`, sinon noop (évite un crash sans clé console).
/// - **Mobile / desktop Apple** : debug **et profile** (`!kReleaseMode`) → providers
///   debug ; **release** uniquement → Play Integrity / App Attest avec repli Device Check.
///   (Sans cela, `flutter run --profile` utiliserait App Attest « prod » et échouerait
///   souvent en local tant que la console App Check n’est pas complète.)
/// - **Windows** : uniquement debug provider ; jeton optionnel
///   `VELOUR_APP_CHECK_WINDOWS_DEBUG_TOKEN` ou variable d’environnement SDK.
Future<void> velourActivateAppCheck() async {
  try {
    if (kIsWeb) {
      const webSiteKey = String.fromEnvironment(
        'VELOUR_APP_CHECK_WEB_SITE_KEY',
        defaultValue: '',
      );
      if (!kReleaseMode) {
        await FirebaseAppCheck.instance.activate(
          providerWeb: WebDebugProvider(),
        );
      } else if (webSiteKey.isNotEmpty) {
        await FirebaseAppCheck.instance.activate(
          providerWeb: ReCaptchaEnterpriseProvider(webSiteKey),
        );
      }
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.windows) {
      const winToken = String.fromEnvironment(
        'VELOUR_APP_CHECK_WINDOWS_DEBUG_TOKEN',
        defaultValue: '',
      );
      await FirebaseAppCheck.instance.activate(
        providerWindows: WindowsDebugProvider(
          debugToken: winToken.isNotEmpty ? winToken : null,
        ),
      );
      return;
    }

    final bool useDebugAppCheckProviders = !kReleaseMode;
    await FirebaseAppCheck.instance.activate(
      providerAndroid: useDebugAppCheckProviders
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: useDebugAppCheckProviders
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  } catch (e, st) {
    debugPrint('Firebase App Check activate failed: $e');
    if (!kDebugMode) {
      await FirebaseCrashlytics.instance.recordError(e, st, fatal: false);
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Indispensable
  // iOS / Android : AVAudioSession + contexte audioplayers (respectSilence: false).
  await configureVelourAudioPipeline(activateSession: true);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await velourActivateAppCheck();

  // Crashlytics : actif hors debug (release + profile, ex. TestFlight interne).
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    !kDebugMode,
  );

  // Erreurs synchrones du framework Flutter (build/layout, etc.).
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  // Erreurs asynchrones non capturées par le framework (Dart 3+).
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Web stability: prefer long-polling over unstable websocket/QUIC paths.
  // These flags are no-ops on mobile/desktop, but help Chrome on flaky networks.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Évite swap de police / micro-lag sur la première frame Material (thème Montserrat).
  await GoogleFonts.pendingFonts(<dynamic>[
    GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme),
  ]);

  runApp(const VelourApp());
}

class VelourApp extends StatelessWidget {
  const VelourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameState()),
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
                    textTheme: GoogleFonts.montserratTextTheme(
                      ThemeData.dark().textTheme,
                    ),
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
