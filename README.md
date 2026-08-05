# flutter_system_events

[![pub package](https://img.shields.io/pub/v/flutter_system_events.svg)](https://pub.dev/packages/flutter_system_events)
[![coverage](https://codecov.io/gh/StanleyCocos/flutter_system_events/branch/master/graph/badge.svg)](https://codecov.io/gh/StanleyCocos/flutter_system_events)

[中文文档](README.zh-CN.md)

One Flutter API for system events: listen to typed changes, or read the current
system state on demand.

Use it when your app needs to react to keyboard, lifecycle, network, memory,
battery, orientation, time, screen, screenshot, thermal, or brightness changes
without wiring several platform listeners yourself.

## Installation

```yaml
dependencies:
  flutter_system_events: ^0.8.0
```

## API

Listen to all events, or subscribe to one typed event group:

```dart
SystemEvents.events.listen((event) {});
SystemEvents.keyboard.listen((event) {});
SystemEvents.lifecycle.listen((event) {});
SystemEvents.network.listen((event) {});
SystemEvents.memory.listen((event) {});
SystemEvents.battery.listen((event) {});
SystemEvents.orientation.listen((event) {});
SystemEvents.time.listen((event) {});
SystemEvents.screen.listen((event) {});
SystemEvents.screenshot.listen((event) {});
SystemEvents.thermal.listen((event) {});
```

Read current values without waiting for the next event:

```dart
await SystemEvents.currentNetwork();
await SystemEvents.currentBattery();
await SystemEvents.currentOrientation();
await SystemEvents.currentScreenBrightness();
```

## Usage

Initialize once, then listen to the stream that matches the state your UI cares
about.

```dart
import 'dart:async';

import 'package:flutter_system_events/flutter_system_events.dart';

StreamSubscription<NetworkEvent>? networkSubscription;

Future<void> startSystemEvents() async {
  await SystemEvents.initialize();

  networkSubscription = SystemEvents.network.listen((event) {
    print('network online=${event.online} type=${event.networkType.name}');
  });

  final battery = await SystemEvents.currentBattery();
  print('battery level=${battery.level} state=${battery.state.name}');
}

Future<void> stopSystemEvents() async {
  await networkSubscription?.cancel();
  await SystemEvents.dispose();
}
```

You can also handle every event from one stream:

```dart
SystemEvents.events.listen((event) {
  switch (event) {
    case KeyboardEvent(:final visible, :final height):
      print('keyboard visible=$visible height=$height');
    case LifecycleEvent(:final state):
      if (state == LifecycleState.resumed) print('refresh data');
    case NetworkEvent(:final online, :final networkType):
      print('network online=$online type=${networkType.name}');
    case MemoryEvent():
      print('memory pressure');
    case BatteryEvent(:final level, :final charging, :final state):
      print('battery level=$level charging=$charging state=${state.name}');
    case OrientationEvent(:final orientation):
      print('orientation=${orientation.name}');
    case TimeEvent(:final reason):
      print('time reason=${reason.name}');
    case ScreenEvent(:final change, :final brightness):
      print('screen change=${change.name} brightness=$brightness');
    case ScreenshotEvent():
      print('screenshot taken');
    case ThermalEvent(:final state):
      print('thermal state=${state.name}');
    case UnknownSystemEvent(:final rawType, :final reason):
      print('unknown event type=$rawType reason=$reason');
  }
});
```

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
| `ScreenshotEvent` | - | Emitted when the user takes a screenshot. No screenshot image is included. |
| `ThermalEvent` | `state` | Current device thermal state. |

Memory events are hints. The plugin reports pressure; your app decides what can
be released safely.

Android screen events include off, on, unlocked, and brightness changes. iOS
supports unlocked and brightness changes; iOS does not expose reliable public
screen off/on notifications for apps.

`ScreenshotEvent` is supported on iOS and Android 14+ (API 34+). Android 13 and
earlier do not support this event and will not emit it. On Android, the host app
must declare `android.permission.DETECT_SCREEN_CAPTURE`; it is an install-time
permission, not a runtime permission, so no `requestPermissions` flow is needed.
Android shows a system notice when screenshot detection is triggered.

`ThermalEvent` is supported on Android 10+ (API 29+) and iOS. Android 9 and
earlier do not support this event and will not emit it. No Android or iOS
permission is required.

## Platform support

| Event | Android | iOS | macOS | Windows | Linux | Web |
| --- | --- | --- | --- | --- | --- | --- |
| `KeyboardEvent` | Yes | Yes | Yes | Yes | In progress | Yes |
| `LifecycleEvent` | Yes | Yes | In progress | In progress | In progress | Yes |
| `NetworkEvent` | Yes | Yes | In progress | In progress | In progress | Yes |
| `MemoryEvent` | Yes | Yes | In progress | In progress | In progress | In progress |
| `BatteryEvent` | Yes | Yes | In progress | In progress | In progress | In progress |
| `OrientationEvent` | Yes | Yes | In progress | In progress | In progress | In progress |
| `TimeEvent` | Yes | Yes | In progress | In progress | In progress | In progress |
| `ScreenEvent` | Yes | Partial | In progress | In progress | In progress | In progress |
| `ScreenshotEvent` | Android 14+ | Yes | No | No | No | No |
| `ThermalEvent` | Android 10+ | Yes | No | No | No | No |

## Example

Run the example app and open each event page:

```sh
cd example
flutter run
```

The example includes separate pages:

- Keyboard
- Lifecycle
- Network
- Memory
- Battery
- Orientation
- Time
- Screen
- Screenshot
- Thermal

Each page shows the latest event value at the top and provides a simple way to
trigger or manually verify the event.
