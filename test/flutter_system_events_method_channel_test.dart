import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_system_events/flutter_system_events_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelFlutterSystemEvents();
  const channel = MethodChannel('flutter_system_events');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('initialize calls native initialize', () async {
    String? method;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          method = methodCall.method;
          return null;
        });

    await platform.initialize();

    expect(method, 'initialize');
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
