import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_system_events_method_channel.dart';

abstract class FlutterSystemEventsPlatform extends PlatformInterface {
  /// Constructs a FlutterSystemEventsPlatform.
  FlutterSystemEventsPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterSystemEventsPlatform _instance =
      MethodChannelFlutterSystemEvents();

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

  Future<void> initialize() {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<void> dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }

  Stream<SystemEvent> get events {
    throw UnimplementedError('events has not been implemented.');
  }
}

sealed class SystemEvent {
  const SystemEvent();

  factory SystemEvent.fromMap(Map<dynamic, dynamic> map) {
    return switch (map['type']) {
      'keyboard' => KeyboardEvent(
        visible: map['visible'] as bool,
        height: (map['height'] as num).toDouble(),
      ),
      'lifecycle' => LifecycleEvent(
        state: LifecycleState.values.byName(map['state'] as String),
      ),
      _ => throw FormatException('Unsupported system event: ${map['type']}'),
    };
  }
}

enum LifecycleState { resumed, inactive, paused, detached }

final class LifecycleEvent extends SystemEvent {
  const LifecycleEvent({required this.state});

  final LifecycleState state;
}

final class KeyboardEvent extends SystemEvent {
  const KeyboardEvent({required this.visible, required this.height});

  final bool visible;
  final double height;
}
