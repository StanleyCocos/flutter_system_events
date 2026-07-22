import Flutter
import Network
import UIKit

public class FlutterSystemEventsPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var events: FlutterEventSink?
  private var observers: [NSObjectProtocol] = []
  private var pathMonitor: NWPathMonitor?

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
      startAll()
      result(nil)
    case "dispose":
      stopAll()
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
    stopAll()
    return nil
  }

  private func startAll() {
    stopAll()
    startKeyboard()
    startLifecycle()
    startNetwork()
    startMemory()
  }

  private func startKeyboard() {
    observers.append(NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] notification in
      let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
      self?.events?(["type": "keyboard", "visible": true, "height": frame?.height ?? 0])
    })
    observers.append(NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
      self?.events?(["type": "keyboard", "visible": false, "height": 0])
    })
  }

  private func startLifecycle() {
    observeLifecycle(UIApplication.didBecomeActiveNotification, state: "resumed")
    observeLifecycle(UIApplication.willResignActiveNotification, state: "inactive")
    observeLifecycle(UIApplication.didEnterBackgroundNotification, state: "paused")
    observeLifecycle(UIApplication.willTerminateNotification, state: "detached")
  }

  private func observeLifecycle(_ name: Notification.Name, state: String) {
    observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
      self?.events?(["type": "lifecycle", "state": state])
    })
  }

  private func startMemory() {
    observers.append(NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: .main) { [weak self] _ in
      self?.events?(["type": "memory", "state": "warning", "level": 0])
    })
  }

  private func stopAll() {
    observers.forEach(NotificationCenter.default.removeObserver)
    observers.removeAll()
    pathMonitor?.cancel()
    pathMonitor = nil
  }

  private func startNetwork() {
    let monitor = NWPathMonitor()
    monitor.pathUpdateHandler = { [weak self] path in
      let networkType: String
      if path.status != .satisfied {
        networkType = "none"
      } else if path.usesInterfaceType(.wifi) {
        networkType = "wifi"
      } else if path.usesInterfaceType(.cellular) {
        networkType = "cellular"
      } else if path.usesInterfaceType(.wiredEthernet) {
        networkType = "ethernet"
      } else {
        networkType = "other"
      }
      DispatchQueue.main.async {
        self?.events?(["type": "network", "online": path.status == .satisfied, "networkType": networkType])
      }
    }
    pathMonitor = monitor
    monitor.start(queue: DispatchQueue.global(qos: .utility))
  }
}
