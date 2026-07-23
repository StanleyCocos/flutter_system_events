# flutter_system_events

[![pub package](https://img.shields.io/pub/v/flutter_system_events.svg)](https://pub.dev/packages/flutter_system_events)

A tiny Flutter plugin that turns common system signals into one typed stream.

Version `0.4.0` keeps the event stream alive when native payloads are unknown
or malformed.

- Show an offline banner from `NetworkEvent`
- Refresh data when the app resumes from `LifecycleEvent`
- Move input UI with keyboard height from `KeyboardEvent`
- Clear app-owned caches from `MemoryEvent`
- Reduce background work from `BatteryEvent`

Use this when you want one small API instead of wiring several platform-specific
listeners or packages.

Memory and battery events are not available on web. Desktop platforms currently
register the plugin but do not emit events.

## Installation

```yaml
dependencies:
  flutter_system_events: ^0.4.0
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

By default, `initialize()` starts keyboard, lifecycle, network, and memory
events. Battery is opt-in:

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

## Events

### KeyboardEvent

Emitted when the software keyboard visibility changes.

```dart
KeyboardEvent(
  visible: true,
  height: 320,
)
```

Fields:

- `visible`: whether the keyboard is visible
- `height`: keyboard height in logical pixels

### LifecycleEvent

Emitted when the app lifecycle changes.

```dart
LifecycleEvent(
  state: LifecycleState.resumed,
)
```

States:

- `resumed`
- `inactive`
- `paused`
- `detached`

### NetworkEvent

Emitted when the network status changes.

```dart
NetworkEvent(
  online: true,
  networkType: NetworkType.wifi,
)
```

Types:

- `wifi`
- `cellular`
- `ethernet`
- `other`
- `none`

### MemoryEvent

Emitted when the operating system reports memory pressure.

```dart
MemoryEvent(
  state: MemoryState.warning,
  level: 0,
)
```

States:

- `warning`
- `low`
- `trim`

### BatteryEvent

Emitted when battery level or charging state changes.

```dart
BatteryEvent(
  level: 80,
  charging: true,
  state: BatteryState.charging,
)
```

States:

- `charging`
- `discharging`
- `full`
- `unknown`

### UnknownSystemEvent

Emitted when a native or web payload is unsupported or malformed. This keeps the
stream alive when platforms add events before the Dart API understands them.

Fields:

- `rawPayload`: original payload received from the platform
- `rawType`: original event type, when present
- `reason`: why the payload could not be parsed as a known event

## Platform support

| Event | Android | iOS | macOS | Windows | Linux | Web |
| --- | --- | --- | --- | --- | --- | --- |
| Keyboard | Yes | Yes | No-op | No-op | No-op | Yes |
| Lifecycle | Yes | Yes | No-op | No-op | No-op | Yes |
| Network | Yes | Yes | No-op | No-op | No-op | Yes |
| Memory | Yes | Yes | No-op | No-op | No-op | No-op |
| Battery | Yes | Yes | No-op | No-op | No-op | No-op |

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

Each page shows the latest event value at the top and provides a simple way to trigger or manually verify the event.
