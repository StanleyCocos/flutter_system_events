import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_system_events_method_channel.dart';

abstract class FlutterSystemEventsPlatform extends PlatformInterface {
  /// Constructs a FlutterSystemEventsPlatform.
  FlutterSystemEventsPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterSystemEventsPlatform _instance = MethodChannelFlutterSystemEvents();

  /// The default instance of [FlutterSystemEventsPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterSystemEvents].
  static FlutterSystemEventsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterSystemEventsPlatform] when
  /// they register themselves.
  static set instance(FlutterSystemEventsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
