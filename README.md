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
  flutter_system_events: ^1.2.0
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
await SystemEvents.currentThermal();
```

### Migration note

Event streams emit changes only. If existing UI code depended on the first
`network`, `battery`, `orientation`, or `thermal` event to initialize state,
read the current value first with the matching `current...()` API, then listen
for changes. Keyboard has no current-value API; initialize keyboard UI as hidden
and listen for later visibility changes.

## Usage

Initialize once, then listen to the stream that matches the state your UI cares
about. Event streams report changes only; read current values explicitly when
initializing UI state.

```dart
import 'dart:async';

import 'package:flutter_system_events/flutter_system_events.dart';

StreamSubscription<NetworkEvent>? networkSubscription;

Future<void> startSystemEvents() async {
  await SystemEvents.initialize();

  final currentNetwork = await SystemEvents.currentNetwork();
  print(
    'current network online=${currentNetwork.online} '
    'type=${currentNetwork.networkType.name}',
  );

  networkSubscription = SystemEvents.network.listen((event) {
    print('network changed online=${event.online} type=${event.networkType.name}');
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

## How events are implemented

`KeyboardEvent`

Android reads the app window's visible frame during global layout changes and
treats the keyboard as visible when the hidden area is more than 15% of the root
view height. iOS listens to UIKit keyboard show/hide notifications. Web infers
keyboard visibility from viewport resize events. macOS and Windows do not emit
an initial keyboard state.

Keyboard height is a UI approximation. Floating keyboards, split keyboards,
hardware keyboards, fullscreen input modes, and unusual window insets can make
the reported height different from the actual input surface.

Official docs: Android
[`ViewTreeObserver.OnGlobalLayoutListener`](https://developer.android.com/reference/android/view/ViewTreeObserver.OnGlobalLayoutListener),
iOS
[`UIResponder.keyboardWillShowNotification`](https://developer.apple.com/documentation/uikit/uiresponder/keyboardwillshownotification),
Web
[`Window.resize`](https://developer.mozilla.org/en-US/docs/Web/API/Window/resize_event).

`LifecycleEvent`

Android maps `Application.ActivityLifecycleCallbacks` for the attached activity.
iOS maps `UIApplication` lifecycle notifications. macOS and Windows map app or
window activation/minimize/close events. Web maps page visibility, focus, blur,
and unload events.

The Dart states are normalized, but the native lifecycle models are not
identical. For example, Windows `paused` means the window was minimized, while
iOS `paused` means the app entered background.

Official docs: Android
[`Application.ActivityLifecycleCallbacks`](https://developer.android.com/reference/android/app/Application.ActivityLifecycleCallbacks),
iOS
[`UIApplication.didBecomeActiveNotification`](https://developer.apple.com/documentation/uikit/uiapplication/didbecomeactivenotification),
macOS
[`NSApplication.didBecomeActiveNotification`](https://developer.apple.com/documentation/appkit/nsapplication/didbecomeactivenotification),
Web
[`Document.visibilitychange`](https://developer.mozilla.org/en-US/docs/Web/API/Document/visibilitychange_event).

`NetworkEvent`

Android uses `ConnectivityManager.NetworkCallback`. iOS and macOS use
`NWPathMonitor`. Windows uses `InternetGetConnectedState`. Web uses
`navigator.onLine` and browser online/offline events.

This reports the platform's connectivity view. `online=true` means a network is
available according to the OS or browser; it does not prove that a particular
server is reachable.

Official docs: Android
[`ConnectivityManager.NetworkCallback`](https://developer.android.com/reference/android/net/ConnectivityManager.NetworkCallback),
Apple
[`NWPathMonitor`](https://developer.apple.com/documentation/network/nwpathmonitor),
Windows
[`InternetGetConnectedState`](https://learn.microsoft.com/windows/win32/api/wininet/nf-wininet-internetgetconnectedstate),
Web
[`Navigator.onLine`](https://developer.mozilla.org/en-US/docs/Web/API/Navigator/onLine).

`MemoryEvent`

Android uses `ComponentCallbacks2` and reports `onLowMemory` or `onTrimMemory`
with the native trim level. iOS listens to the system memory warning
notification. Other platforms do not currently emit memory pressure events.

Memory events are hints. The plugin reports pressure; your app decides what can
be released safely. The meaning of `level` is platform-specific and should not
be compared across operating systems.

Official docs: Android
[`ComponentCallbacks2`](https://developer.android.com/reference/android/content/ComponentCallbacks2),
iOS
[`UIApplication.didReceiveMemoryWarningNotification`](https://developer.apple.com/documentation/uikit/uiapplication/didreceivememorywarningnotification).

`BatteryEvent`

Android reads the sticky `ACTION_BATTERY_CHANGED` broadcast and listens for
future battery broadcasts. iOS temporarily enables `UIDevice` battery monitoring
and listens for battery level/state notifications. macOS uses IOKit power source
APIs.

Battery values are not precision telemetry. They are reported at the granularity
and cadence chosen by the OS. On Apple platforms, battery level notifications
are documented as not being posted more frequently than once per minute. Devices
without a battery can report `level=-1` and `state=unknown`.

Official docs: Android
[`Intent.ACTION_BATTERY_CHANGED`](https://developer.android.com/reference/android/content/Intent#ACTION_BATTERY_CHANGED),
iOS
[`UIDevice.batteryLevelDidChangeNotification`](https://developer.apple.com/documentation/uikit/uidevice/batteryleveldidchangenotification),
macOS
[`IOPowerSources.h`](https://developer.apple.com/documentation/iokit/iopowersources_h).

`OrientationEvent`

Android derives orientation from display rotation and emits when configuration
changes. iOS listens to device orientation notifications. macOS derives
orientation from the main screen geometry and emits when screen parameters
change.

Orientation can be `unknown`, especially before the platform has a stable device
or display orientation. On macOS this is screen geometry, not physical device
rotation.

Official docs: Android
[`Display.getRotation`](<https://developer.android.com/reference/android/view/Display#getRotation()>),
iOS
[`UIDevice.orientationDidChangeNotification`](https://developer.apple.com/documentation/uikit/uidevice/orientationdidchangenotification),
macOS
[`NSApplication.didChangeScreenParametersNotification`](https://developer.apple.com/documentation/appkit/nsapplication/didchangescreenparametersnotification).

`TimeEvent`

Android listens to time, timezone, and date broadcasts. iOS and macOS listen to
system time, timezone, and calendar-day notifications.

This is not a timer. It only reports explicit system time/date/timezone changes
that the OS exposes to apps.

Official docs: Android
[`Intent.ACTION_TIME_CHANGED`](https://developer.android.com/reference/android/content/Intent#ACTION_TIME_CHANGED),
Android
[`Intent.ACTION_TIMEZONE_CHANGED`](https://developer.android.com/reference/android/content/Intent#ACTION_TIMEZONE_CHANGED),
iOS
[`UIApplication.significantTimeChangeNotification`](https://developer.apple.com/documentation/uikit/uiapplication/significanttimechangenotification),
Apple
[`NSSystemTimeZoneDidChange`](https://developer.apple.com/documentation/foundation/nsnotification/name/1414252-nssystemtimezonedidchange).

`ScreenEvent`

Android listens for screen off, screen on, and user-present broadcasts, and
observes `Settings.System.SCREEN_BRIGHTNESS`. iOS listens for screen brightness
changes and protected data becoming available after unlock.

iOS does not expose reliable public app-level screen off/on notifications.
Brightness is normalized to `0.0` through `1.0`; Android system brightness is
stored as an integer value and may not match perceived panel brightness.

Official docs: Android
[`Intent.ACTION_SCREEN_OFF`](https://developer.android.com/reference/android/content/Intent#ACTION_SCREEN_OFF),
Android
[`Settings.System.SCREEN_BRIGHTNESS`](https://developer.android.com/reference/android/provider/Settings.System#SCREEN_BRIGHTNESS),
iOS
[`UIScreen.brightnessDidChangeNotification`](https://developer.apple.com/documentation/uikit/uiscreen/brightnessdidchangenotification),
iOS
[`UIApplication.protectedDataDidBecomeAvailableNotification`](https://developer.apple.com/documentation/uikit/uiapplication/protecteddatadidbecomeavailablenotification).

`ScreenshotEvent`

iOS uses `UIApplication.userDidTakeScreenshotNotification`. Android uses
`Activity.registerScreenCaptureCallback`, which is available on Android 14+
(API 34+) and requires `android.permission.DETECT_SCREEN_CAPTURE` in the host
app manifest.

No screenshot image is included. Android 13 and earlier do not support this
event. `DETECT_SCREEN_CAPTURE` is an install-time permission, not a runtime
permission, so no `requestPermissions` flow is needed. Android shows a system
notice when screenshot detection is triggered.

Official docs: Android
[`Activity.registerScreenCaptureCallback`](<https://developer.android.com/reference/android/app/Activity#registerScreenCaptureCallback(java.util.concurrent.Executor,%20android.app.Activity.ScreenCaptureCallback)>),
Android
[`Manifest.permission.DETECT_SCREEN_CAPTURE`](https://developer.android.com/reference/android/Manifest.permission#DETECT_SCREEN_CAPTURE),
iOS
[`UIApplication.userDidTakeScreenshotNotification`](https://developer.apple.com/documentation/uikit/uiapplication/userdidtakescreenshotnotification).

`ThermalEvent`

Android uses `PowerManager.OnThermalStatusChangedListener`, available on Android
10+ (API 29+). iOS uses `ProcessInfo.thermalStateDidChangeNotification`.
Thermal streams emit changes only; use `currentThermal()` to read the current
thermal state.

Android 9 and earlier do not support this event. No Android or iOS permission is
required. Android has more native thermal states than iOS, so some states are
normalized into the shared Dart enum.

Official docs: Android
[`PowerManager.OnThermalStatusChangedListener`](https://developer.android.com/reference/android/os/PowerManager.OnThermalStatusChangedListener),
iOS
[`ProcessInfo.thermalStateDidChangeNotification`](https://developer.apple.com/documentation/foundation/processinfo/thermalstatedidchangenotification).

## Current value queries

| Method | Android | iOS | macOS | Windows | Linux | Web |
| --- | --- | --- | --- | --- | --- | --- |
| `currentNetwork()` | Yes | Yes | Yes | Yes | No | Yes |
| `currentBattery()` | Yes | Yes | Yes | No | No | No |
| `currentOrientation()` | Yes | Yes | Yes | No | No | No |
| `currentScreenBrightness()` | Yes | Yes | No | No | No | No |
| `currentThermal()` | Android 10+ | Yes | No | No | No | No |

## Platform support

| Event | Android | iOS | macOS | Windows | Linux | Web |
| --- | --- | --- | --- | --- | --- | --- |
| `KeyboardEvent` | Yes | Yes | Partial | Partial | In progress | Yes |
| `LifecycleEvent` | Yes | Yes | Yes | Yes | In progress | Yes |
| `NetworkEvent` | Yes | Yes | Yes | Yes | In progress | Yes |
| `MemoryEvent` | Yes | Yes | In progress | In progress | In progress | In progress |
| `BatteryEvent` | Yes | Yes | Yes | In progress | In progress | In progress |
| `OrientationEvent` | Yes | Yes | Yes | In progress | In progress | In progress |
| `TimeEvent` | Yes | Yes | Yes | In progress | In progress | In progress |
| `ScreenEvent` | Yes | Partial | In progress | In progress | In progress | In progress |
| `ScreenshotEvent` | Android 14+ | Yes | No | No | No | No |
| `ThermalEvent` | Android 10+ | Yes | No | No | No | No |
