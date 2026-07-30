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
        ScreenOrientation,
        SystemEvent,
        SystemEventsConfig,
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
}
