# flutter_system_events

[![pub package](https://img.shields.io/pub/v/flutter_system_events.svg)](https://pub.dev/packages/flutter_system_events)
[![coverage](https://codecov.io/gh/StanleyCocos/flutter_system_events/branch/master/graph/badge.svg)](https://codecov.io/gh/StanleyCocos/flutter_system_events)

[中文文档](README.zh-CN.md)

A Flutter plugin for listening to system events through one small typed API.

## Platform support

| Event | Android | iOS | macOS | Windows | Linux | Web |
| --- | --- | --- | --- | --- | --- | --- |
| `KeyboardEvent` | Yes | Yes | Yes | In progress | In progress | Yes |
| `LifecycleEvent` | Yes | Yes | In progress | In progress | In progress | Yes |
| `NetworkEvent` | Yes | Yes | In progress | In progress | In progress | Yes |
| `MemoryEvent` | Yes | Yes | In progress | In progress | In progress | In progress |
| `BatteryEvent` | Yes | Yes | In progress | In progress | In progress | In progress |
| `OrientationEvent` | Yes | Yes | In progress | In progress | In progress | In progress |
| `TimeEvent` | Yes | Yes | In progress | In progress | In progress | In progress |
| `ScreenEvent` | Yes | Partial | In progress | In progress | In progress | In progress |

## Event payloads

| Event | Field | Meaning |
| --- | --- | --- |
| `KeyboardEvent` | `visible` | Whether the keyboard is visible. |
| `KeyboardEvent` | `height` | Keyboard height in logical pixels. |
| `LifecycleEvent` | `state` | Current app lifecycle state. |
| `NetworkEvent` | `online` | Whether a network connection is available. |
| `NetworkEvent` | `networkType` | Current network connection type. |
| `MemoryEvent` | `state` | Current memory pressure state. |
| `MemoryEvent` | `level` | Platform-specific memory pressure level. |
| `BatteryEvent` | `level` | Battery level from `0` to `100`, or `-1` when unavailable. |
| `BatteryEvent` | `charging` | Whether the device is charging or full. |
| `BatteryEvent` | `state` | Current battery state. |
| `OrientationEvent` | `orientation` | Current screen orientation. |
| `TimeEvent` | `reason` | Why a time event was emitted. |
| `ScreenEvent` | `change` | `off`, `on`, `unlocked`, or `brightness`. |
| `ScreenEvent` | `brightness` | Screen brightness from `0.0` to `1.0` when `change` is `brightness`. |

Memory events are hints. The plugin reports pressure; your app decides what can
be released safely.

Android screen events include off, on, unlocked, and brightness changes. iOS
supports unlocked and brightness changes; iOS does not expose reliable public
screen off/on notifications for apps.

## Installation

```yaml
dependencies:
  flutter_system_events: ^0.7.0
```

## Usage

Initialize once, then listen to `SystemEvents.events`.

```dart
import 'dart:async';

import 'package:flutter/painting.dart';
import 'package:flutter_system_events/flutter_system_events.dart';

StreamSubscription<SystemEvent>? subscription;

Future<void> startSystemEvents() async {
  subscription = SystemEvents.events.listen((event) {
    switch (event) {
      case KeyboardEvent(:final visible, :final height):
        print('keyboard visible=$visible height=$height');
      case LifecycleEvent(:final state):
        if (state == LifecycleState.resumed) print('refresh data');
      case NetworkEvent(:final online, :final networkType):
        print('network online=$online type=${networkType.name}');
      case MemoryEvent():
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
      case BatteryEvent(:final level, :final charging, :final state):
        print('battery level=$level charging=$charging state=${state.name}');
      case OrientationEvent(:final orientation):
        print('orientation=${orientation.name}');
      case TimeEvent(:final reason):
        print('time reason=${reason.name}');
      case ScreenEvent(:final change, :final brightness):
        print('screen change=${change.name} brightness=$brightness');
      case UnknownSystemEvent(:final rawType, :final reason):
        print('unknown event type=$rawType reason=$reason');
    }
  });

  await SystemEvents.initialize();
}

Future<void> stopSystemEvents() async {
  await subscription?.cancel();
  await SystemEvents.dispose();
}
```

By default, `initialize()` starts keyboard, lifecycle, network, memory,
orientation, time, and screen events. Battery is opt-in:

```dart
await SystemEvents.initialize(config: const SystemEventsConfig.all());
```

Pass a custom config to enable only the events you need:

```dart
await SystemEvents.initialize(
  config: const SystemEventsConfig(
    network: NetworkConfig(),
    battery: BatteryConfig(),
  ),
);
```
