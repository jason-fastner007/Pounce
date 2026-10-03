#if os(iOS)
import Flutter
import UIKit
#else
import FlutterMacOS
import AppKit
#endif
import AuthenticationServices

/// Login via the system dialog (ASWebAuthenticationSession, shares Safari cookies).
public class NativeAuthPlugin: NSObject, FlutterPlugin, FlutterStreamHandler,
  ASWebAuthenticationPresentationContextProviding {
  private var session: ASWebAuthenticationSession?
  private var sink: FlutterEventSink?

  public static func register(with registrar: FlutterPluginRegistrar) {
    #if os(iOS)
    let messenger = registrar.messenger()
    #else
    let messenger = registrar.messenger
    #endif
    let instance = NativeAuthPlugin()
    registrar.addMethodCallDelegate(
      instance, channel: FlutterMethodChannel(name: "kittyfork/auth", binaryMessenger: messenger))
    FlutterEventChannel(name: "kittyfork/auth/links", binaryMessenger: messenger)
      .setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "authenticate",
          let args = call.arguments as? [String: Any],
          let s = args["url"] as? String, let url = URL(string: s) else {
      return result(FlutterMethodNotImplemented)
    }
    let scheme = args["scheme"] as? String ?? "sc"
    session = ASWebAuthenticationSession(url: url, callbackURLScheme: scheme) { [weak self] callback, error in
      DispatchQueue.main.async {
        if let callback { self?.sink?(callback.absoluteString) }
        if let error = error as? ASWebAuthenticationSessionError, error.code == .canceledLogin {
          result(FlutterError(code: "cancelled", message: nil, details: nil))
        } else {
          result(callback?.absoluteString)
        }
        self?.session = nil
      }
    }
    session?.presentationContextProvider = self
    session?.start()
  }

  public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    #if os(iOS)
    return UIApplication.shared.connectedScenes
      .compactMap { ($0 as? UIWindowScene)?.keyWindow }.first ?? ASPresentationAnchor()
    #else
    return NSApplication.shared.keyWindow ?? ASPresentationAnchor()
    #endif
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }
}
