import Flutter
import Network
import UIKit

public class FlutterSystemEventsPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var events: FlutterEventSink?
  private var observers: [NSObjectProtocol] = []
  private var pathMonitor: NWPathMonitor?
  private var config = EventConfig.legacy
  private var previousBatteryMonitoring: Bool?

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
      config = EventConfig.from(call.arguments)
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
    if config.keyboard { startKeyboard() }
    if config.lifecycle { startLifecycle() }
    if config.network { startNetwork() }
    if config.memory { startMemory() }
    if config.battery { startBattery() }
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
    stopBattery()
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

  private func startBattery() {
    previousBatteryMonitoring = UIDevice.current.isBatteryMonitoringEnabled
    UIDevice.current.isBatteryMonitoringEnabled = true
    observers.append(NotificationCenter.default.addObserver(forName: UIDevice.batteryLevelDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
      self?.emitBattery()
    })
    observers.append(NotificationCenter.default.addObserver(forName: UIDevice.batteryStateDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
      self?.emitBattery()
    })
    emitBattery()
  }

  private func emitBattery() {
    let device = UIDevice.current
    let state: String
    switch device.batteryState {
    case .charging:
      state = "charging"
    case .full:
      state = "full"
    case .unplugged:
      state = "discharging"
    case .unknown:
      state = "unknown"
    @unknown default:
      state = "unknown"
    }
    let level = device.batteryLevel >= 0 ? Int(device.batteryLevel * 100) : -1
    events?(["type": "battery", "level": level, "charging": state == "charging" || state == "full", "state": state])
  }

  private func stopBattery() {
    if let previousBatteryMonitoring {
      UIDevice.current.isBatteryMonitoringEnabled = previousBatteryMonitoring
      self.previousBatteryMonitoring = nil
    }
  }

  private struct EventConfig {
    let keyboard: Bool
    let lifecycle: Bool
    let network: Bool
    let memory: Bool
    let battery: Bool

    static let legacy = EventConfig(keyboard: true, lifecycle: true, network: true, memory: true, battery: false)

    static func from(_ arguments: Any?) -> EventConfig {
      guard let map = arguments as? [String: Any] else { return legacy }
      return EventConfig(
        keyboard: map["keyboard"] as? Bool == true,
        lifecycle: map["lifecycle"] as? Bool == true,
        network: map["network"] as? Bool == true,
        memory: map["memory"] as? Bool == true,
        battery: map["battery"] as? Bool == true
      )
    }
  }
}
