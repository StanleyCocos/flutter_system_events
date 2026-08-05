import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_system_events/flutter_system_events_platform_interface.dart';

import 'package:flutter_system_events_example/main.dart';

class FakeSystemEventsPlatform extends FlutterSystemEventsPlatform {
  final controller = StreamController<SystemEvent>.broadcast(sync: true);
  SystemEventsConfig? initializedConfig;
  var initializeCount = 0;
  var disposeCount = 0;

  @override
  Future<void> initialize({
    SystemEventsConfig config = const SystemEventsConfig.defaults(),
  }) async {
    initializeCount++;
    initializedConfig = config;
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
  }

  @override
  Stream<SystemEvent> get events => controller.stream;
}

void main() {
  final initialPlatform = FlutterSystemEventsPlatform.instance;

  tearDown(() {
    FlutterSystemEventsPlatform.instance = initialPlatform;
  });

  testWidgets('opens keyboard event page', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Keyboard'), findsOneWidget);
    expect(find.text('Lifecycle'), findsOneWidget);
    expect(find.text('Network'), findsOneWidget);
    expect(find.text('Memory'), findsOneWidget);
    expect(find.text('Battery'), findsOneWidget);
    expect(find.text('Orientation'), findsOneWidget);
    expect(find.text('Time'), findsOneWidget);
    expect(find.text('Screen'), findsOneWidget);

    await tester.tap(find.text('Keyboard'));
    await tester.pumpAndSettle();

    expect(find.text('Keyboard Event'), findsOneWidget);
    expect(find.text('Tap to show keyboard'), findsOneWidget);
    expect(find.text('Recent events'), findsOneWidget);
    expect(find.text('-'), findsOneWidget);
    expect(find.byType(EditableText), findsOneWidget);
  });

  testWidgets('opens lifecycle event page', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Lifecycle'));
    await tester.pumpAndSettle();

    expect(find.text('Lifecycle Event'), findsOneWidget);
    expect(
      find.text('Send the app to background, then open it again.'),
      findsOneWidget,
    );
    expect(find.text('Recent events'), findsOneWidget);
  });

  testWidgets('opens network event page', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Network'));
    await tester.pumpAndSettle();

    expect(find.text('Network Event'), findsOneWidget);
    expect(
      find.text('Toggle Wi-Fi or cellular data to trigger this event.'),
      findsOneWidget,
    );
    expect(find.text('online: -'), findsOneWidget);
    expect(find.text('type: -'), findsOneWidget);
  });

  testWidgets('opens memory event page', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Memory'));
    await tester.pumpAndSettle();

    expect(find.text('Memory Event'), findsOneWidget);
    expect(
      find.text(
        'Memory warnings are emitted by the operating system under memory pressure.',
      ),
      findsOneWidget,
    );
    expect(find.text('Start pressure'), findsOneWidget);
    expect(find.text('Allocated: 0 MB / 20480 MB'), findsOneWidget);

    final release = find.widgetWithText(OutlinedButton, 'Release');
    expect(tester.widget<OutlinedButton>(release).onPressed, isNull);

    await tester.tap(find.text('Start pressure'));
    await tester.pump();

    expect(find.text('Pause'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Allocated: 32 MB / 20480 MB'), findsOneWidget);
    expect(find.text('Block 1: 32 MB'), findsOneWidget);

    await tester.tap(find.text('Pause'));
    await tester.pump();

    expect(find.text('Start pressure'), findsOneWidget);
    expect(find.text('Allocated: 32 MB / 20480 MB'), findsOneWidget);

    await tester.tap(release);
    await tester.pump();

    expect(find.text('Allocated: 0 MB / 20480 MB'), findsOneWidget);
    expect(find.text('Block 1: 32 MB'), findsNothing);
  });

  testWidgets('opens battery event page', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Battery'));
    await tester.pumpAndSettle();

    expect(find.text('Battery Event'), findsOneWidget);
    expect(
      find.text('Plug or unplug power to trigger this event.'),
      findsOneWidget,
    );
    expect(find.text('level: -'), findsOneWidget);
    expect(find.text('charging: -'), findsOneWidget);
    expect(find.text('state: -'), findsOneWidget);
  });

  testWidgets('opens orientation event page', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Orientation'));
    await tester.pumpAndSettle();

    expect(find.text('Orientation Event'), findsOneWidget);
    expect(
      find.text('Rotate the device to trigger this event.'),
      findsOneWidget,
    );
    expect(find.text('orientation: -'), findsOneWidget);
  });

  testWidgets('opens time event page', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();

    expect(find.text('Time Event'), findsOneWidget);
    expect(
      find.text('Change system time, date, or timezone to trigger this event.'),
      findsOneWidget,
    );
    expect(find.text('reason: -'), findsOneWidget);
  });

  testWidgets('opens screen event page', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Screen'));
    await tester.pumpAndSettle();

    expect(find.text('Screen Event'), findsOneWidget);
    expect(
      find.text('Lock, unlock, or change brightness to trigger this event.'),
      findsOneWidget,
    );
    expect(find.text('change: -'), findsOneWidget);
    expect(find.text('brightness: -'), findsOneWidget);
  });

  testWidgets('screen event page renders incoming screen events', (
    tester,
  ) async {
    final platform = FakeSystemEventsPlatform();
    FlutterSystemEventsPlatform.instance = platform;

    await tester.pumpWidget(const MyApp());

    expect(platform.initializeCount, 1);
    expect(platform.initializedConfig?.battery, isNotNull);

    await tester.tap(find.text('Screen'));
    await tester.pumpAndSettle();

    expect(platform.initializeCount, 1);
    expect(platform.initializedConfig?.screen, isNotNull);
    expect(platform.initializedConfig?.keyboard, isNotNull);

    for (final change in [
      ScreenChange.off,
      ScreenChange.on,
      ScreenChange.unlocked,
    ]) {
      platform.controller.add(ScreenEvent(change: change));
      await tester.pump();

      expect(find.text('change: ${change.name}'), findsOneWidget);
      expect(find.text(change.name), findsWidgets);
    }

    platform.controller.add(
      const ScreenEvent(change: ScreenChange.brightness, brightness: 0.42),
    );
    await tester.pump();

    expect(find.text('change: brightness'), findsOneWidget);
    expect(find.text('brightness: 0.42'), findsOneWidget);
    expect(find.text('brightness brightness=0.42'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(platform.disposeCount, 0);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    expect(platform.disposeCount, 1);
    await platform.controller.close();
  });
}
