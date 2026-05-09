import FirebaseAppCheck
import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    #if DEBUG
      // Après `super`, la fenêtre / le FlutterViewController sont prêts sur la prochaine rotation
      // de la run loop — ce qui aligne aussi l’enregistrement avec `main()` Dart (`setDebugToken`).
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        if let fvc = self.window?.rootViewController as? FlutterViewController {
          (UIApplication.shared.delegate as? AppDelegate)?
            .setupAppCheckDebugChannel(fvc.binaryMessenger)
        }
        let t = AppCheckDebugProvider.currentDebugToken()
        NSLog("[Firebase/AppCheck] Debug token: %@", t)
        Swift.print("[Firebase/AppCheck] Debug token: \(t)")
      }
    #endif
  }
}
