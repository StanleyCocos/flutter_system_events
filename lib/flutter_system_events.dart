import 'flutter_system_events_platform_interface.dart';

export 'flutter_system_events_platform_interface.dart'
    show
        BatteryConfig,
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
        SystemEvent,
        SystemEventsConfig;

final class SystemEvents {
  const SystemEvents._();

  static Future<void> initialize({
    SystemEventsConfig config = const SystemEventsConfig.defaults(),
  }) {
    return FlutterSystemEventsPlatform.instance.initialize(config: config);
  }

  static Future<void> dispose() {
    return FlutterSystemEventsPlatform.instance.dispose();
  }

  static Stream<SystemEvent> get events =>
      FlutterSystemEventsPlatform.instance.events;
}
