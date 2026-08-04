import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_system_events/flutter_system_events.dart';
import 'package:flutter_system_events/flutter_system_events_method_channel.dart';
import 'package:flutter_system_events/flutter_system_events_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterSystemEventsPlatform
    with MockPlatformInterfaceMixin
    implements FlutterSystemEventsPlatform {
  SystemEventsConfig? initializedConfig;
  final initializedConfigs = <SystemEventsConfig>[];
  var disposed = false;
  NetworkEvent? networkEvent;
  BatteryEvent? batteryEvent;
  OrientationEvent? orientationEvent;
  ScreenEvent? screenBrightnessEvent;

  @override
  Future<void> initialize({
    SystemEventsConfig config = const SystemEventsConfig.defaults(),
  }) async {
    initializedConfig = config;
    initializedConfigs.add(config);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  @override
  Future<NetworkEvent> currentNetwork() async {
    return networkEvent ??
        const NetworkEvent(online: true, networkType: NetworkType.wifi);
  }

  @override
  Future<BatteryEvent> currentBattery() async {
    return batteryEvent ??
        const BatteryEvent(
          level: 80,
          charging: true,
          state: BatteryState.charging,
        );
  }

  @override
  Future<OrientationEvent> currentOrientation() async {
    return orientationEvent ??
        const OrientationEvent(orientation: ScreenOrientation.portraitUp);
  }

  @override
  Future<ScreenEvent> currentScreenBrightness() async {
    return screenBrightnessEvent ??
        const ScreenEvent(change: ScreenChange.brightness, brightness: 0.5);
  }

  @override
  Stream<SystemEvent> get events => Stream<SystemEvent>.value(
    const KeyboardEvent(visible: true, height: 300),
  );
}

class IncompleteFlutterSystemEventsPlatform
    extends FlutterSystemEventsPlatform {}

class MixedEventFlutterSystemEventsPlatform
    with MockPlatformInterfaceMixin
    implements FlutterSystemEventsPlatform {
  @override
  Future<void> initialize({
    SystemEventsConfig config = const SystemEventsConfig.defaults(),
  }) async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<NetworkEvent> currentNetwork() async {
    return const NetworkEvent(online: true, networkType: NetworkType.wifi);
  }

  @override
  Future<BatteryEvent> currentBattery() async {
    return const BatteryEvent(
      level: 80,
      charging: true,
      state: BatteryState.charging,
    );
  }

  @override
  Future<OrientationEvent> currentOrientation() async {
    return const OrientationEvent(orientation: ScreenOrientation.portraitUp);
  }

  @override
  Future<ScreenEvent> currentScreenBrightness() async {
    return const ScreenEvent(change: ScreenChange.brightness, brightness: 0.5);
  }

  @override
  Stream<SystemEvent> get events => Stream<SystemEvent>.fromIterable([
    const NetworkEvent(online: true, networkType: NetworkType.wifi),
    const KeyboardEvent(visible: true, height: 300),
    const LifecycleEvent(state: LifecycleState.resumed),
    const MemoryEvent(state: MemoryState.warning, level: 0),
    const BatteryEvent(level: 80, charging: true, state: BatteryState.charging),
    const OrientationEvent(orientation: ScreenOrientation.portraitUp),
    const TimeEvent(reason: TimeChangeReason.timeChanged),
    const ScreenEvent(change: ScreenChange.brightness, brightness: 0.5),
  ]);
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
    expect(SystemEvents.config, same(config));
  });

  test(
    'updateConfig replaces current config and delegates to platform',
    () async {
      final platform = MockFlutterSystemEventsPlatform();
      FlutterSystemEventsPlatform.instance = platform;
      const config = SystemEventsConfig(battery: BatteryConfig());

      await SystemEvents.updateConfig(config);

      expect(platform.initializedConfig, same(config));
      expect(SystemEvents.config, same(config));
    },
  );

  test('enable adds one event group to current config', () async {
    final platform = MockFlutterSystemEventsPlatform();
    FlutterSystemEventsPlatform.instance = platform;

    await SystemEvents.updateConfig(const SystemEventsConfig());
    await SystemEvents.enable(SystemEventType.keyboard);

    expect(SystemEvents.config.keyboard, isNotNull);
    expect(SystemEvents.config.lifecycle, isNull);
    expect(platform.initializedConfigs.last.toMap(), {
      'keyboard': true,
      'lifecycle': false,
      'network': false,
      'memory': false,
      'battery': false,
      'orientation': false,
      'time': false,
      'screen': false,
    });
  });

  test('disable removes one event group from current config', () async {
    final platform = MockFlutterSystemEventsPlatform();
    FlutterSystemEventsPlatform.instance = platform;

    await SystemEvents.updateConfig(const SystemEventsConfig.all());
    await SystemEvents.disable(SystemEventType.battery);

    expect(SystemEvents.config.battery, isNull);
    expect(SystemEvents.config.keyboard, isNotNull);
    expect(platform.initializedConfigs.last.toMap(), {
      'keyboard': true,
      'lifecycle': true,
      'network': true,
      'memory': true,
      'battery': false,
      'orientation': true,
      'time': true,
      'screen': true,
    });
  });

  test('dispose delegates to platform instance', () async {
    final platform = MockFlutterSystemEventsPlatform();
    FlutterSystemEventsPlatform.instance = platform;

    await SystemEvents.dispose();

    expect(platform.disposed, isTrue);
  });

  test('currentNetwork delegates to platform instance', () async {
    final platform = MockFlutterSystemEventsPlatform()
      ..networkEvent = const NetworkEvent(
        online: false,
        networkType: NetworkType.none,
      );
    FlutterSystemEventsPlatform.instance = platform;

    final event = await SystemEvents.currentNetwork();

    expect(event.online, isFalse);
    expect(event.networkType, NetworkType.none);
  });

  test('currentBattery delegates to platform instance', () async {
    final platform = MockFlutterSystemEventsPlatform()
      ..batteryEvent = const BatteryEvent(
        level: 42,
        charging: false,
        state: BatteryState.discharging,
      );
    FlutterSystemEventsPlatform.instance = platform;

    final event = await SystemEvents.currentBattery();

    expect(event.level, 42);
    expect(event.charging, isFalse);
    expect(event.state, BatteryState.discharging);
  });

  test('currentOrientation delegates to platform instance', () async {
    final platform = MockFlutterSystemEventsPlatform()
      ..orientationEvent = const OrientationEvent(
        orientation: ScreenOrientation.landscapeLeft,
      );
    FlutterSystemEventsPlatform.instance = platform;

    final event = await SystemEvents.currentOrientation();

    expect(event.orientation, ScreenOrientation.landscapeLeft);
  });

  test('currentScreenBrightness delegates to platform instance', () async {
    final platform = MockFlutterSystemEventsPlatform()
      ..screenBrightnessEvent = const ScreenEvent(
        change: ScreenChange.brightness,
        brightness: 0.42,
      );
    FlutterSystemEventsPlatform.instance = platform;

    final event = await SystemEvents.currentScreenBrightness();

    expect(event.change, ScreenChange.brightness);
    expect(event.brightness, 0.42);
  });

  test('events exposes keyboard events', () async {
    FlutterSystemEventsPlatform.instance = MockFlutterSystemEventsPlatform();

    expect(await SystemEvents.events.single, isA<KeyboardEvent>());
  });

  test('typed event streams only emit matching events', () async {
    FlutterSystemEventsPlatform.instance =
        MixedEventFlutterSystemEventsPlatform();

    expect(await SystemEvents.keyboard.single, isA<KeyboardEvent>());
    expect(await SystemEvents.lifecycle.single, isA<LifecycleEvent>());
    expect(await SystemEvents.network.single, isA<NetworkEvent>());
    expect(await SystemEvents.memory.single, isA<MemoryEvent>());
    expect(await SystemEvents.battery.single, isA<BatteryEvent>());
    expect(await SystemEvents.orientation.single, isA<OrientationEvent>());
    expect(await SystemEvents.time.single, isA<TimeEvent>());
    expect(await SystemEvents.screen.single, isA<ScreenEvent>());
  });

  test('base platform methods throw when not implemented', () {
    final platform = IncompleteFlutterSystemEventsPlatform();

    expect(platform.initialize, throwsUnimplementedError);
    expect(platform.dispose, throwsUnimplementedError);
    expect(platform.currentNetwork, throwsUnimplementedError);
    expect(platform.currentBattery, throwsUnimplementedError);
    expect(platform.currentOrientation, throwsUnimplementedError);
    expect(platform.currentScreenBrightness, throwsUnimplementedError);
    expect(() => platform.events, throwsUnimplementedError);
  });

  test('default config enables legacy events', () {
    expect(const SystemEventsConfig.defaults().toMap(), {
      'keyboard': true,
      'lifecycle': true,
      'network': true,
      'memory': true,
      'battery': false,
      'orientation': true,
      'time': true,
      'screen': true,
    });
  });

  test('all config enables every event', () {
    expect(const SystemEventsConfig.all().toMap(), {
      'keyboard': true,
      'lifecycle': true,
      'network': true,
      'memory': true,
      'battery': true,
      'orientation': true,
      'time': true,
      'screen': true,
    });
  });

  test('custom config only enables configured events', () {
    expect(
      const SystemEventsConfig(
        keyboard: KeyboardConfig(),
        battery: BatteryConfig(),
        screen: ScreenConfig(),
      ).toMap(),
      {
        'keyboard': true,
        'lifecycle': false,
        'network': false,
        'memory': false,
        'battery': true,
        'orientation': false,
        'time': false,
        'screen': true,
      },
    );
  });

  test('parses screen event maps', () {
    for (final change in ScreenChange.values) {
      final event = SystemEvent.fromMap({
        'type': 'screen',
        'change': change.name,
        if (change == ScreenChange.brightness) 'brightness': 0.5,
      });

      expect(event, isA<ScreenEvent>());
      expect((event as ScreenEvent).change, change);
      expect(event.brightness, change == ScreenChange.brightness ? 0.5 : null);
    }
  });

  test('ignores brightness field for non-brightness screen events', () {
    final event = SystemEvent.fromMap({
      'type': 'screen',
      'change': 'off',
      'brightness': 0.5,
    });

    expect(event, isA<ScreenEvent>());
    expect((event as ScreenEvent).change, ScreenChange.off);
    expect(event.brightness, isNull);
  });

  test('parses time event maps', () {
    for (final reason in TimeChangeReason.values) {
      final event = SystemEvent.fromMap({
        'type': 'time',
        'reason': reason.name,
      });

      expect(event, isA<TimeEvent>());
      expect((event as TimeEvent).reason, reason);
    }
  });

  test('parses orientation event maps', () {
    for (final orientation in ScreenOrientation.values) {
      final event = SystemEvent.fromMap({
        'type': 'orientation',
        'orientation': orientation.name,
      });

      expect(event, isA<OrientationEvent>());
      expect((event as OrientationEvent).orientation, orientation);
    }
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

  test('returns unknown event for invalid screen event payloads', () {
    final missingBrightness = SystemEvent.fromMap({
      'type': 'screen',
      'change': 'brightness',
    });
    final invalidChange = SystemEvent.fromMap({
      'type': 'screen',
      'change': 'invalid',
    });

    expect(missingBrightness, isA<UnknownSystemEvent>());
    expect((missingBrightness as UnknownSystemEvent).rawType, 'screen');
    expect(invalidChange, isA<UnknownSystemEvent>());
    expect((invalidChange as UnknownSystemEvent).rawType, 'screen');
  });

  test('returns unknown event for non-map payloads', () {
    final event = SystemEvent.fromPayload('invalid');

    expect(event, isA<UnknownSystemEvent>());
    expect((event as UnknownSystemEvent).rawPayload, 'invalid');
  });
}
