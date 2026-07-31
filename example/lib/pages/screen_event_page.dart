import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_system_events/flutter_system_events.dart';

class ScreenEventPage extends StatefulWidget {
  const ScreenEventPage({super.key});

  @override
  State<ScreenEventPage> createState() => _ScreenEventPageState();
}

class _ScreenEventPageState extends State<ScreenEventPage> {
  StreamSubscription<SystemEvent>? _subscription;
  ScreenChange? _change;
  double? _brightness;
  final _events = <String>[];

  @override
  void initState() {
    super.initState();
    _subscription = SystemEvents.events.listen((event) {
      if (event is! ScreenEvent || !mounted) return;
      setState(() {
        _change = event.change;
        _brightness = event.brightness;
        _events.insert(0, _eventText(event));
        if (_events.length > 8) _events.removeLast();
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Screen Event')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('change: ${_change?.name ?? '-'}'),
          const SizedBox(height: 8),
          Text('brightness: ${_formatBrightness(_brightness)}'),
          const SizedBox(height: 24),
          const Text(
            'Lock, unlock, or change brightness to trigger this event.',
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

String _eventText(ScreenEvent event) {
  final brightness = event.brightness;
  if (brightness == null) return event.change.name;
  return '${event.change.name} brightness=${_formatBrightness(brightness)}';
}

String _formatBrightness(double? brightness) {
  if (brightness == null) return '-';
  return brightness.toStringAsFixed(2);
}
