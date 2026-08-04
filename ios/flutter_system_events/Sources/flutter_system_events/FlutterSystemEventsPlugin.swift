import Flutter
import Network
import UIKit

public class FlutterSystemEventsPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var events: FlutterEventSink?
  private var observers: [NSObjectProtocol] = []
  private var pathMonitor: NWPathMonitor?
  private var currentNetworkMonitor: NWPathMonitor?
  private var config = EventConfig.legacy
  private var previousBatteryMonitoring: Bool?
  private var previousOrientationNotifications: Bool?
  private var lastOrientation: String?

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
    case "currentNetwork":
      currentNetwork(result)
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
    return nil
  }

  private func startAll() {
    stopAll()
    if config.keyboard { startKeyboard() }
    if config.lifecycle { startLifecycle() }
    if config.network { startNetwork() }
    if config.memory { startMemory() }
    if config.battery { startBattery() }
    if config.orientation { startOrientation() }
    if config.time { startTime() }
    if config.screen { startScreen() }
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
      print("[FlutterSystemEvents] memory callback: state=warning level=0")
      self?.events?(["type": "memory", "state": "warning", "level": 0])
    })
  }

  private func stopAll() {
    observers.forEach(NotificationCenter.default.removeObserver)
    observers.removeAll()
    pathMonitor?.cancel()
    pathMonitor = nil
    currentNetworkMonitor?.cancel()
    currentNetworkMonitor = nil
    stopBattery()
    stopOrientation()
  }

  private func startNetwork() {
    let monitor = NWPathMonitor()
    monitor.pathUpdateHandler = { [weak self] path in
      DispatchQueue.main.async {
        self?.events?(networkEvent(from: path))
      }
    }
    pathMonitor = monitor
    monitor.start(queue: DispatchQueue.global(qos: .utility))
  }

  private func currentNetwork(_ result: @escaping FlutterResult) {
    currentNetworkMonitor?.cancel()
    let monitor = NWPathMonitor()
    currentNetworkMonitor = monitor
    var completed = false
    monitor.pathUpdateHandler = { [weak self] path in
      DispatchQueue.main.async {
        guard !completed else { return }
        completed = true
        result(networkEvent(from: path))
        monitor.cancel()
        if self?.currentNetworkMonitor === monitor {
          self?.currentNetworkMonitor = nil
        }
      }
    }
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

  private func startOrientation() {
    previousOrientationNotifications = UIDevice.current.isGeneratingDeviceOrientationNotifications
    UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    observers.append(NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
      self?.emitOrientation()
    })
    emitOrientation()
  }

  private func emitOrientation() {
    let orientation = orientationName(from: UIDevice.current.orientation)
    if orientation == lastOrientation { return }
    lastOrientation = orientation
    events?(["type": "orientation", "orientation": orientation])
  }

  private func stopOrientation() {
    if previousOrientationNotifications == false {
      UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
    previousOrientationNotifications = nil
    lastOrientation = nil
  }

  private func startTime() {
    observeTime(UIApplication.significantTimeChangeNotification, reason: "timeChanged")
    observeTime(NSNotification.Name.NSSystemTimeZoneDidChange, reason: "timezoneChanged")
    observeTime(NSNotification.Name.NSCalendarDayChanged, reason: "dateChanged")
  }

  private func observeTime(_ name: Notification.Name, reason: String) {
    observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
      self?.events?(["type": "time", "reason": reason])
    })
  }

  private func startScreen() {
    observers.append(NotificationCenter.default.addObserver(forName: UIScreen.brightnessDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
      self?.events?(["type": "screen", "change": "brightness", "brightness": UIScreen.main.brightness])
    })
    observers.append(NotificationCenter.default.addObserver(forName: UIApplication.protectedDataDidBecomeAvailableNotification, object: nil, queue: .main) { [weak self] _ in
      self?.events?(["type": "screen", "change": "unlocked"])
    })
  }

  private struct EventConfig {
    let keyboard: Bool
    let lifecycle: Bool
    let network: Bool
    let memory: Bool
    let battery: Bool
    let orientation: Bool
    let time: Bool
    let screen: Bool

    static let legacy = EventConfig(keyboard: true, lifecycle: true, network: true, memory: true, battery: false, orientation: true, time: true, screen: true)

    static func from(_ arguments: Any?) -> EventConfig {
      guard let map = arguments as? [String: Any] else { return legacy }
      return EventConfig(
        keyboard: map["keyboard"] as? Bool == true,
        lifecycle: map["lifecycle"] as? Bool == true,
        network: map["network"] as? Bool == true,
        memory: map["memory"] as? Bool == true,
        battery: map["battery"] as? Bool == true,
        orientation: map["orientation"] as? Bool == true,
        time: map["time"] as? Bool == true,
        screen: map["screen"] as? Bool == true
      )
    }
  }
}

func orientationName(from orientation: UIDeviceOrientation) -> String {
  switch orientation {
  case .portrait:
    return "portraitUp"
  case .portraitUpsideDown:
    return "portraitDown"
  case .landscapeLeft:
    return "landscapeLeft"
  case .landscapeRight:
    return "landscapeRight"
  default:
    return "unknown"
  }
}

func networkEvent(from path: NWPath) -> [String: Any] {
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
  return ["type": "network", "online": path.status == .satisfied, "networkType": networkType]
}
