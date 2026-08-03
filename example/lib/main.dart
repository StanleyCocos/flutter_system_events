import 'package:flutter/material.dart';
import 'package:flutter_system_events/flutter_system_events.dart';

import 'global_system_event_logger.dart';
import 'pages/battery_event_page.dart';
import 'pages/keyboard_event_page.dart';
import 'pages/lifecycle_event_page.dart';
import 'pages/memory_event_page.dart';
import 'pages/network_event_page.dart';
import 'pages/orientation_event_page.dart';
import 'pages/screen_event_page.dart';
import 'pages/time_event_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _eventLogger = GlobalSystemEventLogger();

  @override
  void initState() {
    super.initState();
    SystemEvents.initialize(config: const SystemEventsConfig.all());
    _eventLogger.start();
  }

  @override
  void dispose() {
    _eventLogger.dispose();
    SystemEvents.dispose();
    super.dispose();
  }

  @override
  Widget build(_) => MaterialApp(home: EventListPage());
}

class EventListPage extends StatelessWidget {
  const EventListPage({super.key});

  Future<void> _push(BuildContext context, Widget page) {
    return Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Events')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Keyboard'),
            subtitle: const Text('Show, hide, height'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _push(context, const KeyboardEventPage()),
          ),
          ListTile(
            title: const Text('Lifecycle'),
            subtitle: const Text('Resume, inactive, pause, detach'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _push(context, const LifecycleEventPage()),
          ),
          ListTile(
            title: const Text('Network'),
            subtitle: const Text('Online, offline, type'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _push(context, const NetworkEventPage()),
          ),
          ListTile(
            title: const Text('Memory'),
            subtitle: const Text('Warning, low memory, trim'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _push(context, const MemoryEventPage()),
          ),
          ListTile(
            title: const Text('Battery'),
            subtitle: const Text('Level, charging, state'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _push(context, const BatteryEventPage()),
          ),
          ListTile(
            title: const Text('Orientation'),
            subtitle: const Text('Portrait, landscape, direction'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _push(context, const OrientationEventPage()),
          ),
          ListTile(
            title: const Text('Time'),
            subtitle: const Text('Time, date, timezone'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _push(context, const TimeEventPage()),
          ),
          ListTile(
            title: const Text('Screen'),
            subtitle: const Text('Off, on, unlock, brightness'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _push(context, const ScreenEventPage()),
          ),
        ],
      ),
    );
  }
}
