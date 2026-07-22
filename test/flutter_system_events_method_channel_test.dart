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
}
