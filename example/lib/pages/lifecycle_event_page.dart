import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_system_events/flutter_system_events.dart';

class LifecycleEventPage extends StatefulWidget {
  const LifecycleEventPage({super.key});

  @override
  State<LifecycleEventPage> createState() => _LifecycleEventPageState();
}

class _LifecycleEventPageState extends State<LifecycleEventPage> {
  StreamSubscription<SystemEvent>? _subscription;
  LifecycleState? _state;
  final _events = <String>[];

  @override
  void initState() {
    super.initState();
    _subscription = SystemEvents.events.listen((event) {
      if (event is! LifecycleEvent || !mounted) return;
      setState(() {
        _state = event.state;
        _events.insert(0, event.state.name);
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
      appBar: AppBar(title: const Text('Lifecycle Event')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('state: ${_state?.name ?? '-'}'),
          const SizedBox(height: 24),
          const Text('Send the app to background, then open it again.'),
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
