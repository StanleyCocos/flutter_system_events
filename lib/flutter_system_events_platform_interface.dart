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

  Future<void> initialize({
    SystemEventsConfig config = const SystemEventsConfig.defaults(),
  }) {
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
      'network' => NetworkEvent(
        online: map['online'] as bool,
        networkType: NetworkType.values.byName(map['networkType'] as String),
      ),
      'memory' => MemoryEvent(
        state: MemoryState.values.byName(map['state'] as String),
        level: map['level'] as int,
      ),
      _ => throw FormatException('Unsupported system event: ${map['type']}'),
    };
  }
}

final class SystemEventsConfig {
  const SystemEventsConfig({
    this.keyboard,
    this.lifecycle,
    this.network,
    this.memory,
    this.battery,
  });

  const SystemEventsConfig.defaults()
    : keyboard = const KeyboardConfig(),
      lifecycle = const LifecycleConfig(),
      network = const NetworkConfig(),
      memory = const MemoryConfig(),
      battery = null;

  const SystemEventsConfig.all()
    : keyboard = const KeyboardConfig(),
      lifecycle = const LifecycleConfig(),
      network = const NetworkConfig(),
      memory = const MemoryConfig(),
      battery = const BatteryConfig();

  final KeyboardConfig? keyboard;
  final LifecycleConfig? lifecycle;
  final NetworkConfig? network;
  final MemoryConfig? memory;
  final BatteryConfig? battery;

  Map<String, bool> toMap() {
    return {
      'keyboard': keyboard != null,
      'lifecycle': lifecycle != null,
      'network': network != null,
      'memory': memory != null,
      'battery': battery != null,
    };
  }
}

final class KeyboardConfig {
  const KeyboardConfig();
}

final class LifecycleConfig {
  const LifecycleConfig();
}

final class NetworkConfig {
  const NetworkConfig();
}

final class MemoryConfig {
  const MemoryConfig();
}

final class BatteryConfig {
  const BatteryConfig();
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

enum NetworkType { wifi, cellular, ethernet, other, none }

final class NetworkEvent extends SystemEvent {
  const NetworkEvent({required this.online, required this.networkType});

  final bool online;
  final NetworkType networkType;
}

enum MemoryState { warning, low, trim }

final class MemoryEvent extends SystemEvent {
  const MemoryEvent({required this.state, required this.level});

  final MemoryState state;
  final int level;
}
