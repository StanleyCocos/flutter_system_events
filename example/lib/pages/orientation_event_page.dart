import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_system_events/flutter_system_events.dart';

class OrientationEventPage extends StatefulWidget {
  const OrientationEventPage({super.key});

  @override
  State<OrientationEventPage> createState() => _OrientationEventPageState();
}

class _OrientationEventPageState extends State<OrientationEventPage> {
  StreamSubscription<SystemEvent>? _subscription;
  ScreenOrientation? _orientation;
  final _events = <String>[];

  @override
  void initState() {
    super.initState();
    _subscription = SystemEvents.events.listen((event) {
      if (event is! OrientationEvent || !mounted) return;
      setState(() {
        _orientation = event.orientation;
        _events.insert(0, event.orientation.name);
        if (_events.length > 8) _events.removeLast();
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentOrientation() async {
    final event = await SystemEvents.currentOrientation();
    debugPrint(
      '[OrientationEventPage] current orientation: ${event.orientation.name}',
    );
    if (!mounted) return;
    setState(() {
      _orientation = event.orientation;
      _events.insert(0, 'current ${event.orientation.name}');
      if (_events.length > 8) _events.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orientation Event')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('orientation: ${_orientation?.name ?? '-'}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCurrentOrientation,
            child: const Text('Get current orientation'),
          ),
          const SizedBox(height: 24),
          const Text('Rotate the device to trigger this event.'),
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
