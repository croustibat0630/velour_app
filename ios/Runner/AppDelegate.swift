import AVFoundation
import Flutter
import UIKit
import FirebaseAppCheck


@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
    try? session.setActive(true)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    #if DEBUG
      // App Check debug token helper (iOS simulator/dev). We set the token and
      // provider factory early so Firebase can use it for Functions/Firestore.
      if let controller = window?.rootViewController as? FlutterViewController {
        let channel = FlutterMethodChannel(
          name: "velour/app_check",
          binaryMessenger: controller.binaryMessenger
        )
        channel.setMethodCallHandler { call, result in
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
          AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
          result(nil)
        }
      }
    #endif
  }
}
