import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_system_events/flutter_system_events.dart';

class TimeEventPage extends StatefulWidget {
  const TimeEventPage({super.key});

  @override
  State<TimeEventPage> createState() => _TimeEventPageState();
}

class _TimeEventPageState extends State<TimeEventPage> {
  StreamSubscription<SystemEvent>? _subscription;
  TimeChangeReason? _reason;
  final _events = <String>[];

  @override
  void initState() {
    super.initState();
    _subscription = SystemEvents.events.listen((event) {
      if (event is! TimeEvent || !mounted) return;
      setState(() {
        _reason = event.reason;
        _events.insert(0, event.reason.name);
        if (_events.length > 8) _events.removeLast();
      });
    });
    SystemEvents.initialize(
      config: const SystemEventsConfig(time: TimeConfig()),
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
      appBar: AppBar(title: const Text('Time Event')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('reason: ${_reason?.name ?? '-'}'),
          const SizedBox(height: 24),
          const Text(
            'Change system time, date, or timezone to trigger this event.',
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
