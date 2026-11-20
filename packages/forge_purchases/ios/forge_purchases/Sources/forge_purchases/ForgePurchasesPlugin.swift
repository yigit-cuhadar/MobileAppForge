import AdServices
import Flutter

/// Answers `attributionToken` on the `forge_purchases/ad_services` channel
/// with AdServices' token for this install, or nil where there is none.
public class ForgePurchasesPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "forge_purchases/ad_services",
      binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(ForgePurchasesPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "attributionToken" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard #available(iOS 14.3, *) else {
      result(nil)
      return
    }
    // attributionToken() is synchronous and may wait on the system.
    DispatchQueue.global(qos: .utility).async {
      let token = try? AAAttribution.attributionToken()
      DispatchQueue.main.async { result(token) }
    }
  }
}
