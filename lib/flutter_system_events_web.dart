import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'flutter_system_events_platform_interface.dart';

/// A web implementation of the FlutterSystemEventsPlatform of the FlutterSystemEvents plugin.
class FlutterSystemEventsWeb extends FlutterSystemEventsPlatform {
  /// Constructs a FlutterSystemEventsWeb
  FlutterSystemEventsWeb();

  static void registerWith(Registrar registrar) {
    FlutterSystemEventsPlatform.instance = FlutterSystemEventsWeb();
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  Stream<SystemEvent> get events => const Stream.empty();
}
