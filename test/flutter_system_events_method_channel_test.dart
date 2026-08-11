import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_system_events/flutter_system_events.dart';
import 'package:flutter_system_events/flutter_system_events_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelFlutterSystemEvents();
  const channel = MethodChannel('flutter_system_events');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('initialize calls native initialize with default config', () async {
    String? method;
    Object? arguments;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          method = methodCall.method;
          arguments = methodCall.arguments;
          return null;
        });

    await platform.initialize();

    expect(method, 'initialize');
    expect(arguments, {
      'keyboard': true,
      'lifecycle': true,
      'network': true,
      'memory': true,
      'battery': false,
      'orientation': true,
      'time': true,
      'screen': true,
      'screenshot': false,
      'thermal': false,
    });
  });

  test('initialize calls native initialize with custom config', () async {
    Object? arguments;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          arguments = methodCall.arguments;
          return null;
        });

    await platform.initialize(
      config: const SystemEventsConfig(battery: BatteryConfig()),
    );

    expect(arguments, {
      'keyboard': false,
      'lifecycle': false,
      'network': false,
      'memory': false,
      'battery': true,
      'orientation': false,
      'time': false,
      'screen': false,
      'screenshot': false,
      'thermal': false,
    });
  });

  test('dispose calls native dispose', () async {
    String? method;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          method = methodCall.method;
          return null;
        });

    await platform.dispose();

    expect(method, 'dispose');
  });

  test(
    'currentNetwork calls native currentNetwork and decodes event',
    () async {
      String? method;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            method = methodCall.method;
            return {'type': 'network', 'online': true, 'networkType': 'wifi'};
          });

      final event = await platform.currentNetwork();

      expect(method, 'currentNetwork');
      expect(event.online, isTrue);
      expect(event.networkType, NetworkType.wifi);
    },
  );

  test(
    'currentBattery calls native currentBattery and decodes event',
    () async {
      String? method;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            method = methodCall.method;
            return {
              'type': 'battery',
              'level': 42,
              'charging': false,
              'state': 'discharging',
            };
          });

      final event = await platform.currentBattery();

      expect(method, 'currentBattery');
      expect(event.level, 42);
      expect(event.charging, isFalse);
      expect(event.state, BatteryState.discharging);
    },
  );

  test(
    'currentOrientation calls native currentOrientation and decodes event',
    () async {
      String? method;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            method = methodCall.method;
            return {'type': 'orientation', 'orientation': 'landscapeLeft'};
          });

      final event = await platform.currentOrientation();

      expect(method, 'currentOrientation');
      expect(event.orientation, ScreenOrientation.landscapeLeft);
    },
  );

  test(
    'currentScreenBrightness calls native currentScreenBrightness and decodes event',
    () async {
      String? method;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            method = methodCall.method;
            return {
              'type': 'screen',
              'change': 'brightness',
              'brightness': 0.42,
            };
          });

      final event = await platform.currentScreenBrightness();

      expect(method, 'currentScreenBrightness');
      expect(event.change, ScreenChange.brightness);
      expect(event.brightness, 0.42);
    },
  );

  test(
    'currentThermal calls native currentThermal and decodes event',
    () async {
      String? method;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            method = methodCall.method;
            return {'type': 'thermal', 'state': 'serious'};
          });

      final event = await platform.currentThermal();

      expect(method, 'currentThermal');
      expect(event.state, ThermalState.serious);
    },
  );

  test('currentThermal converts unavailable errors to UnsupportedError', () {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          throw PlatformException(
            code: 'unavailable',
            message: 'Thermal state unavailable.',
          );
        });

    expect(platform.currentThermal(), throwsA(isA<UnsupportedError>()));
  });

  test('currentThermal converts missing plugin errors to UnsupportedError', () {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          throw MissingPluginException('currentThermal missing');
        });

    expect(platform.currentThermal(), throwsA(isA<UnsupportedError>()));
  });

  test('events converts native maps to system events', () async {
    final platform = MethodChannelFlutterSystemEvents();
    const eventChannel = EventChannel('flutter_system_events/events');
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          eventChannel.name,
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('listen', null),
          ),
          (_) {},
        );

    final event = platform.events.first;
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          eventChannel.name,
          const StandardMethodCodec().encodeSuccessEnvelope({
            'type': 'memory',
            'state': 'trim',
            'level': 10,
          }),
          (_) {},
        );

    expect(await event, isA<MemoryEvent>());
  });

  test('events converts screen off payloads to screen events', () async {
    final platform = MethodChannelFlutterSystemEvents();
    const eventChannel = EventChannel('flutter_system_events/events');
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          eventChannel.name,
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('listen', null),
          ),
          (_) {},
        );

    final event = platform.events.first;
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          eventChannel.name,
          const StandardMethodCodec().encodeSuccessEnvelope({
            'type': 'screen',
            'change': 'off',
          }),
          (_) {},
        );

    final screenEvent = await event;
    expect(screenEvent, isA<ScreenEvent>());
    expect((screenEvent as ScreenEvent).change, ScreenChange.off);
    expect(screenEvent.brightness, isNull);
  });

  test('events converts screen brightness payloads to screen events', () async {
    final platform = MethodChannelFlutterSystemEvents();
    const eventChannel = EventChannel('flutter_system_events/events');
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          eventChannel.name,
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('listen', null),
          ),
          (_) {},
        );

    final event = platform.events.first;
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          eventChannel.name,
          const StandardMethodCodec().encodeSuccessEnvelope({
            'type': 'screen',
            'change': 'brightness',
            'brightness': 0.42,
          }),
          (_) {},
        );

    final screenEvent = await event;
    expect(screenEvent, isA<ScreenEvent>());
    expect((screenEvent as ScreenEvent).change, ScreenChange.brightness);
    expect(screenEvent.brightness, 0.42);
  });

  test('events converts screenshot payloads to screenshot events', () async {
    final platform = MethodChannelFlutterSystemEvents();
    const eventChannel = EventChannel('flutter_system_events/events');
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          eventChannel.name,
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('listen', null),
          ),
          (_) {},
        );

    final event = platform.events.first;
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          eventChannel.name,
          const StandardMethodCodec().encodeSuccessEnvelope({
            'type': 'screenshot',
          }),
          (_) {},
        );

    expect(await event, isA<ScreenshotEvent>());
  });

  test('events converts thermal payloads to thermal events', () async {
    final platform = MethodChannelFlutterSystemEvents();
    const eventChannel = EventChannel('flutter_system_events/events');
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          eventChannel.name,
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('listen', null),
          ),
          (_) {},
        );

    final event = platform.events.first;
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          eventChannel.name,
          const StandardMethodCodec().encodeSuccessEnvelope({
            'type': 'thermal',
            'state': 'serious',
          }),
          (_) {},
        );

    final thermalEvent = await event;
    expect(thermalEvent, isA<ThermalEvent>());
    expect((thermalEvent as ThermalEvent).state, ThermalState.serious);
  });

  test('events converts non-map payloads to unknown events', () async {
    final platform = MethodChannelFlutterSystemEvents();
    const eventChannel = EventChannel('flutter_system_events/events');
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          eventChannel.name,
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('listen', null),
          ),
          (_) {},
        );

    final event = platform.events.first;
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          eventChannel.name,
          const StandardMethodCodec().encodeSuccessEnvelope('invalid'),
          (_) {},
        );

    expect(await event, isA<UnknownSystemEvent>());
  });
}
