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
      stream.listen((event) => _log('[$prefix] ${event.runtimeType}')),
    );
  }
}
