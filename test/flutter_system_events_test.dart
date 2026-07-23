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

  test('parses network event maps', () {
    for (final type in NetworkType.values) {
      final event = SystemEvent.fromMap({
        'type': 'network',
        'online': type != NetworkType.none,
        'networkType': type.name,
      });

      expect(event, isA<NetworkEvent>());
      expect((event as NetworkEvent).online, type != NetworkType.none);
      expect(event.networkType, type);
    }
  });

  test('parses memory event maps', () {
    final cases = {
      MemoryState.warning: 0,
      MemoryState.low: 0,
      MemoryState.trim: 10,
    };

    for (final entry in cases.entries) {
      final event = SystemEvent.fromMap({
        'type': 'memory',
        'state': entry.key.name,
        'level': entry.value,
      });

      expect(event, isA<MemoryEvent>());
      expect((event as MemoryEvent).state, entry.key);
      expect(event.level, entry.value);
    }
  });

  test('parses battery event maps', () {
    final cases = {
      BatteryState.charging: true,
      BatteryState.discharging: false,
      BatteryState.full: true,
      BatteryState.unknown: false,
    };

    for (final entry in cases.entries) {
      final event = SystemEvent.fromMap({
        'type': 'battery',
        'level': entry.key == BatteryState.unknown ? -1 : 80,
        'charging': entry.value,
        'state': entry.key.name,
      });

      expect(event, isA<BatteryEvent>());
      expect(
        (event as BatteryEvent).level,
        entry.key == BatteryState.unknown ? -1 : 80,
      );
      expect(event.charging, entry.value);
      expect(event.state, entry.key);
    }
  });

  test('returns unknown event for unsupported event type', () {
    final event = SystemEvent.fromMap({'type': 'unknown'});

    expect(event, isA<UnknownSystemEvent>());
    expect((event as UnknownSystemEvent).rawType, 'unknown');
  });

  test('returns unknown event for invalid enum values', () {
    final event = SystemEvent.fromMap({
      'type': 'memory',
      'state': 'invalid',
      'level': 0,
    });

    expect(event, isA<UnknownSystemEvent>());
    expect((event as UnknownSystemEvent).rawType, 'memory');
  });

  test('returns unknown event for missing fields', () {
    final event = SystemEvent.fromMap({'type': 'keyboard'});

    expect(event, isA<UnknownSystemEvent>());
    expect((event as UnknownSystemEvent).rawType, 'keyboard');
  });

  test('returns unknown event for wrong field types', () {
    final event = SystemEvent.fromMap({
      'type': 'battery',
      'level': '80',
      'charging': true,
      'state': 'charging',
    });

    expect(event, isA<UnknownSystemEvent>());
    expect((event as UnknownSystemEvent).rawType, 'battery');
  });

  test('returns unknown event for non-map payloads', () {
    final event = SystemEvent.fromPayload('invalid');

    expect(event, isA<UnknownSystemEvent>());
    expect((event as UnknownSystemEvent).rawPayload, 'invalid');
  });
}
