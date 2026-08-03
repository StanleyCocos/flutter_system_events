/// Listens to selected system-level events from Flutter apps.
library;

import 'flutter_system_events_platform_interface.dart';

export 'flutter_system_events_platform_interface.dart'
    show
        BatteryConfig,
        BatteryEvent,
        BatteryState,
        KeyboardEvent,
        KeyboardConfig,
        LifecycleConfig,
        LifecycleEvent,
        LifecycleState,
        MemoryConfig,
        MemoryEvent,
        MemoryState,
        NetworkConfig,
        NetworkEvent,
        NetworkType,
        OrientationConfig,
        OrientationEvent,
        ScreenChange,
        ScreenConfig,
        ScreenEvent,
        ScreenOrientation,
        SystemEvent,
        SystemEventsConfig,
        TimeChangeReason,
        TimeConfig,
        TimeEvent,
        UnknownSystemEvent;

/// Entry point for configuring and receiving system events.
final class SystemEvents {
  const SystemEvents._();

  /// Starts native listeners for the enabled event groups in [config].
  static Future<void> initialize({
    SystemEventsConfig config = const SystemEventsConfig.defaults(),
  }) {
    return FlutterSystemEventsPlatform.instance.initialize(config: config);
  }

  /// Stops native listeners and releases platform resources.
  static Future<void> dispose() {
    return FlutterSystemEventsPlatform.instance.dispose();
  }

  /// Broadcast stream of decoded system events.
  static Stream<SystemEvent> get events =>
      FlutterSystemEventsPlatform.instance.events;

  /// Keyboard visibility events.
  static Stream<KeyboardEvent> get keyboard =>
      events.where((event) => event is KeyboardEvent).cast<KeyboardEvent>();

  /// App lifecycle events.
  static Stream<LifecycleEvent> get lifecycle =>
      events.where((event) => event is LifecycleEvent).cast<LifecycleEvent>();

  /// Network connectivity events.
  static Stream<NetworkEvent> get network =>
      events.where((event) => event is NetworkEvent).cast<NetworkEvent>();

  /// Memory pressure events.
  static Stream<MemoryEvent> get memory =>
      events.where((event) => event is MemoryEvent).cast<MemoryEvent>();

  /// Battery state events.
  static Stream<BatteryEvent> get battery =>
      events.where((event) => event is BatteryEvent).cast<BatteryEvent>();

  /// Screen orientation events.
  static Stream<OrientationEvent> get orientation => events
      .where((event) => event is OrientationEvent)
      .cast<OrientationEvent>();

  /// System time change events.
  static Stream<TimeEvent> get time =>
      events.where((event) => event is TimeEvent).cast<TimeEvent>();

  /// Screen state and brightness events.
  static Stream<ScreenEvent> get screen =>
      events.where((event) => event is ScreenEvent).cast<ScreenEvent>();
}
