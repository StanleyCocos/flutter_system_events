import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_system_events/flutter_system_events.dart';

import 'global_system_event_logger.dart';
import 'system_events_example_app.dart';

void main() => runApp(const SystemEventsExample());

class SystemEventsExample extends StatefulWidget {
  const SystemEventsExample({super.key});

  @override
  State<SystemEventsExample> createState() => _SystemEventsExampleState();
}

class _SystemEventsExampleState extends State<SystemEventsExample> {
  StreamSubscription<ScreenshotEvent>? _screenshotSubscription;
  StreamSubscription<ThermalEvent>? _thermalSubscription;
  final GlobalSystemEventLogger _eventLogger = GlobalSystemEventLogger();

  @override
  void initState() {
    super.initState();
    unawaited(SystemEvents.initialize(config: const SystemEventsConfig.all()));
    _eventLogger.start();
    _screenshotSubscription = SystemEvents.screenshot.listen((event) {
      debugPrint('screenshot taken');
    });

    _thermalSubscription = SystemEvents.thermal.listen((event) {
      debugPrint('thermal state=${event.state.name}');
    });
  }

  @override
  void dispose() {
    unawaited(_eventLogger.dispose());
    unawaited(_screenshotSubscription?.cancel());
    unawaited(_thermalSubscription?.cancel());
    unawaited(SystemEvents.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SystemEventsExampleApp();
  }
}
