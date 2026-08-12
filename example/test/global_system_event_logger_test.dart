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

    final logger = GlobalSystemEventLogger(
      log: logs.add,
      now: () => DateTime(2026, 8, 12, 13, 4, 5, 6),
    );
    logger.start();

    platform.controller.add(const KeyboardEvent(visible: true, height: 300));
    platform.controller.add(const ScreenshotEvent());
    platform.controller.add(const ThermalEvent(state: ThermalState.serious));
    await Future<void>.delayed(Duration.zero);

    expect(
      logs,
      containsAll([
        '[SystemEvents.events] 2026-08-12 13-04-05-006\n'
            '{\n'
            "  'event': 'KeyboardEvent',\n"
            "  'visible': true,\n"
            "  'height': 300.0,\n"
            '}',
        '[SystemEvents.keyboard] 2026-08-12 13-04-05-006\n'
            '{\n'
            "  'event': 'KeyboardEvent',\n"
            "  'visible': true,\n"
            "  'height': 300.0,\n"
            '}',
        '[SystemEvents.events] 2026-08-12 13-04-05-006\n'
            '{\n'
            "  'event': 'ScreenshotEvent',\n"
            '}',
        '[SystemEvents.screenshot] 2026-08-12 13-04-05-006\n'
            '{\n'
            "  'event': 'ScreenshotEvent',\n"
            '}',
        '[SystemEvents.events] 2026-08-12 13-04-05-006\n'
            '{\n'
            "  'event': 'ThermalEvent',\n"
            "  'state': 'serious',\n"
            '}',
        '[SystemEvents.thermal] 2026-08-12 13-04-05-006\n'
            '{\n'
            "  'event': 'ThermalEvent',\n"
            "  'state': 'serious',\n"
            '}',
      ]),
    );

    await logger.dispose();
    await platform.controller.close();
  });
}
