import 'flutter_system_events_platform_interface.dart';

export 'flutter_system_events_platform_interface.dart'
    show KeyboardEvent, LifecycleEvent, LifecycleState, SystemEvent;

final class SystemEvents {
  const SystemEvents._();

  static Future<void> initialize() {
    return FlutterSystemEventsPlatform.instance.initialize();
  }

  static Stream<SystemEvent> get events =>
      FlutterSystemEventsPlatform.instance.events;
}
