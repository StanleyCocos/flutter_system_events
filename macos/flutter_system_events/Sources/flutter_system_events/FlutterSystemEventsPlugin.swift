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
    if config.keyboard { emitKeyboardHidden() }
    if config.lifecycle { startLifecycle() }
    if config.network { startNetwork() }
    if config.time { startTime() }
    if config.battery { startBattery() }
  }

  private func stopAll() {
    observers.forEach(NotificationCenter.default.removeObserver)
    observers.removeAll()
    stopBattery()
    pathMonitor?.cancel()
    pathMonitor = nil
    currentNetworkMonitor?.cancel()
    currentNetworkMonitor = nil
  }

  private func emitKeyboardHidden() {
    events?(["type": "keyboard", "visible": false, "height": 0])
  }

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
    emitBattery()
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
    events?(batteryEvent())
  }

  private func stopBattery() {
    if let powerSourceRunLoopSource {
      CFRunLoopRemoveSource(CFRunLoopGetMain(), powerSourceRunLoopSource, .defaultMode)
      self.powerSourceRunLoopSource = nil
    }
  }

  private struct EventConfig {
    let keyboard: Bool
    let lifecycle: Bool
    let network: Bool
    let time: Bool
    let battery: Bool

    static let legacy = EventConfig(keyboard: true, lifecycle: true, network: true, time: true, battery: false)

    static func from(_ arguments: Any?) -> EventConfig {
      guard let map = arguments as? [String: Any] else { return legacy }
      return EventConfig(
        keyboard: map["keyboard"] as? Bool == true,
        lifecycle: map["lifecycle"] as? Bool == true,
        network: map["network"] as? Bool == true,
        time: map["time"] as? Bool == true,
        battery: map["battery"] as? Bool == true
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
