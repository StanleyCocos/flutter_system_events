import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_system_events_platform_interface.dart';

/// An implementation of [FlutterSystemEventsPlatform] that uses method channels.
class MethodChannelFlutterSystemEvents extends FlutterSystemEventsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_system_events');

  /// The event channel used to receive native system events.
  @visibleForTesting
  final eventChannel = const EventChannel('flutter_system_events/events');

  late final Stream<SystemEvent> _events = eventChannel
      .receiveBroadcastStream()
      .map(SystemEvent.fromPayload);

  @override
  Future<void> initialize({
    SystemEventsConfig config = const SystemEventsConfig.defaults(),
  }) {
    return methodChannel.invokeMethod<void>('initialize', config.toMap());
  }

  @override
  Future<void> dispose() {
    return methodChannel.invokeMethod<void>('dispose');
  }

  @override
  Future<NetworkEvent> currentNetwork() async {
    final event = SystemEvent.fromPayload(
      await methodChannel.invokeMethod<Object?>('currentNetwork'),
    );
    if (event is NetworkEvent) return event;
    throw StateError('Expected NetworkEvent, got ${event.runtimeType}.');
  }

  @override
  Future<BatteryEvent> currentBattery() async {
    final event = SystemEvent.fromPayload(
      await methodChannel.invokeMethod<Object?>('currentBattery'),
    );
    if (event is BatteryEvent) return event;
    throw StateError('Expected BatteryEvent, got ${event.runtimeType}.');
  }

  @override
  Future<OrientationEvent> currentOrientation() async {
    final event = SystemEvent.fromPayload(
      await methodChannel.invokeMethod<Object?>('currentOrientation'),
    );
    if (event is OrientationEvent) return event;
    throw StateError('Expected OrientationEvent, got ${event.runtimeType}.');
  }

  @override
  Future<ScreenEvent> currentScreenBrightness() async {
    final event = SystemEvent.fromPayload(
      await methodChannel.invokeMethod<Object?>('currentScreenBrightness'),
    );
    if (event is ScreenEvent && event.change == ScreenChange.brightness) {
      return event;
    }
    throw StateError('Expected screen brightness event, got $event.');
  }

  @override
  Future<ThermalEvent> currentThermal() async {
    final Object? payload;
    try {
      payload = await methodChannel.invokeMethod<Object?>('currentThermal');
    } on MissingPluginException catch (error) {
      throw UnsupportedError('currentThermal() is not supported: $error');
    } on PlatformException catch (error) {
      if (error.code == 'unavailable') {
        throw UnsupportedError('currentThermal() is not supported: $error');
      }
      rethrow;
    }
    final event = SystemEvent.fromPayload(payload);
    if (event is ThermalEvent) return event;
    throw StateError('Expected ThermalEvent, got ${event.runtimeType}.');
  }

  @override
  Stream<SystemEvent> get events => _events;
}
