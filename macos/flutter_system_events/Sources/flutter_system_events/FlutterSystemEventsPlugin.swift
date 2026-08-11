import Cocoa
import FlutterMacOS
import IOKit.ps
import Network

public class FlutterSystemEventsPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var events: FlutterEventSink?
  private var observers: [NSObjectProtocol] = []
  private var powerSourceRunLoopSource: CFRunLoopSource?
  private var pathMonitor: NWPathMonitor?
  private var currentNetworkMonitor: NWPathMonitor?
  private var config = EventConfig.legacy
  private var initialized = false
  private var lastBatterySnapshot: BatterySnapshot?
  private var lastNetworkSnapshot: NetworkSnapshot?
  private var lastOrientationSnapshot: OrientationSnapshot?

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
    case "currentNetwork":
      currentNetwork(result)
    case "currentBattery":
      result(batteryEvent())
    case "currentOrientation":
      result(orientationEvent())
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
    stopAll()
    if config.keyboard { startKeyboard() }
    if config.lifecycle { startLifecycle() }
    if config.network { startNetwork() }
    if config.time { startTime() }
    if config.battery { startBattery() }
    if config.orientation { startOrientation() }
  }

  private func stopAll() {
    observers.forEach(NotificationCenter.default.removeObserver)
    observers.removeAll()
    stopBattery()
    pathMonitor?.cancel()
    pathMonitor = nil
    lastNetworkSnapshot = nil
    lastOrientationSnapshot = nil
    currentNetworkMonitor?.cancel()
    currentNetworkMonitor = nil
  }

  private func startKeyboard() {}

  private func startLifecycle() {
    observeLifecycle(NSApplication.didBecomeActiveNotification, state: "resumed")
    observeLifecycle(NSApplication.willResignActiveNotification, state: "inactive")
    observeLifecycle(NSApplication.didResignActiveNotification, state: "paused")
    observeLifecycle(NSApplication.willTerminateNotification, state: "detached")
  }

  private func observeLifecycle(_ name: Notification.Name, state: String) {
    observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
      self?.events?(["type": "lifecycle", "state": state])
    })
  }

  private func startNetwork() {
    let monitor = NWPathMonitor()
    lastNetworkSnapshot = NetworkSnapshot(event: networkEvent(from: monitor.currentPath))
    monitor.pathUpdateHandler = { [weak self] path in
      DispatchQueue.main.async {
        self?.emitNetworkIfChanged(from: path)
      }
    }
    pathMonitor = monitor
    monitor.start(queue: DispatchQueue.global(qos: .utility))
  }

  private func emitNetworkIfChanged(from path: NWPath) {
    let event = networkEvent(from: path)
    let snapshot = NetworkSnapshot(event: event)
    guard let lastNetworkSnapshot else {
      self.lastNetworkSnapshot = snapshot
      return
    }
    guard snapshot != lastNetworkSnapshot else { return }
    self.lastNetworkSnapshot = snapshot
    events?(event)
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

  private func startTime() {
    observeTime(NSNotification.Name.NSSystemClockDidChange, reason: "timeChanged")
    observeTime(NSNotification.Name.NSSystemTimeZoneDidChange, reason: "timezoneChanged")
    observeTime(NSNotification.Name.NSCalendarDayChanged, reason: "dateChanged")
  }

  private func observeTime(_ name: Notification.Name, reason: String) {
    observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
      self?.events?(["type": "time", "reason": reason])
    })
  }

  private func startBattery() {
    lastBatterySnapshot = BatterySnapshot(event: batteryEvent())
    let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
    guard let source = IOPSNotificationCreateRunLoopSource({ context in
      guard let context else { return }
      let plugin = Unmanaged<FlutterSystemEventsPlugin>.fromOpaque(context).takeUnretainedValue()
      DispatchQueue.main.async {
        plugin.emitBattery()
      }
    }, context)?.takeRetainedValue() else { return }

    powerSourceRunLoopSource = source
    CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
  }

  private func emitBattery() {
    let event = batteryEvent()
    let snapshot = BatterySnapshot(event: event)
    guard let lastBatterySnapshot else {
      self.lastBatterySnapshot = snapshot
      return
    }
    guard snapshot != lastBatterySnapshot else { return }
    self.lastBatterySnapshot = snapshot
    events?(event)
  }

  private func stopBattery() {
    if let powerSourceRunLoopSource {
      CFRunLoopRemoveSource(CFRunLoopGetMain(), powerSourceRunLoopSource, .defaultMode)
      self.powerSourceRunLoopSource = nil
    }
    lastBatterySnapshot = nil
  }

  private func startOrientation() {
    lastOrientationSnapshot = OrientationSnapshot(event: orientationEvent())
    observers.append(NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
      self?.emitOrientation()
    })
  }

  private func emitOrientation() {
    let event = orientationEvent()
    let snapshot = OrientationSnapshot(event: event)
    guard let lastOrientationSnapshot else {
      self.lastOrientationSnapshot = snapshot
      return
    }
    guard snapshot != lastOrientationSnapshot else { return }
    self.lastOrientationSnapshot = snapshot
    events?(event)
  }

  private struct EventConfig {
    let keyboard: Bool
    let lifecycle: Bool
    let network: Bool
    let time: Bool
    let battery: Bool
    let orientation: Bool

    static let legacy = EventConfig(keyboard: true, lifecycle: true, network: true, time: true, battery: false, orientation: true)

    static func from(_ arguments: Any?) -> EventConfig {
      guard let map = arguments as? [String: Any] else { return legacy }
      return EventConfig(
        keyboard: map["keyboard"] as? Bool == true,
        lifecycle: map["lifecycle"] as? Bool == true,
        network: map["network"] as? Bool == true,
        time: map["time"] as? Bool == true,
        battery: map["battery"] as? Bool == true,
        orientation: map["orientation"] as? Bool == true
      )
    }
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

struct NetworkSnapshot: Equatable {
  let online: Bool
  let networkType: String

  init(event: [String: Any]) {
    online = event["online"] as! Bool
    networkType = event["networkType"] as! String
  }
}

struct BatterySnapshot: Equatable {
  let level: Int
  let charging: Bool
  let state: String

  init(event: [String: Any]) {
    level = event["level"] as! Int
    charging = event["charging"] as! Bool
    state = event["state"] as! String
  }
}

struct OrientationSnapshot: Equatable {
  let orientation: String

  init(event: [String: Any]) {
    orientation = event["orientation"] as! String
  }
}

func batteryEvent() -> [String: Any] {
  guard
    let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
    let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef],
    let source = sources.first,
    let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any]
  else {
    return ["type": "battery", "level": -1, "charging": false, "state": "unknown"]
  }

  let current = description[kIOPSCurrentCapacityKey] as? Int
  let max = description[kIOPSMaxCapacityKey] as? Int
  let level = current.flatMap { current in
    max.flatMap { max in max > 0 ? Int(Double(current) / Double(max) * 100) : nil }
  } ?? -1
  let isCharging = description[kIOPSIsChargingKey] as? Bool == true
  let sourceState = description[kIOPSPowerSourceStateKey] as? String

  let state: String
  if isCharging {
    state = "charging"
  } else if level >= 100 && sourceState == kIOPSACPowerValue {
    state = "full"
  } else if sourceState == kIOPSBatteryPowerValue {
    state = "discharging"
  } else if sourceState == kIOPSACPowerValue {
    state = "full"
  } else {
    state = "unknown"
  }

  return ["type": "battery", "level": level, "charging": state == "charging" || state == "full", "state": state]
}

func orientationEvent() -> [String: Any] {
  guard let frame = NSScreen.main?.frame else {
    return ["type": "orientation", "orientation": "unknown"]
  }
  let orientation = frame.height > frame.width ? "portraitUp" : "landscapeLeft"
  return ["type": "orientation", "orientation": orientation]
}
