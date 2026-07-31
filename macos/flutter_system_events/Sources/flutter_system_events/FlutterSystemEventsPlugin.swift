import Cocoa
import FlutterMacOS

public class FlutterSystemEventsPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var events: FlutterEventSink?
  private var config = EventConfig.legacy
  private var initialized = false

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_system_events", binaryMessenger: registrar.messenger)
    let eventChannel = FlutterEventChannel(name: "flutter_system_events/events", binaryMessenger: registrar.messenger)
    let instance = FlutterSystemEventsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      config = EventConfig.from(call.arguments)
      initialized = true
      startAll()
      result(nil)
    case "dispose":
      initialized = false
      stopAll()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.events = events
    if initialized { startAll() }
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    events = nil
    return nil
  }

  private func startAll() {
    if config.keyboard { emitKeyboardHidden() }
  }

  private func stopAll() {}

  private func emitKeyboardHidden() {
    events?(["type": "keyboard", "visible": false, "height": 0])
  }

  private struct EventConfig {
    let keyboard: Bool

    static let legacy = EventConfig(keyboard: true)

    static func from(_ arguments: Any?) -> EventConfig {
      guard let map = arguments as? [String: Any] else { return legacy }
      return EventConfig(keyboard: map["keyboard"] as? Bool == true)
    }
  }
}
