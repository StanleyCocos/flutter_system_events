## 1.2.1

- Fixed Android release builds by avoiding duplicate Kotlin source registration.

## 1.2.0

- Added Windows lifecycle events.
- Added Windows current network state and network events.
- Added Windows CI build checks.

## 1.1.0

- Added macOS lifecycle, network, battery, orientation, and time events.
- Added macOS current network, battery, and orientation queries.
- Documented macOS battery and orientation behavior.
- Updated the macOS support matrix.

## 1.0.0

- Added screenshot events on iOS and Android 14+.
- Added thermal events on iOS and Android 10+.
- Added example pages, tests, and docs for screenshot and thermal events.
- Documented platform support and permission behavior for screenshot and thermal events.

## 0.8.0

- Added typed event streams on `SystemEvents`.
- Added current network, battery, orientation, and screen brightness queries.
- Added runtime event configuration helpers.
- Added Windows keyboard event support.
- Updated the example app and README usage docs.

## 0.7.0

- Added screen events.
- Added Android screen off, screen on, unlock, and brightness events.
- Added iOS unlock and brightness events.
- Added a screen event page to the example app.

## 0.6.0

- Added Android and iOS time change events.
- Added a time event page to the example app.

## 0.5.0

- Added Android and iOS orientation events.
- Added an orientation event page to the example app.

## 0.4.0

- Added `UnknownSystemEvent` for unsupported or malformed event payloads.
- Kept the event stream alive when native events cannot be parsed.
- Documented robust event parsing behavior.

## 0.3.0

- Added configurable event initialization.
- Added Android and iOS battery events.
- Added web keyboard, lifecycle, and network events.
- Updated the example app with a battery event page.

## 0.2.0

- Fixed Android package namespace.
- Added `SystemEvents.dispose()`.
- Improved README.
- Improved example event pages.
- Added Android and iOS network events.
- Added Android and iOS memory events.
- Kept non-Android and non-iOS platforms as no-op implementations.

## 0.0.1

- Initial release.
- Added `SystemEvents.initialize()` and `SystemEvents.events`.
- Added Android and iOS keyboard events.
- Added Android and iOS lifecycle events.
- Added example pages for testing keyboard and lifecycle events.
