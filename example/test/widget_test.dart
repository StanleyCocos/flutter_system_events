import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_system_events_example/main.dart';

void main() {
  testWidgets('opens keyboard event page', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Keyboard'), findsOneWidget);
    expect(find.text('Lifecycle'), findsOneWidget);
    expect(find.text('Network'), findsOneWidget);
    expect(find.text('Memory'), findsOneWidget);
    expect(find.text('Battery'), findsOneWidget);

    await tester.tap(find.text('Keyboard'));
    await tester.pumpAndSettle();

    expect(find.text('Keyboard Event'), findsOneWidget);
    expect(find.text('Tap to show keyboard'), findsOneWidget);
    expect(find.text('Recent events'), findsOneWidget);
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
}
