import FirebaseAppCheck
import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

  #if DEBUG
    private enum VelourAppCheckNativeLogOnce {
      static var didPrintToken = false
    }
  #endif

  /// UIScene : `window` / `FlutterViewController` peuvent ne pas être prêts au tout premier
  /// tick ; on réessaie après `super` et à l’activation de la scène.
  private func registerVelourAppCheckDebugChannel() {
    #if DEBUG
      guard let fvc = window?.rootViewController as? FlutterViewController else {
        return
      }
      (UIApplication.shared.delegate as? AppDelegate)?
        .setupAppCheckDebugChannel(fvc.binaryMessenger)
      if !VelourAppCheckNativeLogOnce.didPrintToken {
        VelourAppCheckNativeLogOnce.didPrintToken = true
        let t = AppCheckDebugProvider.currentDebugToken()
        NSLog("[Firebase/AppCheck] Debug token: %@", t)
        Swift.print("[Firebase/AppCheck] Debug token: \(t)")
      }
    #endif
  }

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    #if DEBUG
      registerVelourAppCheckDebugChannel()
      DispatchQueue.main.async { [weak self] in
        self?.registerVelourAppCheckDebugChannel()
      }
    #endif
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    #if DEBUG
      registerVelourAppCheckDebugChannel()
    #endif
  }
}
