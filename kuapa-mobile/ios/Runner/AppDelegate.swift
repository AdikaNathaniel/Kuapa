import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Replace AIzaSyDZbvGHPXLZ4zLBV7gjxf9fkfTTrUcKtj8 with your key from https://console.cloud.google.com/
    // Enable: Maps SDK for iOS, Geocoding API
    GMSServices.provideAPIKey("AIzaSyDZbvGHPXLZ4zLBV7gjxf9fkfTTrUcKtj8")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
