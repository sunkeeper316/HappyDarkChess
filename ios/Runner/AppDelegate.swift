import Flutter
import UIKit

class PortraitFlutterViewController: FlutterViewController {
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return .portrait
  }

  @available(iOS 26.0, *)
  override var prefersInterfaceOrientationLocked: Bool {
    return true
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
