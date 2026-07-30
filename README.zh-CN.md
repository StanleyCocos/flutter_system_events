# flutter_system_events

[![pub package](https://img.shields.io/pub/v/flutter_system_events.svg)](https://pub.dev/packages/flutter_system_events)

[English](README.md)

一个轻量、全方位的 Flutter 系统事件监听插件。

版本 `0.7.0` 新增屏幕事件。

在真实 App 里，我经常只需要监听一些很小的系统状态变化：网络变化、应用生命周期、键盘高度、内存压力、电池状态、屏幕方向、系统时间、屏幕状态等等。每一类事件都可以用单独的库或插件解决，但如果只是为了监听几个事件就引入一堆依赖，会有点大材小用。

`flutter_system_events` 就是为这种场景准备的。它只做系统事件监听，并通过一个小而明确的类型化 API 暴露出来。你也可以只启用自己需要的事件类型，不用担心未使用的监听器浪费资源。

- 通过 `NetworkEvent` 显示离线提示
- 通过 `LifecycleEvent` 在 App 恢复时刷新数据
- 通过 `KeyboardEvent` 根据键盘高度移动输入区域
- 通过 `MemoryEvent` 清理 App 自己管理的缓存
- 通过 `BatteryEvent` 减少后台任务
- 通过 `OrientationEvent` 调整横竖屏布局
- 通过 `TimeEvent` 刷新和日期、时区相关的界面
- 通过 `ScreenEvent` 响应屏幕状态或亮度变化

当你只想要一个小 API，而不是手动接入多个平台监听器或插件时，可以使用它。

## 平台支持

| 事件 | Android | iOS | macOS | Windows | Linux | Web |
| --- | --- | --- | --- | --- | --- | --- |
| Keyboard | 支持 | 支持 | 支持 | 努力实现中 | 努力实现中 | 支持 |
| Lifecycle | 支持 | 支持 | 努力实现中 | 努力实现中 | 努力实现中 | 支持 |
| Network | 支持 | 支持 | 努力实现中 | 努力实现中 | 努力实现中 | 支持 |
| Memory | 支持 | 支持 | 努力实现中 | 努力实现中 | 努力实现中 | 努力实现中 |
| Battery | 支持 | 支持 | 努力实现中 | 努力实现中 | 努力实现中 | 努力实现中 |
| Orientation | 支持 | 支持 | 努力实现中 | 努力实现中 | 努力实现中 | 努力实现中 |
| Time | 支持 | 支持 | 努力实现中 | 努力实现中 | 努力实现中 | 努力实现中 |
| Screen | 支持 | 部分支持：解锁、亮度 | 努力实现中 | 努力实现中 | 努力实现中 | 努力实现中 |

## 安装

```yaml
dependencies:
  flutter_system_events: ^0.7.0
```

## 使用

初始化一次，然后监听 `SystemEvents.events`。

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

默认情况下，`initialize()` 会启动键盘、生命周期、网络、内存、屏幕方向、系统时间和屏幕事件。电池事件需要主动启用：

```dart
await SystemEvents.initialize(config: const SystemEventsConfig.all());
```

也可以传入自定义配置，只启用你需要的事件：

```dart
await SystemEvents.initialize(
  config: const SystemEventsConfig(
    network: NetworkConfig(),
    battery: BatteryConfig(),
  ),
);
```

内存事件只是系统提示。插件只报告压力状态，具体可以安全释放什么资源由你的 App 决定。

Android 屏幕事件包含熄屏、亮屏、解锁和亮度变化。iOS 支持解锁和亮度变化；iOS 没有可靠的公开 API 可以让 App 直接监听熄屏/亮屏。

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

每个页面都会在顶部显示最新事件值，并提供简单方式用于触发或手动验证事件。
