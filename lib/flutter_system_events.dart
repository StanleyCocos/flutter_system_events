import 'flutter_system_events_platform_interface.dart';

export 'flutter_system_events_platform_interface.dart'
    show
        KeyboardEvent,
        LifecycleEvent,
        LifecycleState,
        NetworkEvent,
        NetworkType,
        SystemEvent;

final class SystemEvents {
  const SystemEvents._();

  static Future<void> initialize() {
    return FlutterSystemEventsPlatform.instance.initialize();
  }

  static Future<void> dispose() {
    return FlutterSystemEventsPlatform.instance.dispose();
  }

  static Stream<SystemEvent> get events =>
      FlutterSystemEventsPlatform.instance.events;
}
