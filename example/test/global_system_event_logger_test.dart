import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_system_events/flutter_system_events_platform_interface.dart';
import 'package:flutter_system_events_example/global_system_event_logger.dart';

class FakeSystemEventsPlatform extends FlutterSystemEventsPlatform {
  final controller = StreamController<SystemEvent>.broadcast(sync: true);

  @override
  Future<void> initialize({
    SystemEventsConfig config = const SystemEventsConfig.defaults(),
  }) async {}

  @override
  Future<void> dispose() async {}

  @override
  Stream<SystemEvent> get events => controller.stream;
}

void main() {
  final initialPlatform = FlutterSystemEventsPlatform.instance;

  tearDown(() {
    FlutterSystemEventsPlatform.instance = initialPlatform;
  });

  test('logs raw and typed event callbacks with different prefixes', () async {
    final platform = FakeSystemEventsPlatform();
    final logs = <String>[];
    FlutterSystemEventsPlatform.instance = platform;

    final logger = GlobalSystemEventLogger(log: logs.add);
    logger.start();

    platform.controller.add(const KeyboardEvent(visible: true, height: 300));
    platform.controller.add(const ScreenshotEvent());
    await Future<void>.delayed(Duration.zero);

    expect(
      logs,
      containsAll([
        '[SystemEvents.events] KeyboardEvent',
        '[SystemEvents.keyboard] KeyboardEvent',
        '[SystemEvents.events] ScreenshotEvent',
        '[SystemEvents.screenshot] ScreenshotEvent',
      ]),
    );

    await logger.dispose();
    await platform.controller.close();
  });
}
