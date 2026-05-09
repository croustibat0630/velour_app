import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velour_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/app_settings.dart';
import 'services/audio_handler.dart';
import 'services/remote_config_service.dart';
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
import 'widgets/ui/lux_cloud_notice_global_layer.dart';
import 'utils/route_transition_observer.dart';
import 'utils/session_trace_navigator_observer.dart';
import 'utils/velour_release_links.dart';
import 'utils/velour_route_observer.dart';
import 'utils/velour_session_trace.dart';

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

/// Le canal est enregistré sur `applicationRegistrar.messenger()` dès
/// `didInitializeImplicitFlutterEngine`. On réaffiche le jeton via Dart pour
/// `flutter run` (les logs natifs ne remontent pas toujours).
void _scheduleIosAppCheckDebugTokenEchoOnce({
  required bool injectedViaDartDefine,
}) {
  if (injectedViaDartDefine ||
      kIsWeb ||
      kReleaseMode ||
      defaultTargetPlatform != TargetPlatform.iOS) {
    return;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(() async {
      const MethodChannel ch = MethodChannel('velour/app_check');
      Object? lastErr;
      for (int i = 0; i < 25; i++) {
        try {
          final String? t = await ch.invokeMethod<String>('getDebugToken');
          if (t != null && t.isNotEmpty) {
            debugPrint(
              'Firebase App Check debug token (add in Console → App Check → '
              'Manage debug tokens): $t',
            );
            return;
          }
          lastErr = 'empty_token';
        } catch (e) {
          lastErr = e;
        }
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      debugPrint('Firebase App Check debug token bridge: $lastErr');
    }());
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Indispensable
  // iOS simulator App Check: `flutter run` doesn't reliably propagate process
  // env vars to the iOS app. Use a native bridge so we can set the debug token
  // before Firebase config, without committing secrets.
  const String debugAppCheckToken = String.fromEnvironment(
    'VELOUR_APP_CHECK_DEBUG_TOKEN',
    defaultValue: '',
  );
  if (!kIsWeb &&
      !kReleaseMode &&
      debugAppCheckToken.isNotEmpty &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    try {
      const MethodChannel ch = MethodChannel('velour/app_check');
      Object? lastErr;
      for (int i = 0; i < 8; i++) {
        try {
          await ch.invokeMethod<void>('setDebugToken', <String, Object?>{
            'token': debugAppCheckToken,
          });
          lastErr = null;
          break;
        } catch (e) {
          lastErr = e;
          await Future<void>.delayed(const Duration(milliseconds: 80));
        }
      }
      if (lastErr != null) {
        debugPrint('App Check debug token bridge failed: $lastErr');
      }
    } catch (e) {
      debugPrint('App Check debug token bridge failed: $e');
    }
  }

  // Réduit le timeout interne « preparation » d’audioplayers (30s par défaut) pour
  // éviter des TimeoutException fantômes remontées à Crashlytics après nos awaits.
  AudioHandler.installAudioplayersTimeoutGuardsEarly();
  // iOS / Android : AVAudioSession + contexte audioplayers (respectSilence: false).
  await configureVelourAudioPipeline(activateSession: true);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await velourActivateAppCheck();
  unawaited(VelourRemoteConfig.instance.init());

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
  // Roboto Mono : GameOverOverlay / chiffres — sans preload la 1re frame fin de partie peut
  // saturer le thread UI sur simulateur ou appareils modestes.
  await GoogleFonts.pendingFonts(<dynamic>[
    GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme),
    GoogleFonts.robotoMonoTextTheme(ThemeData.dark().textTheme),
  ]);

  _scheduleIosAppCheckDebugTokenEchoOnce(
    injectedViaDartDefine: debugAppCheckToken.isNotEmpty,
  );
  VelourReleaseLinks.debugWarnIfPrivacyPolicyMisconfiguredForRelease();
  if (VelourSessionTrace.enabled) {
    // ignore: avoid_print
    print(
      '[VelourTrace] VELOUR_SESSION_TRACE actif — navigation + gameState.notify '
      '+ velourDebug() (sortie console uniquement).',
    );
  }
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
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            child ?? const SizedBox.shrink(),
                            const WelcomeGiftGlobalLayer(),
                            const LuxCloudNoticeGlobalLayer(),
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
