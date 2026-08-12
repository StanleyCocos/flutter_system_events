import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_system_events_example/event_time_format.dart';

void main() {
  test('formats event date time with milliseconds', () {
    expect(
      formatEventDateTime(DateTime(2026, 8, 12, 13, 4, 5, 6)),
      '2026-08-12 13-04-05-006',
    );
  });

  test('formats timed log message', () {
    expect(
      formatTimedLog(
        '[KeyboardEventPage] event visible=true height=300.0',
        now: DateTime(2026, 8, 12, 13, 4, 5, 6),
      ),
      '[2026-08-12 13-04-05-006] [KeyboardEventPage] event visible=true height=300.0',
    );
  });
}
