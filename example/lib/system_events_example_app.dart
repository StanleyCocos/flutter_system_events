import 'package:flutter/material.dart';

import 'pages/battery_event_page.dart';
import 'pages/keyboard_event_page.dart';
import 'pages/lifecycle_event_page.dart';
import 'pages/memory_event_page.dart';
import 'pages/network_event_page.dart';
import 'pages/orientation_event_page.dart';
import 'pages/screen_event_page.dart';
import 'pages/screenshot_event_page.dart';
import 'pages/thermal_event_page.dart';
import 'pages/time_event_page.dart';

class SystemEventsExampleApp extends StatelessWidget {
  const SystemEventsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: EventListPage());
  }
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
          ListTile(
            title: const Text('Screenshot'),
            subtitle: const Text('User screenshot taken'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _push(context, const ScreenshotEventPage()),
          ),
          ListTile(
            title: const Text('Thermal'),
            subtitle: const Text('Device thermal state'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _push(context, const ThermalEventPage()),
          ),
        ],
      ),
    );
  }
}
