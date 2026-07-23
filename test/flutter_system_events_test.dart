import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_system_events/flutter_system_events.dart';
import 'package:flutter_system_events/flutter_system_events_method_channel.dart';
import 'package:flutter_system_events/flutter_system_events_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterSystemEventsPlatform
    with MockPlatformInterfaceMixin
    implements FlutterSystemEventsPlatform {
  SystemEventsConfig? initializedConfig;
  var disposed = false;

  @override
  Future<void> initialize({
    SystemEventsConfig config = const SystemEventsConfig.defaults(),
  }) async {
    initializedConfig = config;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  @override
  Stream<SystemEvent> get events => Stream<SystemEvent>.value(
    const KeyboardEvent(visible: true, height: 300),
  );
}

void main() {
  final initialPlatform = FlutterSystemEventsPlatform.instance;

  tearDown(() {
    FlutterSystemEventsPlatform.instance = initialPlatform;
  });

  test('$MethodChannelFlutterSystemEvents is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterSystemEvents>());
  });

  test('initialize delegates to platform instance', () async {
    final platform = MockFlutterSystemEventsPlatform();
    FlutterSystemEventsPlatform.instance = platform;
    const config = SystemEventsConfig(memory: MemoryConfig());

    await SystemEvents.initialize(config: config);

    expect(platform.initializedConfig, same(config));
  });

  test('dispose delegates to platform instance', () async {
    final platform = MockFlutterSystemEventsPlatform();
    FlutterSystemEventsPlatform.instance = platform;

    await SystemEvents.dispose();

    expect(platform.disposed, isTrue);
  });

  test('events exposes keyboard events', () async {
    FlutterSystemEventsPlatform.instance = MockFlutterSystemEventsPlatform();

    expect(await SystemEvents.events.single, isA<KeyboardEvent>());
  });

  test('default config enables legacy events', () {
    expect(const SystemEventsConfig.defaults().toMap(), {
      'keyboard': true,
      'lifecycle': true,
      'network': true,
      'memory': true,
      'battery': false,
    });
  });

  test('all config enables every event', () {
    expect(const SystemEventsConfig.all().toMap(), {
      'keyboard': true,
      'lifecycle': true,
      'network': true,
      'memory': true,
      'battery': true,
    });
  });

  test('custom config only enables configured events', () {
    expect(
      const SystemEventsConfig(
        keyboard: KeyboardConfig(),
        battery: BatteryConfig(),
      ).toMap(),
      {
        'keyboard': true,
        'lifecycle': false,
        'network': false,
        'memory': false,
        'battery': true,
      },
    );
  });

  test('parses keyboard event maps', () {
    final visibleEvent = SystemEvent.fromMap({
      'type': 'keyboard',
      'visible': true,
      'height': 240,
    });
    final hiddenEvent = SystemEvent.fromMap({
      'type': 'keyboard',
      'visible': false,
      'height': 0,
    });

    expect(visibleEvent, isA<KeyboardEvent>());
    expect((visibleEvent as KeyboardEvent).visible, isTrue);
    expect(visibleEvent.height, 240);
    expect(hiddenEvent, isA<KeyboardEvent>());
    expect((hiddenEvent as KeyboardEvent).visible, isFalse);
    expect(hiddenEvent.height, 0);
  });

  test('parses lifecycle event maps', () {
    for (final state in LifecycleState.values) {
      final event = SystemEvent.fromMap({
        'type': 'lifecycle',
        'state': state.name,
      });

      expect(event, isA<LifecycleEvent>());
      expect((event as LifecycleEvent).state, state);
    }
  });

  test('parses network event map', () {
    final event = SystemEvent.fromMap({
      'type': 'network',
      'online': true,
      'networkType': 'wifi',
    });

    expect(event, isA<NetworkEvent>());
    expect((event as NetworkEvent).networkType, NetworkType.wifi);
  });

  test('parses memory event map', () {
    final event = SystemEvent.fromMap({
      'type': 'memory',
      'state': 'warning',
      'level': 0,
    });

    expect(event, isA<MemoryEvent>());
    expect((event as MemoryEvent).state, MemoryState.warning);
  });

  test('parses battery event map', () {
    final event = SystemEvent.fromMap({
      'type': 'battery',
      'level': 80,
      'charging': true,
      'state': 'charging',
    });

    expect(event, isA<BatteryEvent>());
    expect((event as BatteryEvent).level, 80);
    expect(event.state, BatteryState.charging);
  });
}
