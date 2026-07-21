import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_system_events/flutter_system_events.dart';
import 'package:flutter_system_events/flutter_system_events_platform_interface.dart';
import 'package:flutter_system_events/flutter_system_events_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterSystemEventsPlatform
    with MockPlatformInterfaceMixin
    implements FlutterSystemEventsPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterSystemEventsPlatform initialPlatform = FlutterSystemEventsPlatform.instance;

  test('$MethodChannelFlutterSystemEvents is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterSystemEvents>());
  });

  test('getPlatformVersion', () async {
    FlutterSystemEvents flutterSystemEventsPlugin = FlutterSystemEvents();
    MockFlutterSystemEventsPlatform fakePlatform = MockFlutterSystemEventsPlatform();
    FlutterSystemEventsPlatform.instance = fakePlatform;

    expect(await flutterSystemEventsPlugin.getPlatformVersion(), '42');
  });
}
