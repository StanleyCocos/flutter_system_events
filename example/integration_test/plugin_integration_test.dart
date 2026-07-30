import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_system_events_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('example starts', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('System Events'), findsOneWidget);
  });

  testWidgets('macOS keyboard page receives hidden keyboard event', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Keyboard'));
    await tester.pumpAndSettle();

    expect(find.text('Keyboard Event'), findsOneWidget);

    if (!Platform.isMacOS) return;

    await tester.pumpAndSettle();

    expect(find.text('visible: false'), findsOneWidget);
    expect(find.text('height: 0'), findsOneWidget);
    expect(find.text('hide height=0'), findsOneWidget);
  });
}
