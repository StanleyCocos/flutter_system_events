# flutter_system_events

A small Flutter plugin for listening to system events with one API.

Version `0.2.0` focuses on Android and iOS:

- Keyboard show / hide / height
- App lifecycle changes
- Network status changes
- Memory warnings

Other platforms currently expose a no-op implementation.

## Installation

```yaml
dependencies:
  flutter_system_events: ^0.2.0
```

## Usage

Initialize once, then listen to the event stream.

```dart
import 'dart:async';

import 'package:flutter_system_events/flutter_system_events.dart';

StreamSubscription<SystemEvent>? subscription;

Future<void> startSystemEvents() async {
  subscription = SystemEvents.events.listen((event) {
    switch (event) {
      case KeyboardEvent(:final visible, :final height):
        print('keyboard visible=$visible height=$height');
      case LifecycleEvent(:final state):
        print('lifecycle ${state.name}');
      case NetworkEvent(:final online, :final networkType):
        print('network online=$online type=${networkType.name}');
      case MemoryEvent(:final state, :final level):
        print('memory state=${state.name} level=$level');
    }
  });

  await SystemEvents.initialize();
}

Future<void> stopSystemEvents() async {
  await subscription?.cancel();
  await SystemEvents.dispose();
}
```

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

## Platform support

| Event | Android | iOS | macOS | Windows | Linux | Web |
| --- | --- | --- | --- | --- | --- | --- |
| Keyboard | Yes | Yes | No-op | No-op | No-op | No-op |
| Lifecycle | Yes | Yes | No-op | No-op | No-op | No-op |
| Network | Yes | Yes | No-op | No-op | No-op | No-op |
| Memory | Yes | Yes | No-op | No-op | No-op | No-op |

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

Each page shows the latest event value at the top and provides a simple way to trigger or manually verify the event.
