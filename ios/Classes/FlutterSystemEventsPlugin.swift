import Flutter
import UIKit

public class FlutterSystemEventsPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var events: FlutterEventSink?
  private var observers: [NSObjectProtocol] = []

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_system_events", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: "flutter_system_events/events", binaryMessenger: registrar.messenger())
    let instance = FlutterSystemEventsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      startKeyboard()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.events = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    events = nil
    stopKeyboard()
    return nil
  }

  private func startKeyboard() {
    stopKeyboard()
    observers.append(NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] notification in
      let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
      self?.events?(["type": "keyboard", "visible": true, "height": frame?.height ?? 0])
    })
    observers.append(NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
      self?.events?(["type": "keyboard", "visible": false, "height": 0])
    })
  }

  private func stopKeyboard() {
    observers.forEach(NotificationCenter.default.removeObserver)
    observers.removeAll()
  }
}
