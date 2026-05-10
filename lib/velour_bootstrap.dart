import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'services/audio_handler.dart';
import 'services/remote_config_service.dart';
import 'services/velour_analytics.dart';
import 'services/velour_audio_platform.dart';
import 'services/velour_observability.dart';
import 'utils/velour_release_links.dart';
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
void velourScheduleIosAppCheckDebugTokenEchoOnce({
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

/// `flutter test` / `integration_test` installent un [WidgetsBinding] dont le nom
/// de runtime contient `Test` (ex. [IntegrationTestWidgetsFlutterBinding]). Ne pas
/// remplacer [FlutterError.onError] ni [PlatformDispatcher.instance.onError] dans ce
/// cas : cela casse l’état interne du binding (`_pendingExceptionDetails`, etc.).
bool velourAppRunningUnderFlutterTestBinding() {
  final String n = WidgetsBinding.instance.runtimeType.toString();
  return n.contains('Test') && n.endsWith('Binding');
}

/// Tout le démarrage avant [runApp] (Firebase, App Check, Crashlytics, polices, etc.).
///
/// [WidgetsFlutterBinding.ensureInitialized] doit déjà avoir été appelé.
Future<void> velourRunAppStartup() async {
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
  await VelourAnalytics.configureAfterFirebaseInit();
  await velourActivateAppCheck();
  unawaited(VelourRemoteConfig.instance.init());

  // Crashlytics : actif hors debug (release + profile, ex. TestFlight interne).
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    !kDebugMode,
  );
  VelourObservability.tagReleaseSessionForCrashlyticsJ1();

  // Erreurs synchrones / asynchrones : handlers globaux réservés aux runs « app ».
  // Voir [velourAppRunningUnderFlutterTestBinding] (integration_test / widget tests).
  if (!velourAppRunningUnderFlutterTestBinding()) {
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
  }

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

  velourScheduleIosAppCheckDebugTokenEchoOnce(
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
}
