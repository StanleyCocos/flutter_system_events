import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_system_events/flutter_system_events.dart';

class MemoryEventPage extends StatefulWidget {
  const MemoryEventPage({super.key});

  @override
  State<MemoryEventPage> createState() => _MemoryEventPageState();
}

class _MemoryEventPageState extends State<MemoryEventPage> {
  static const _blockSizeMb = 32;
  static const _maxAllocatedMb = 20480;
  static const _bytesPerMb = 1024 * 1024;

  StreamSubscription<SystemEvent>? _subscription;
  Timer? _pressureTimer;
  MemoryState? _state;
  int _level = 0;
  final _events = <String>[];
  final _memoryBlocks = <Uint8List>[];

  int get _allocatedMb => _memoryBlocks.length * _blockSizeMb;
  bool get _isPressuring => _pressureTimer?.isActive ?? false;

  @override
  void initState() {
    super.initState();
    _subscription = SystemEvents.events.listen((event) {
      if (event is! MemoryEvent || !mounted) return;
      debugPrint(
        '[MemoryEventPage] memory callback: state=${event.state.name} level=${event.level}',
      );
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
    _pressureTimer?.cancel();
    _memoryBlocks.clear();
    _subscription?.cancel();
    SystemEvents.dispose();
    super.dispose();
  }

  void _startPressure() {
    if (_isPressuring) return;
    _pressureTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_allocatedMb >= _maxAllocatedMb) {
        _pausePressure();
        debugPrint(
          '[MemoryEventPage] memory pressure reached $_maxAllocatedMb MB and is being held',
        );
        return;
      }
      try {
        final block = Uint8List(_blockSizeMb * _bytesPerMb);
        for (var i = 0; i < block.length; i += 4096) {
          block[i] = _memoryBlocks.length % 256;
        }
        setState(() {
          _memoryBlocks.add(block);
          debugPrint('[MemoryEventPage] allocated $_allocatedMb MB');
        });
      } catch (error) {
        _pausePressure();
        debugPrint(
          '[MemoryEventPage] Dart heap exhausted at $_allocatedMb MB: $error',
        );
      }
    });
    debugPrint('[MemoryEventPage] memory pressure started');
    setState(() {});
  }

  void _pausePressure() {
    _pressureTimer?.cancel();
    _pressureTimer = null;
    debugPrint('[MemoryEventPage] memory pressure stopped at $_allocatedMb MB');
    setState(() {});
  }

  void _releasePressure() {
    _pausePressure();
    debugPrint(
      '[MemoryEventPage] memory pressure released at $_allocatedMb MB',
    );
    setState(_memoryBlocks.clear);
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
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _isPressuring ? _pausePressure : _startPressure,
                icon: Icon(_isPressuring ? Icons.stop : Icons.memory),
                label: Text(_isPressuring ? 'Pause' : 'Start pressure'),
              ),
              OutlinedButton.icon(
                onPressed: _memoryBlocks.isEmpty ? null : _releasePressure,
                icon: const Icon(Icons.delete),
                label: const Text('Release'),
              ),
              Text('Allocated: $_allocatedMb MB / $_maxAllocatedMb MB'),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'This allocates real Dart heap memory until the OS decides whether to send a memory warning.',
          ),
          const SizedBox(height: 24),
          const Text('Allocated blocks'),
          const SizedBox(height: 8),
          if (_memoryBlocks.isEmpty) const Text('-'),
          for (var i = _memoryBlocks.length; i > 0; i--)
            Text('Block $i: $_blockSizeMb MB'),
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
