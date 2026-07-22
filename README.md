# flutter_system_events

A Flutter plugin for listening to system events through a small unified API.

## Supported events

- Android: keyboard, lifecycle
- iOS: keyboard, lifecycle

Other platforms currently expose a no-op implementation.

## Usage

```dart
await SystemEvents.initialize();

final subscription = SystemEvents.events.listen((event) {
  switch (event) {
    case KeyboardEvent(:final visible, :final height):
      print('keyboard visible=$visible height=$height');
    case LifecycleEvent(:final state):
      print('lifecycle ${state.name}');
  }
});
```
