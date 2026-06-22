import Flutter
import UIKit
import MessageUI

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, MFMessageComposeViewControllerDelegate {
  private var flutterResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "com.adyapan.sms") {
      let smsChannel = FlutterMethodChannel(name: "com.adyapan.sms",
                                                binaryMessenger: registrar.messenger())
      smsChannel.setMethodCallHandler({
        [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        guard call.method == "sendSms" else {
          result(FlutterMethodNotImplemented)
          return
        }
        self?.flutterResult = result
        self?.sendSms(call: call)
      })
    }
  }

  private func sendSms(call: FlutterMethodCall) {
    guard let args = call.arguments as? [String: Any],
          let phone = args["phone"] as? String,
          let msg = args["msg"] as? String else {
      flutterResult?(FlutterError(code: "INVALID_ARGS", message: "Phone or msg missing", details: nil))
      return
    }

    if MFMessageComposeViewController.canSendText() {
      let controller = MFMessageComposeViewController()
      controller.body = msg
      controller.recipients = [phone]
      controller.messageComposeDelegate = self
      
      let rootVC = self.window?.rootViewController
      rootVC?.present(controller, animated: true, completion: nil)
    } else {
      flutterResult?(FlutterError(code: "SMS_NOT_AVAILABLE", message: "SMS Composer not available", details: nil))
    }
  }

  func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
    controller.dismiss(animated: true, completion: nil)
    switch result {
    case .cancelled:
      flutterResult?(FlutterError(code: "SMS_CANCELLED", message: "SMS sending was cancelled", details: nil))
    case .failed:
      flutterResult?(FlutterError(code: "SMS_FAILED", message: "SMS sending failed", details: nil))
    case .sent:
      flutterResult?("SMS Sent")
    @unknown default:
      flutterResult?(FlutterError(code: "UNKNOWN", message: "Unknown error", details: nil))
    }
  }
}
