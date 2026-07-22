import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_system_events/flutter_system_events.dart';

class MemoryEventPage extends StatefulWidget {
  const MemoryEventPage({super.key});

  @override
  State<MemoryEventPage> createState() => _MemoryEventPageState();
}

class _MemoryEventPageState extends State<MemoryEventPage> {
  StreamSubscription<SystemEvent>? _subscription;
  MemoryState? _state;
  int _level = 0;
  final _events = <String>[];

  @override
  void initState() {
    super.initState();
    _subscription = SystemEvents.events.listen((event) {
      if (event is! MemoryEvent || !mounted) return;
      setState(() {
        _state = event.state;
        _level = event.level;
        _events.insert(0, 'state=${event.state.name} level=${event.level}');
        if (_events.length > 8) _events.removeLast();
      });
    });
    SystemEvents.initialize();
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
      appBar: AppBar(title: const Text('Memory Event')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('state: ${_state?.name ?? '-'}'),
          const SizedBox(height: 8),
          Text('level: $_level'),
          const SizedBox(height: 24),
          const Text(
            'Memory warnings are emitted by the operating system under memory pressure.',
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
