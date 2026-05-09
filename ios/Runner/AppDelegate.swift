import AVFoundation
import FirebaseAppCheck
import FirebaseCore
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Toujours enregistrer le canal (évite `MissingPluginException` côté Dart).
  /// Logique debug : voir `SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG` sur la cible Runner.
  func setupAppCheckDebugChannel(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "velour/app_check", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      #if DEBUG
        if call.method == "getDebugToken" {
          guard let app = FirebaseApp.app(),
                let debugProvider = AppCheckDebugProvider(app: app)
          else {
            result(nil)
            return
          }
          result(debugProvider.localDebugToken())
          return
        }
        if call.method == "setDebugToken" {
          guard let args = call.arguments as? [String: Any],
                let token = args["token"] as? String,
                !token.isEmpty
          else {
            result(nil)
            return
          }
          UserDefaults.standard.set(token, forKey: "FIRAAppCheckDebugToken")
          setenv("FIRAAppCheckDebugToken", token, 1)
          AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
          result(nil)
          return
        }
        result(FlutterMethodNotImplemented)
      #else
        result(FlutterMethodNotImplemented)
      #endif
    }
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
    try? session.setActive(true)
    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let controller = window?.rootViewController as? FlutterViewController {
      setupAppCheckDebugChannel(controller.binaryMessenger)
    }
    return ok
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    setupAppCheckDebugChannel(engineBridge.applicationRegistrar.messenger())
  }
}
