// ignore: deprecated_member_use
import 'dart:html' as html;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_system_events/flutter_system_events_platform_interface.dart';
import 'package:flutter_system_events/flutter_system_events_web.dart';

void main() {
  test(
    'initialize with network enabled does not emit initial network event',
    () async {
      final platform = FlutterSystemEventsWeb();
      final events = <SystemEvent>[];
      final subscription = platform.events.listen(events.add);

      await platform.initialize(
        config: const SystemEventsConfig(network: NetworkConfig()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);

      await subscription.cancel();
      await platform.dispose();
    },
  );

  test(
    'network events are suppressed when browser state is unchanged',
    () async {
      final platform = FlutterSystemEventsWeb();
      final events = <SystemEvent>[];
      final subscription = platform.events.listen(events.add);

      await platform.initialize(
        config: const SystemEventsConfig(network: NetworkConfig()),
      );

      html.window
        ..dispatchEvent(html.Event('online'))
        ..dispatchEvent(html.Event('offline'));
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);

      await subscription.cancel();
      await platform.dispose();
    },
  );

  test('currentThermal is unsupported on web', () {
    final platform = FlutterSystemEventsWeb();

    expect(platform.currentThermal(), throwsA(isA<UnsupportedError>()));
  });
}
