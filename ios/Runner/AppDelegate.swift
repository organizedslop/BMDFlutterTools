import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

   // Set up the "icmMethodChannel" to handle getBuildTime
    let controller = window?.rootViewController as! FlutterViewController
    let buildTimeChannel = FlutterMethodChannel(
      name: "icmMethodChannel",
      binaryMessenger: controller.binaryMessenger
    )
    buildTimeChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "getBuildTime" {
        if let buildTime = Bundle.main.object(forInfoDictionaryKey: "BUILD_TIME") as? String {
          result(buildTime)
        } else {
          result(FlutterError(
            code: "UNAVAILABLE",
            message: "BUILD_TIME not set in Info.plist",
            details: nil
          ))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
