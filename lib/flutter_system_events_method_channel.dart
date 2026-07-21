import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_system_events_platform_interface.dart';

/// An implementation of [FlutterSystemEventsPlatform] that uses method channels.
class MethodChannelFlutterSystemEvents extends FlutterSystemEventsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_system_events');

  @visibleForTesting
  final eventChannel = const EventChannel('flutter_system_events/events');

  late final Stream<SystemEvent> _events = eventChannel
      .receiveBroadcastStream()
      .map((event) => SystemEvent.fromMap(event as Map<dynamic, dynamic>));

  @override
  Future<void> initialize() {
    return methodChannel.invokeMethod<void>('initialize');
  }

  @override
  Stream<SystemEvent> get events => _events;
}
