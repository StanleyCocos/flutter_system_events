import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_system_events_method_channel.dart';

/// Platform interface for native system event implementations.
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

  /// Starts platform listeners for the enabled event groups in [config].
  Future<void> initialize({
    SystemEventsConfig config = const SystemEventsConfig.defaults(),
  }) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Stops active platform listeners.
  Future<void> dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }

  /// Stream of decoded platform events.
  Stream<SystemEvent> get events {
    throw UnimplementedError('events has not been implemented.');
  }
}

/// Base type for every event emitted by [SystemEvents.events].
sealed class SystemEvent {
  /// Creates a system event.
  const SystemEvent();

  /// Decodes an event from a platform channel payload.
  factory SystemEvent.fromPayload(Object? payload) {
    if (payload is Map<dynamic, dynamic>) return SystemEvent.fromMap(payload);
    return UnknownSystemEvent(
      rawPayload: payload,
      reason: 'Expected an event map.',
    );
  }

  /// Decodes an event from a platform channel map.
  factory SystemEvent.fromMap(Map<dynamic, dynamic> map) {
    try {
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
        'battery' => BatteryEvent(
          level: map['level'] as int,
          charging: map['charging'] as bool,
          state: BatteryState.values.byName(map['state'] as String),
        ),
        'orientation' => OrientationEvent(
          orientation: ScreenOrientation.values.byName(
            map['orientation'] as String,
          ),
        ),
        _ => UnknownSystemEvent(
          rawPayload: map,
          rawType: map['type'],
          reason: 'Unsupported system event type.',
        ),
      };
    } on Object catch (error) {
      return UnknownSystemEvent(
        rawPayload: map,
        rawType: map['type'],
        reason: 'Invalid system event payload: $error',
      );
    }
  }
}

/// Selects which native event listeners are enabled.
final class SystemEventsConfig {
  /// Creates a custom event listener configuration.
  const SystemEventsConfig({
    this.keyboard,
    this.lifecycle,
    this.network,
    this.memory,
    this.battery,
    this.orientation,
  });

  /// Enables keyboard, lifecycle, network, memory, and orientation events.
  const SystemEventsConfig.defaults()
    : keyboard = const KeyboardConfig(),
      lifecycle = const LifecycleConfig(),
      network = const NetworkConfig(),
      memory = const MemoryConfig(),
      battery = null,
      orientation = const OrientationConfig();

  /// Enables every supported event group, including battery events.
  const SystemEventsConfig.all()
    : keyboard = const KeyboardConfig(),
      lifecycle = const LifecycleConfig(),
      network = const NetworkConfig(),
      memory = const MemoryConfig(),
      battery = const BatteryConfig(),
      orientation = const OrientationConfig();

  /// Enables keyboard visibility events when non-null.
  final KeyboardConfig? keyboard;

  /// Enables app lifecycle events when non-null.
  final LifecycleConfig? lifecycle;

  /// Enables network connectivity events when non-null.
  final NetworkConfig? network;

  /// Enables memory warning events when non-null.
  final MemoryConfig? memory;

  /// Enables battery state events when non-null.
  final BatteryConfig? battery;

  /// Enables screen orientation events when non-null.
  final OrientationConfig? orientation;

  /// Converts this configuration to the platform channel payload.
  Map<String, bool> toMap() {
    return {
      'keyboard': keyboard != null,
      'lifecycle': lifecycle != null,
      'network': network != null,
      'memory': memory != null,
      'battery': battery != null,
      'orientation': orientation != null,
    };
  }
}

/// Configuration for keyboard visibility events.
final class KeyboardConfig {
  /// Creates keyboard event configuration.
  const KeyboardConfig();
}

/// Configuration for app lifecycle events.
final class LifecycleConfig {
  /// Creates lifecycle event configuration.
  const LifecycleConfig();
}

/// Configuration for network connectivity events.
final class NetworkConfig {
  /// Creates network event configuration.
  const NetworkConfig();
}

/// Configuration for memory warning events.
final class MemoryConfig {
  /// Creates memory event configuration.
  const MemoryConfig();
}

/// Configuration for battery state events.
final class BatteryConfig {
  /// Creates battery event configuration.
  const BatteryConfig();
}

/// Configuration for screen orientation events.
final class OrientationConfig {
  /// Creates screen orientation event configuration.
  const OrientationConfig();
}

/// App lifecycle states reported by the platform.
enum LifecycleState { resumed, inactive, paused, detached }

/// Event emitted when the app lifecycle changes.
final class LifecycleEvent extends SystemEvent {
  /// Creates a lifecycle event.
  const LifecycleEvent({required this.state});

  /// Current lifecycle state.
  final LifecycleState state;
}

/// Event emitted when keyboard visibility changes.
final class KeyboardEvent extends SystemEvent {
  /// Creates a keyboard visibility event.
  const KeyboardEvent({required this.visible, required this.height});

  /// Whether the keyboard is visible.
  final bool visible;

  /// Keyboard height in logical pixels when visible.
  final double height;
}

/// Network connection types reported by the platform.
enum NetworkType { wifi, cellular, ethernet, other, none }

/// Event emitted when network connectivity changes.
final class NetworkEvent extends SystemEvent {
  /// Creates a network event.
  const NetworkEvent({required this.online, required this.networkType});

  /// Whether a network connection is available.
  final bool online;

  /// Current network connection type.
  final NetworkType networkType;
}

/// Memory pressure states reported by the platform.
enum MemoryState { warning, low, trim }

/// Event emitted when memory pressure changes.
final class MemoryEvent extends SystemEvent {
  /// Creates a memory event.
  const MemoryEvent({required this.state, required this.level});

  /// Current memory pressure state.
  final MemoryState state;

  /// Platform-specific memory pressure level.
  final int level;
}

/// Battery states reported by the platform.
enum BatteryState { charging, discharging, full, unknown }

/// Event emitted when battery state changes.
final class BatteryEvent extends SystemEvent {
  /// Creates a battery event.
  const BatteryEvent({
    required this.level,
    required this.charging,
    required this.state,
  });

  /// Battery level from 0 to 100, or -1 when unavailable.
  final int level;

  /// Whether the device is charging or full.
  final bool charging;

  /// Current battery state.
  final BatteryState state;
}

/// Screen orientations reported by the platform.
enum ScreenOrientation {
  portraitUp,
  portraitDown,
  landscapeLeft,
  landscapeRight,
  unknown,
}

/// Event emitted when the screen orientation changes.
final class OrientationEvent extends SystemEvent {
  /// Creates a screen orientation event.
  const OrientationEvent({required this.orientation});

  /// Current screen orientation.
  final ScreenOrientation orientation;
}

/// Event emitted when a platform payload cannot be decoded.
final class UnknownSystemEvent extends SystemEvent {
  /// Creates an unknown event wrapper.
  const UnknownSystemEvent({
    required this.rawPayload,
    required this.reason,
    this.rawType,
  });

  /// Original platform payload.
  final Object? rawPayload;

  /// Original event type, when provided.
  final Object? rawType;

  /// Human-readable decode failure reason.
  final String reason;
}
