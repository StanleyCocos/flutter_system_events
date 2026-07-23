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
