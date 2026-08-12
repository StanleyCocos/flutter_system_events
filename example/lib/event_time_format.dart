String formatEventDateTime(DateTime dateTime) {
  String pad(int value, int width) => value.toString().padLeft(width, '0');
  return '${dateTime.year}-${pad(dateTime.month, 2)}-${pad(dateTime.day, 2)} '
      '${pad(dateTime.hour, 2)}-${pad(dateTime.minute, 2)}-'
      '${pad(dateTime.second, 2)}-${pad(dateTime.millisecond, 3)}';
}

String formatTimedEvent(String message, {DateTime? now}) {
  return '${formatEventDateTime(now ?? DateTime.now())} $message';
}

String formatTimedLog(String message, {DateTime? now}) {
  return '[${formatEventDateTime(now ?? DateTime.now())}] $message';
}
