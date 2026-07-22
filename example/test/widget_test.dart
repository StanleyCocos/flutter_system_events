import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_system_events_example/main.dart';

void main() {
  testWidgets('opens keyboard event page', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Keyboard'), findsOneWidget);
    expect(find.text('Lifecycle'), findsOneWidget);

    await tester.tap(find.text('Keyboard'));
    await tester.pumpAndSettle();

    expect(find.text('Keyboard Event'), findsOneWidget);
    expect(find.text('Tap to show keyboard'), findsOneWidget);
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
  });
}
