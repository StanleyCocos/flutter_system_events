import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_system_events/flutter_system_events.dart';

import '../event_time_format.dart';

class ScreenshotEventPage extends StatefulWidget {
  const ScreenshotEventPage({super.key});

  @override
  State<ScreenshotEventPage> createState() => _ScreenshotEventPageState();
}

class _ScreenshotEventPageState extends State<ScreenshotEventPage> {
  StreamSubscription<ScreenshotEvent>? _subscription;
  var _count = 0;
  final _events = <String>[];

  @override
  void initState() {
    super.initState();
    _subscription = SystemEvents.screenshot.listen((event) {
      if (!mounted) return;
      setState(() {
        _count++;
        _events.insert(0, formatTimedEvent('screenshot $_count'));
        if (_events.length > 8) _events.removeLast();
      });
    });

    unawaited(SystemEvents.enable(SystemEventType.screenshot));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Screenshot Event')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('count: $_count'),
          const SizedBox(height: 24),
          const Text('Take a screenshot to trigger this event.'),
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
