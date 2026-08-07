import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_system_events/flutter_system_events.dart';

typedef SystemEventLog = void Function(String message);

final class GlobalSystemEventLogger {
  GlobalSystemEventLogger({SystemEventLog? log}) : _log = log ?? debugPrint;

  final SystemEventLog _log;
  final _subscriptions = <StreamSubscription<SystemEvent>>[];

  void start() {
    if (_subscriptions.isNotEmpty) return;
    _listen('SystemEvents.events', SystemEvents.events);
    _listen('SystemEvents.keyboard', SystemEvents.keyboard);
    _listen('SystemEvents.lifecycle', SystemEvents.lifecycle);
    _listen('SystemEvents.network', SystemEvents.network);
    _listen('SystemEvents.memory', SystemEvents.memory);
    _listen('SystemEvents.battery', SystemEvents.battery);
    _listen('SystemEvents.orientation', SystemEvents.orientation);
    _listen('SystemEvents.time', SystemEvents.time);
    _listen('SystemEvents.screen', SystemEvents.screen);
    _listen('SystemEvents.screenshot', SystemEvents.screenshot);
    _listen('SystemEvents.thermal', SystemEvents.thermal);
  }

  Future<void> dispose() async {
    final subscriptions = List.of(_subscriptions);
    _subscriptions.clear();
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
  }

  void _listen(String prefix, Stream<SystemEvent> stream) {
    _subscriptions.add(
      stream.listen(
        (event) => _log('[$prefix]\n${_formatMap(_toLogMap(event))}'),
      ),
    );
  }

  Map<String, Object?> _toLogMap(SystemEvent event) {
    return switch (event) {
      LifecycleEvent(:final state) => {
        'event': 'LifecycleEvent',
        'state': state.name,
      },
      KeyboardEvent(:final visible, :final height) => {
        'event': 'KeyboardEvent',
        'visible': visible,
        'height': height,
      },
      NetworkEvent(:final online, :final networkType) => {
        'event': 'NetworkEvent',
        'online': online,
        'networkType': networkType.name,
      },
      MemoryEvent(:final state, :final level) => {
        'event': 'MemoryEvent',
        'state': state.name,
        'level': level,
      },
      BatteryEvent(:final level, :final charging, :final state) => {
        'event': 'BatteryEvent',
        'level': level,
        'charging': charging,
        'state': state.name,
      },
      OrientationEvent(:final orientation) => {
        'event': 'OrientationEvent',
        'orientation': orientation.name,
      },
      TimeEvent(:final reason) => {'event': 'TimeEvent', 'reason': reason.name},
      ScreenEvent(:final change, :final brightness) => {
        'event': 'ScreenEvent',
        'change': change.name,
        'brightness': brightness,
      },
      ScreenshotEvent() => {'event': 'ScreenshotEvent'},
      ThermalEvent(:final state) => {
        'event': 'ThermalEvent',
        'state': state.name,
      },
      UnknownSystemEvent(:final rawType, :final reason, :final rawPayload) => {
        'event': 'UnknownSystemEvent',
        'rawType': rawType,
        'reason': reason,
        'rawPayload': rawPayload,
      },
    };
  }

  String _formatMap(Map<String, Object?> map) {
    final buffer = StringBuffer('{\n');
    for (final entry in map.entries) {
      buffer.writeln("  '${entry.key}': ${_formatValue(entry.value)},");
    }
    buffer.write('}');
    return buffer.toString();
  }

  String _formatValue(Object? value) {
    return switch (value) {
      null => 'null',
      String() => "'${value.replaceAll('\\', '\\\\').replaceAll("'", r"\'")}'",
      _ => '$value',
    };
  }
}
