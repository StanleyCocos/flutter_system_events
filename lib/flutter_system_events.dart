
import 'flutter_system_events_platform_interface.dart';

class FlutterSystemEvents {
  Future<String?> getPlatformVersion() {
    return FlutterSystemEventsPlatform.instance.getPlatformVersion();
  }
}
