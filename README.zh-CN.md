# flutter_system_events

[![pub package](https://img.shields.io/pub/v/flutter_system_events.svg)](https://pub.dev/packages/flutter_system_events)
[![coverage](https://codecov.io/gh/StanleyCocos/flutter_system_events/branch/master/graph/badge.svg)](https://codecov.io/gh/StanleyCocos/flutter_system_events)

[English](README.md)

一个 Flutter 系统事件 API：既可以监听类型化事件变化，也可以按需读取当前系统状态。

当 App 需要响应键盘、生命周期、网络、内存、电池、屏幕方向、系统时间、屏幕状态、截屏、设备热状态或亮度变化，但不想自己接入多个平台监听器时，可以使用它。

## 安装

```yaml
dependencies:
  flutter_system_events: ^1.2.0
```

## API

监听全部事件，或只订阅某一类类型化事件：

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

不等待下一次事件，直接读取当前状态：

```dart
await SystemEvents.currentNetwork();
await SystemEvents.currentBattery();
await SystemEvents.currentOrientation();
await SystemEvents.currentScreenBrightness();
```

## 使用

初始化一次，然后监听你的 UI 关心的事件流。

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

也可以从一个流里处理全部事件：

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

## 事件字段

| 事件 | 字段 | 含义 |
| --- | --- | --- |
| `KeyboardEvent` | `visible` | 键盘是否可见。 |
| `KeyboardEvent` | `height` | 键盘高度，单位为逻辑像素。 |
| `LifecycleEvent` | `state` | 当前 App 生命周期状态。 |
| `NetworkEvent` | `online` | 当前是否有可用网络连接。 |
| `NetworkEvent` | `networkType` | 当前网络连接类型。 |
| `MemoryEvent` | `state` | 当前内存压力状态。 |
| `MemoryEvent` | `level` | 平台相关的内存压力等级。 |
| `BatteryEvent` | `level` | 电量，范围 `0` 到 `100`，不可用时为 `-1`。 |
| `BatteryEvent` | `charging` | 设备是否正在充电或已充满。 |
| `BatteryEvent` | `state` | 当前电池状态。 |
| `OrientationEvent` | `orientation` | 当前屏幕方向。 |
| `TimeEvent` | `reason` | 触发系统时间事件的原因。 |
| `ScreenEvent` | `change` | `off`、`on`、`unlocked` 或 `brightness`。 |
| `ScreenEvent` | `brightness` | 当 `change` 为 `brightness` 时，表示 `0.0` 到 `1.0` 的屏幕亮度。 |
| `ScreenshotEvent` | - | 用户截屏时触发。事件不会包含截图图片。 |
| `ThermalEvent` | `state` | 当前设备热状态。 |

内存事件只是系统提示。插件只报告压力状态，具体可以安全释放什么资源由你的 App 决定。

Android 屏幕事件包含熄屏、亮屏、解锁和亮度变化。iOS 支持解锁和亮度变化；iOS 没有可靠的公开 API 可以让 App 直接监听熄屏/亮屏。

`ScreenshotEvent` 支持 iOS 和 Android 14+（API 34+）。Android 13 及以下不支持这个事件，也不会触发回调。Android 宿主 App 需要声明 `android.permission.DETECT_SCREEN_CAPTURE`；这是安装时权限，不是运行时权限，因此不需要 `requestPermissions`。Android 在触发截屏检测时会显示系统提示。

`ThermalEvent` 支持 Android 10+（API 29+）和 iOS。Android 9 及以下不支持这个事件，也不会触发回调。Android 和 iOS 都不需要权限。

macOS 上的 `BatteryEvent` 使用系统电源信息 API。台式机或没有电池的设备会返回 `level=-1` 和 `state=unknown`。

macOS 上的 `OrientationEvent` 根据主屏幕尺寸推导，并在屏幕参数变化时触发。

## 平台支持

| 事件 | Android | iOS | macOS | Windows | Linux | Web |
| --- | --- | --- | --- | --- | --- | --- |
| `KeyboardEvent` | 支持 | 支持 | 支持 | 支持 | 努力实现中 | 支持 |
| `LifecycleEvent` | 支持 | 支持 | 支持 | 支持 | 努力实现中 | 支持 |
| `NetworkEvent` | 支持 | 支持 | 支持 | 支持 | 努力实现中 | 支持 |
| `MemoryEvent` | 支持 | 支持 | 努力实现中 | 努力实现中 | 努力实现中 | 努力实现中 |
| `BatteryEvent` | 支持 | 支持 | 支持 | 努力实现中 | 努力实现中 | 努力实现中 |
| `OrientationEvent` | 支持 | 支持 | 支持 | 努力实现中 | 努力实现中 | 努力实现中 |
| `TimeEvent` | 支持 | 支持 | 支持 | 努力实现中 | 努力实现中 | 努力实现中 |
| `ScreenEvent` | 支持 | 部分支持 | 努力实现中 | 努力实现中 | 努力实现中 | 努力实现中 |
| `ScreenshotEvent` | Android 14+ | 支持 | 不支持 | 不支持 | 不支持 | 不支持 |
| `ThermalEvent` | Android 10+ | 支持 | 不支持 | 不支持 | 不支持 | 不支持 |

`ScreenEvent` 在 iOS 上支持解锁和亮度变化。

## 示例

运行示例 App，并打开每个事件页面：

```sh
cd example
flutter run
```

示例包含独立页面：

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

每个页面都会在顶部显示最新事件值，并提供简单方式用于触发或手动验证事件。
