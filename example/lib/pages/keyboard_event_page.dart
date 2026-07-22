import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_system_events/flutter_system_events.dart';

class KeyboardEventPage extends StatefulWidget {
  const KeyboardEventPage({super.key});

  @override
  State<KeyboardEventPage> createState() => _KeyboardEventPageState();
}

class _KeyboardEventPageState extends State<KeyboardEventPage> {
  StreamSubscription<SystemEvent>? _subscription;
  bool _visible = false;
  double _height = 0;
  final _events = <String>[];

  @override
  void initState() {
    super.initState();
    _subscription = SystemEvents.events.listen((event) {
      if (event is! KeyboardEvent || !mounted) return;
      setState(() {
        _visible = event.visible;
        _height = event.height;
        _events.insert(
          0,
          '${event.visible ? 'show' : 'hide'} height=${event.height.toStringAsFixed(0)}',
        );
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
      appBar: AppBar(title: const Text('Keyboard Event')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('visible: $_visible'),
          const SizedBox(height: 8),
          Text('height: ${_height.toStringAsFixed(0)}'),
          const SizedBox(height: 24),
          const TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Tap to show keyboard',
            ),
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
