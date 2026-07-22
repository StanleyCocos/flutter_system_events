import 'package:flutter/material.dart';

import 'pages/keyboard_event_page.dart';
import 'pages/lifecycle_event_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: EventListPage());
  }
}

class EventListPage extends StatelessWidget {
  const EventListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Events')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Keyboard'),
            subtitle: const Text('Show, hide, height'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const KeyboardEventPage(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Lifecycle'),
            subtitle: const Text('Resume, inactive, pause, detach'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const LifecycleEventPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
