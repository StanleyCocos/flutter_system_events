import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_system_events/flutter_system_events.dart';

class BatteryEventPage extends StatefulWidget {
  const BatteryEventPage({super.key});

  @override
  State<BatteryEventPage> createState() => _BatteryEventPageState();
}

class _BatteryEventPageState extends State<BatteryEventPage> {
  StreamSubscription<SystemEvent>? _subscription;
  int _level = -1;
  bool? _charging;
  BatteryState? _state;
  final _events = <String>[];

  @override
  void initState() {
    super.initState();
    _subscription = SystemEvents.events.listen((event) {
      if (event is! BatteryEvent || !mounted) return;
      setState(() {
        _level = event.level;
        _charging = event.charging;
        _state = event.state;
        _events.insert(
          0,
          'level=${event.level} charging=${event.charging} state=${event.state.name}',
        );
        if (_events.length > 8) _events.removeLast();
      });
    });
    SystemEvents.initialize(
      config: const SystemEventsConfig(battery: BatteryConfig()),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    SystemEvents.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Battery Event')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('level: ${_level < 0 ? '-' : '$_level%'}'),
          const SizedBox(height: 8),
          Text('charging: ${_charging ?? '-'}'),
          const SizedBox(height: 8),
          Text('state: ${_state?.name ?? '-'}'),
          const SizedBox(height: 24),
          const Text('Plug or unplug power to trigger this event.'),
          const SizedBox(height: 24),
          const Text('Recent events'),
          const SizedBox(height: 8),
          if (_events.isEmpty) const Text('-'),
          for (final event in _events) Text(event),
        ],
      ),
    );
  }
}
