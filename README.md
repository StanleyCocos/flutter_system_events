# flutter_system_events

[![pub package](https://img.shields.io/pub/v/flutter_system_events.svg)](https://pub.dev/packages/flutter_system_events)

[中文文档](README.zh-CN.md)

A lightweight, all-around system monitoring plugin for Flutter.

Version `0.7.0` adds screen events.

In real apps, I often need to listen to small pieces of system state: network
changes, app lifecycle, keyboard height, memory pressure, battery state,
orientation changes, time changes, screen state, and so
on. Each one can be solved with a separate package, but pulling in several
plugins just to watch a few events can feel heavier than the problem needs.

`flutter_system_events` exists for that case. It only listens for system events
and exposes them through one small, typed API. You can also enable only the event
types you need, so unused listeners do not waste resources.

- Show an offline banner from `NetworkEvent`
- Refresh data when the app resumes from `LifecycleEvent`
- Move input UI with keyboard height from `KeyboardEvent`
- Clear app-owned caches from `MemoryEvent`
- Reduce background work from `BatteryEvent`
- Adapt layouts from `OrientationEvent`
- Refresh date-sensitive UI from `TimeEvent`
- React to screen state or brightness from `ScreenEvent`

Use this when you want one small API instead of wiring several
platform-specific listeners or packages.

## Platform support

| Event | Android | iOS | macOS | Windows | Linux | Web |
| --- | --- | --- | --- | --- | --- | --- |
| Keyboard | Yes | Yes | Yes | In progress | In progress | Yes |
| Lifecycle | Yes | Yes | In progress | In progress | In progress | Yes |
| Network | Yes | Yes | In progress | In progress | In progress | Yes |
| Memory | Yes | Yes | In progress | In progress | In progress | In progress |
| Battery | Yes | Yes | In progress | In progress | In progress | In progress |
| Orientation | Yes | Yes | In progress | In progress | In progress | In progress |
| Time | Yes | Yes | In progress | In progress | In progress | In progress |
| Screen | Yes | Partial: unlock, brightness | In progress | In progress | In progress | In progress |

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

Memory events are hints. The plugin reports pressure; your app decides what can
be released safely.

Android screen events include off, on, unlocked, and brightness changes. iOS
supports unlocked and brightness changes; iOS does not expose reliable public
screen off/on notifications for apps.

## Example

Run the example app and open each event page:

```sh
cd example
flutter run
```

The example includes separate pages for:

- Keyboard
- Lifecycle
- Network
- Memory
- Battery
- Orientation
- Time
- Screen

Each page shows the latest event value at the top and provides a simple way to trigger or manually verify the event.
