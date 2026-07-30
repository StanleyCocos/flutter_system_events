# flutter_system_events

[![pub package](https://img.shields.io/pub/v/flutter_system_events.svg)](https://pub.dev/packages/flutter_system_events)
[![coverage](https://codecov.io/gh/StanleyCocos/flutter_system_events/branch/master/graph/badge.svg)](https://codecov.io/gh/StanleyCocos/flutter_system_events)

[中文文档](README.zh-CN.md)

A Flutter plugin for listening to system events through one small typed API.

## Platform support

<table>
  <thead>
    <tr>
      <th rowspan="2">Platform</th>
      <th colspan="2">KeyboardEvent</th>
      <th>LifecycleEvent</th>
      <th colspan="2">NetworkEvent</th>
      <th colspan="2">MemoryEvent</th>
      <th colspan="3">BatteryEvent</th>
      <th>OrientationEvent</th>
      <th>TimeEvent</th>
      <th colspan="2">ScreenEvent</th>
    </tr>
    <tr>
      <th>visible</th>
      <th>height</th>
      <th>state</th>
      <th>online</th>
      <th>networkType</th>
      <th>state</th>
      <th>level</th>
      <th>level</th>
      <th>charging</th>
      <th>state</th>
      <th>orientation</th>
      <th>reason</th>
      <th>change</th>
      <th>brightness</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>Android</th>
      <td>Yes</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>Yes</td>
    </tr>
    <tr>
      <th>iOS</th>
      <td>Yes</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>Partial</td>
      <td>Yes</td>
    </tr>
    <tr>
      <th>macOS</th>
      <td>Yes</td>
      <td>Yes</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
    </tr>
    <tr>
      <th>Windows</th>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
    </tr>
    <tr>
      <th>Linux</th>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
    </tr>
    <tr>
      <th>Web</th>
      <td>Yes</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>Yes</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
      <td>In progress</td>
    </tr>
  </tbody>
</table>

Field meanings:

- `visible`: whether the keyboard is visible.
- `height`: keyboard height in logical pixels.
- `state`: lifecycle, memory pressure, or battery state depending on the event.
- `online`: whether a network connection is available.
- `networkType`: current network connection type.
- `level`: memory pressure level or battery level depending on the event.
- `charging`: whether the device is charging or full.
- `orientation`: current screen orientation.
- `reason`: why a time event was emitted.
- `change`: `off`, `on`, `unlocked`, or `brightness`.
- `brightness`: screen brightness from `0.0` to `1.0`.

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
