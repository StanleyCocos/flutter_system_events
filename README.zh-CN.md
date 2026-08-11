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
await SystemEvents.currentThermal();
```

### 迁移说明

事件流只上报变化。如果旧 UI 依赖 `network`、`battery`、`orientation` 或 `thermal`
的首个事件初始化状态，请先用对应的 `current...()` API 读取当前值，再监听后续变化。
Keyboard 没有当前值 API；请将键盘 UI 初始为隐藏状态，再监听后续可见性变化。

## 使用

初始化一次，然后监听你的 UI 关心的事件流。事件流只上报变化；初始化 UI 状态时请显式读取当前值。

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

## 事件实现方式

`KeyboardEvent`

Android 在全局布局变化时读取 App 窗口可见区域，当被遮挡高度超过根视图高度的 15% 时认为键盘可见。iOS 监听 UIKit 键盘显示/隐藏通知。Web 通过视口高度变化推断键盘状态。macOS 和 Windows 不会上报初始键盘状态。

键盘高度是 UI 层面的近似值。悬浮键盘、分裂键盘、硬件键盘、全屏输入模式和特殊窗口 inset 都可能让高度与真实输入区域不完全一致。

官方文档：Android
[`ViewTreeObserver.OnGlobalLayoutListener`](https://developer.android.com/reference/android/view/ViewTreeObserver.OnGlobalLayoutListener)，iOS
[`UIResponder.keyboardWillShowNotification`](https://developer.apple.com/documentation/uikit/uiresponder/keyboardwillshownotification)，Web
[`Window.resize`](https://developer.mozilla.org/en-US/docs/Web/API/Window/resize_event)。

`LifecycleEvent`

Android 将当前 Activity 的 `Application.ActivityLifecycleCallbacks` 映射为 Dart 生命周期状态。iOS 使用 `UIApplication` 生命周期通知。macOS 和 Windows 使用应用或窗口激活、最小化、关闭事件。Web 使用页面可见性、焦点、失焦和卸载事件。

Dart 状态是统一后的抽象，但各平台原生生命周期并不完全等价。例如 Windows 的 `paused` 表示窗口被最小化，而 iOS 的 `paused` 表示 App 进入后台。

官方文档：Android
[`Application.ActivityLifecycleCallbacks`](https://developer.android.com/reference/android/app/Application.ActivityLifecycleCallbacks)，iOS
[`UIApplication.didBecomeActiveNotification`](https://developer.apple.com/documentation/uikit/uiapplication/didbecomeactivenotification)，macOS
[`NSApplication.didBecomeActiveNotification`](https://developer.apple.com/documentation/appkit/nsapplication/didbecomeactivenotification)，Web
[`Document.visibilitychange`](https://developer.mozilla.org/en-US/docs/Web/API/Document/visibilitychange_event)。

`NetworkEvent`

Android 使用 `ConnectivityManager.NetworkCallback`。iOS 和 macOS 使用 `NWPathMonitor`。Windows 使用 `InternetGetConnectedState`。Web 使用 `navigator.onLine` 以及浏览器 online/offline 事件。

这个事件表示系统或浏览器视角下的连接状态。`online=true` 只说明平台认为当前有网络连接，不保证某个业务服务器一定可达。

官方文档：Android
[`ConnectivityManager.NetworkCallback`](https://developer.android.com/reference/android/net/ConnectivityManager.NetworkCallback)，Apple
[`NWPathMonitor`](https://developer.apple.com/documentation/network/nwpathmonitor)，Windows
[`InternetGetConnectedState`](https://learn.microsoft.com/windows/win32/api/wininet/nf-wininet-internetgetconnectedstate)，Web
[`Navigator.onLine`](https://developer.mozilla.org/en-US/docs/Web/API/Navigator/onLine)。

`MemoryEvent`

Android 使用 `ComponentCallbacks2`，上报 `onLowMemory` 或 `onTrimMemory` 及原生 trim level。iOS 监听系统内存警告通知。其他平台当前不会触发内存压力事件。

内存事件只是系统提示。插件只报告压力状态，具体可以安全释放什么资源由你的 App 决定。`level` 是平台相关值，不应跨操作系统直接比较。

官方文档：Android
[`ComponentCallbacks2`](https://developer.android.com/reference/android/content/ComponentCallbacks2)，iOS
[`UIApplication.didReceiveMemoryWarningNotification`](https://developer.apple.com/documentation/uikit/uiapplication/didreceivememorywarningnotification)。

`BatteryEvent`

Android 读取 sticky `ACTION_BATTERY_CHANGED` 广播，并监听后续电池广播。iOS 临时开启 `UIDevice` 电池监控，并监听电量/状态通知。macOS 使用 IOKit 电源信息 API。

电池数据不是高精度遥测。它由系统按自己的粒度和频率上报。Apple 官方文档说明，电量变化通知最多约每分钟发送一次。没有电池的设备可能返回 `level=-1` 和 `state=unknown`。

官方文档：Android
[`Intent.ACTION_BATTERY_CHANGED`](https://developer.android.com/reference/android/content/Intent#ACTION_BATTERY_CHANGED)，iOS
[`UIDevice.batteryLevelDidChangeNotification`](https://developer.apple.com/documentation/uikit/uidevice/batteryleveldidchangenotification)，macOS
[`IOPowerSources.h`](https://developer.apple.com/documentation/iokit/iopowersources_h)。

`OrientationEvent`

Android 根据 display rotation 推导方向，并在配置变化时触发。iOS 监听设备方向变化通知。macOS 根据主屏幕尺寸推导方向，并在屏幕参数变化时触发。

方向可能是 `unknown`，尤其是在平台还没有稳定设备方向或屏幕方向时。macOS 上这是屏幕几何方向，不是设备物理旋转。

官方文档：Android
[`Display.getRotation`](<https://developer.android.com/reference/android/view/Display#getRotation()>)，iOS
[`UIDevice.orientationDidChangeNotification`](https://developer.apple.com/documentation/uikit/uidevice/orientationdidchangenotification)，macOS
[`NSApplication.didChangeScreenParametersNotification`](https://developer.apple.com/documentation/appkit/nsapplication/didchangescreenparametersnotification)。

`TimeEvent`

Android 监听系统时间、时区和日期广播。iOS 和 macOS 监听系统时间、时区和日历日期变化通知。

这不是定时器。它只报告系统暴露给 App 的时间、日期或时区变化，不会按分钟或固定间隔触发。

官方文档：Android
[`Intent.ACTION_TIME_CHANGED`](https://developer.android.com/reference/android/content/Intent#ACTION_TIME_CHANGED)，Android
[`Intent.ACTION_TIMEZONE_CHANGED`](https://developer.android.com/reference/android/content/Intent#ACTION_TIMEZONE_CHANGED)，iOS
[`UIApplication.significantTimeChangeNotification`](https://developer.apple.com/documentation/uikit/uiapplication/significanttimechangenotification)，Apple
[`NSSystemTimeZoneDidChange`](https://developer.apple.com/documentation/foundation/nsnotification/name/1414252-nssystemtimezonedidchange)。

`ScreenEvent`

Android 监听熄屏、亮屏、用户解锁广播，并观察 `Settings.System.SCREEN_BRIGHTNESS`。iOS 监听屏幕亮度变化，以及解锁后 protected data 变为可用的通知。

iOS 没有可靠的公开 App 级 API 可以直接监听熄屏/亮屏。亮度会归一化到 `0.0` 到 `1.0`；Android 系统亮度本身是整数值，不一定等同于人眼感知到的面板亮度。

官方文档：Android
[`Intent.ACTION_SCREEN_OFF`](https://developer.android.com/reference/android/content/Intent#ACTION_SCREEN_OFF)，Android
[`Settings.System.SCREEN_BRIGHTNESS`](https://developer.android.com/reference/android/provider/Settings.System#SCREEN_BRIGHTNESS)，iOS
[`UIScreen.brightnessDidChangeNotification`](https://developer.apple.com/documentation/uikit/uiscreen/brightnessdidchangenotification)，iOS
[`UIApplication.protectedDataDidBecomeAvailableNotification`](https://developer.apple.com/documentation/uikit/uiapplication/protecteddatadidbecomeavailablenotification)。

`ScreenshotEvent`

iOS 使用 `UIApplication.userDidTakeScreenshotNotification`。Android 使用 `Activity.registerScreenCaptureCallback`，该 API 仅 Android 14+（API 34+）可用，并要求宿主 App 在 manifest 中声明 `android.permission.DETECT_SCREEN_CAPTURE`。

事件不会包含截图图片。Android 13 及以下不支持这个事件。`DETECT_SCREEN_CAPTURE` 是安装时权限，不是运行时权限，因此不需要 `requestPermissions`。Android 在触发截屏检测时会显示系统提示。

官方文档：Android
[`Activity.registerScreenCaptureCallback`](<https://developer.android.com/reference/android/app/Activity#registerScreenCaptureCallback(java.util.concurrent.Executor,%20android.app.Activity.ScreenCaptureCallback)>)，Android
[`Manifest.permission.DETECT_SCREEN_CAPTURE`](https://developer.android.com/reference/android/Manifest.permission#DETECT_SCREEN_CAPTURE)，iOS
[`UIApplication.userDidTakeScreenshotNotification`](https://developer.apple.com/documentation/uikit/uiapplication/userdidtakescreenshotnotification)。

`ThermalEvent`

Android 使用 `PowerManager.OnThermalStatusChangedListener`，仅 Android 10+（API 29+）可用。iOS 使用 `ProcessInfo.thermalStateDidChangeNotification`。热状态事件流只上报变化；请使用 `currentThermal()` 读取当前热状态。

Android 9 及以下不支持这个事件。Android 和 iOS 都不需要权限。Android 原生热状态比 iOS 更多，因此部分状态会归一化到统一的 Dart enum。

官方文档：Android
[`PowerManager.OnThermalStatusChangedListener`](https://developer.android.com/reference/android/os/PowerManager.OnThermalStatusChangedListener)，iOS
[`ProcessInfo.thermalStateDidChangeNotification`](https://developer.apple.com/documentation/foundation/processinfo/thermalstatedidchangenotification)。

## 当前状态查询

| 方法 | Android | iOS | macOS | Windows | Linux | Web |
| --- | --- | --- | --- | --- | --- | --- |
| `currentNetwork()` | 支持 | 支持 | 支持 | 支持 | 不支持 | 支持 |
| `currentBattery()` | 支持 | 支持 | 支持 | 不支持 | 不支持 | 不支持 |
| `currentOrientation()` | 支持 | 支持 | 支持 | 不支持 | 不支持 | 不支持 |
| `currentScreenBrightness()` | 支持 | 支持 | 不支持 | 不支持 | 不支持 | 不支持 |
| `currentThermal()` | Android 10+ | 支持 | 不支持 | 不支持 | 不支持 | 不支持 |

## 平台支持

| 事件 | Android | iOS | macOS | Windows | Linux | Web |
| --- | --- | --- | --- | --- | --- | --- |
| `KeyboardEvent` | 支持 | 支持 | 部分支持 | 部分支持 | 努力实现中 | 支持 |
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
