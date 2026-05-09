import AVFoundation
import Flutter
import UIKit
import FirebaseAppCheck


@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Enregistré depuis la scène active (`SceneDelegate`) : avec `UIApplicationSceneManifest`,
  /// `AppDelegate.window` est souvent nil, donc pas de `FlutterViewController` au lancement.
  func setupAppCheckDebugChannel(_ messenger: FlutterBinaryMessenger) {
    #if DEBUG
      let channel = FlutterMethodChannel(name: "velour/app_check", binaryMessenger: messenger)
      channel.setMethodCallHandler { call, result in
        if call.method == "getDebugToken" {
          // Returns (and generates if needed) the current debug token.
          // This token must be registered in Firebase Console -> App Check -> Debug tokens.
          let t = AppCheckDebugProvider.currentDebugToken()
          result(t)
          return
        }

        guard call.method == "setDebugToken" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard let args = call.arguments as? [String: Any],
              let token = args["token"] as? String,
              !token.isEmpty
        else {
          result(nil)
          return
        }
        // The iOS App Check debug provider reads this key to reuse a stable token.
        UserDefaults.standard.set(token, forKey: "FIRAAppCheckDebugToken")
        // Some SDK paths look at the process environment variable instead.
        setenv("FIRAAppCheckDebugToken", token, 1)
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        result(nil)
      }
    #endif
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
    #if DEBUG
      // UIScene + storyboard : `SceneDelegate.window` / `FlutterViewController` peuvent être nil
      // avant la fin du branchement — le messenger de l’engine implicite est le bon endroit
      // (voir FlutterEngine `performImplicitEngineCallback` / `FlutterApplicationRegistrar`).
      setupAppCheckDebugChannel(engineBridge.applicationRegistrar.messenger())
      let t = AppCheckDebugProvider.currentDebugToken()
      NSLog("[Firebase/AppCheck] Debug token: %@", t)
    #endif
  }
}
