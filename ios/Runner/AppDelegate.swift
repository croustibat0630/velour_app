import AVFoundation
import Flutter
import UIKit
import FirebaseAppCheck


@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private func setupAppCheckDebugChannel(_ messenger: FlutterBinaryMessenger) {
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

    #if DEBUG
      // Make it easy to register the simulator in Firebase Console:
      // Build -> App Check -> iOS app -> Manage debug tokens -> Add token.
      // This token is stable across launches (stored by the SDK).
      let t = AppCheckDebugProvider.currentDebugToken()
      NSLog("[Firebase/AppCheck] Debug token: %@", t)
    #endif
    return ok
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    #if DEBUG
      // App Check debug token helper (iOS simulator/dev). We set the token and
      // provider factory early so Firebase can use it for Functions/Firestore.
      let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "VelourAppCheckBridge")
      setupAppCheckDebugChannel(registrar.messenger())
    #endif
  }
}
