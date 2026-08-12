import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_system_events/flutter_system_events.dart';

import '../event_time_format.dart';

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
        _events.insert(0, formatTimedEvent('state=${event.state.name}'));
        if (_events.length > 8) _events.removeLast();
      });
    });

    unawaited(SystemEvents.enable(SystemEventType.thermal));
    unawaited(_loadCurrentThermal());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentThermal() async {
    try {
      final event = await SystemEvents.currentThermal();
      debugPrint(
        formatTimedLog(
          '[ThermalEventPage] current thermal: state=${event.state.name}',
        ),
      );
      if (!mounted) return;
      setState(() {
        _state = event.state;
        _events.insert(
          0,
          formatTimedEvent('current state=${event.state.name}'),
        );
        if (_events.length > 8) _events.removeLast();
      });
    } on Object catch (error) {
      debugPrint(
        formatTimedLog(
          '[ThermalEventPage] current thermal unavailable: $error',
        ),
      );
      if (!mounted) return;
      setState(() {
        _events.insert(0, formatTimedEvent('current unavailable'));
        if (_events.length > 8) _events.removeLast();
      });
    }
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCurrentThermal,
            child: const Text('Get current thermal'),
          ),
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
