import 'flutter_system_events_web_test_stub.dart'
    if (dart.library.html) 'flutter_system_events_web_test_browser.dart'
    as web_test;

void main() {
  web_test.main();
}
