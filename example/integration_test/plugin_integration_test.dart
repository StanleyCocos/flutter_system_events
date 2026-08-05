import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_system_events_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('example starts', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('System Events'), findsOneWidget);
  });

  testWidgets('opens every example page', (tester) async {
    await tester.pumpWidget(const MyApp());

    for (final page in _examplePages) {
      await _openPage(tester, page);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('System Events'), findsOneWidget);
    }
  });

  testWidgets('desktop keyboard page receives hidden keyboard event', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Keyboard'));
    await tester.pumpAndSettle();

    expect(find.text('Keyboard Event'), findsOneWidget);

    if (!Platform.isMacOS && !Platform.isWindows) return;

    await tester.pumpAndSettle();

    expect(find.text('visible: false'), findsOneWidget);
    expect(find.text('height: 0'), findsOneWidget);
    expect(find.text('hide height=0'), findsOneWidget);
  });

  testWidgets('opens screen event page', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Screen'));
    await tester.pumpAndSettle();

    expect(find.text('Screen Event'), findsOneWidget);
    expect(find.text('change: -'), findsOneWidget);
    expect(find.text('brightness: -'), findsOneWidget);
  });
}

Future<void> _openPage(WidgetTester tester, _ExamplePage page) async {
  await tester.tap(find.text(page.entry));
  await tester.pumpAndSettle();

  expect(find.text(page.title), findsOneWidget);
  for (final text in page.expectedTexts) {
    expect(find.text(text), findsOneWidget);
  }
}

const _examplePages = [
  _ExamplePage(
    entry: 'Keyboard',
    title: 'Keyboard Event',
    expectedTexts: ['Tap to show keyboard', 'Recent events'],
  ),
  _ExamplePage(
    entry: 'Lifecycle',
    title: 'Lifecycle Event',
    expectedTexts: ['state: -', 'Recent events'],
  ),
  _ExamplePage(
    entry: 'Network',
    title: 'Network Event',
    expectedTexts: ['online: -', 'type: -'],
  ),
  _ExamplePage(
    entry: 'Memory',
    title: 'Memory Event',
    expectedTexts: ['Start pressure', 'Allocated: 0 MB / 20480 MB'],
  ),
  _ExamplePage(
    entry: 'Battery',
    title: 'Battery Event',
    expectedTexts: ['level: -', 'charging: -', 'state: -'],
  ),
  _ExamplePage(
    entry: 'Orientation',
    title: 'Orientation Event',
    expectedTexts: ['orientation: -'],
  ),
  _ExamplePage(
    entry: 'Time',
    title: 'Time Event',
    expectedTexts: ['reason: -'],
  ),
  _ExamplePage(
    entry: 'Screen',
    title: 'Screen Event',
    expectedTexts: ['change: -', 'brightness: -'],
  ),
  _ExamplePage(
    entry: 'Screenshot',
    title: 'Screenshot Event',
    expectedTexts: ['count: 0', 'Recent events'],
  ),
];

class _ExamplePage {
  const _ExamplePage({
    required this.entry,
    required this.title,
    required this.expectedTexts,
  });

  final String entry;
  final String title;
  final List<String> expectedTexts;
}
