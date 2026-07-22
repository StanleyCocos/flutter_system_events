import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_system_events/flutter_system_events.dart';

class NetworkEventPage extends StatefulWidget {
  const NetworkEventPage({super.key});

  @override
  State<NetworkEventPage> createState() => _NetworkEventPageState();
}

class _NetworkEventPageState extends State<NetworkEventPage> {
  StreamSubscription<SystemEvent>? _subscription;
  bool? _online;
  NetworkType? _networkType;
  final _events = <String>[];

  @override
  void initState() {
    super.initState();
    _subscription = SystemEvents.events.listen((event) {
      if (event is! NetworkEvent || !mounted) return;
      setState(() {
        _online = event.online;
        _networkType = event.networkType;
        _events.insert(
          0,
          'online=${event.online} type=${event.networkType.name}',
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
      appBar: AppBar(title: const Text('Network Event')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('online: ${_online ?? '-'}'),
          const SizedBox(height: 8),
          Text('type: ${_networkType?.name ?? '-'}'),
          const SizedBox(height: 24),
          const Text('Toggle Wi-Fi or cellular data to trigger this event.'),
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
