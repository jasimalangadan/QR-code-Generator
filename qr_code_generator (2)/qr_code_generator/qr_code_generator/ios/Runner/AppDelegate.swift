import Flutter
import UIKit
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.example.qr_code_generator/save_image",
                                      binaryMessenger: controller.binaryMessenger)
    channel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "saveImageToGallery" {
        guard let args = call.arguments as? [String: Any],
              let flutterData = args["bytes"] as? FlutterStandardTypedData else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Bytes argument is null", details: nil))
          return
        }
        
        let data = flutterData.data
        if let image = UIImage(data: data) {
          UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
          // Keep reference to result to call it when saving completes
          self.pendingResult = result
        } else {
          result(FlutterError(code: "INVALID_IMAGE", message: "Failed to decode UIImage", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private var pendingResult: FlutterResult?

  @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
    if let error = error {
      pendingResult?(FlutterError(code: "SAVE_FAILED", message: error.localizedDescription, details: nil))
    } else {
      pendingResult?(true)
    }
    pendingResult = nil
  }
}
