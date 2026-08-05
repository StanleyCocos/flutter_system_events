import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_system_events/flutter_system_events.dart';

class ThermalEventPage extends StatefulWidget {
  const ThermalEventPage({super.key});

  @override
  State<ThermalEventPage> createState() => _ThermalEventPageState();
}

class _ThermalEventPageState extends State<ThermalEventPage> {
  StreamSubscription<ThermalEvent>? _subscription;
  ThermalState? _state;
  var _count = 0;
  final _events = <String>[];

  @override
  void initState() {
    super.initState();
    _subscription = SystemEvents.thermal.listen((event) {
      if (!mounted) return;
      setState(() {
        _state = event.state;
        _count++;
        _events.insert(0, 'state=${event.state.name}');
        if (_events.length > 8) _events.removeLast();
      });
    });

    unawaited(SystemEvents.enable(SystemEventType.thermal));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thermal Event')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('state: ${_state?.name ?? '-'}'),
          const SizedBox(height: 8),
          Text('count: $_count'),
          const SizedBox(height: 24),
          const Text(
            'Thermal changes are emitted when the device heats up or cools down.',
          ),
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
