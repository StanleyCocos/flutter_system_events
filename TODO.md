# TODO

## Goal
- Add screen events for Android and iOS in small, tested, independently committed steps.

## Acceptance Criteria
- [x] Dart exposes `ScreenConfig`, `ScreenEvent`, and `ScreenChange`.
- [x] `screen` is enabled by `SystemEventsConfig.defaults()` and `SystemEventsConfig.all()`.
- [x] Android emits screen off, screen on, unlocked, and brightness events.
- [x] iOS emits supported screen events: unlocked and brightness.
- [x] Every feature step has unit and integration coverage or a recorded platform limitation.
- [x] Tests pass before every feature commit.
- [x] Example and docs are committed separately from feature implementation.

## Tasks
- [x] 1. Initialize auto-iterator task files and commit the iteration plan.
- [x] 2. Add Dart screen event API, tests, run tests, commit.
- [x] 3. Add Android screen off event, tests, run tests, commit.
- [x] 4. Add Android screen on event, tests, run tests, commit.
- [x] 5. Add Android unlock event, tests, run tests, commit.
- [x] 6. Add Android brightness event, tests, run tests, commit.
- [x] 7. Add supported iOS screen events, tests or recorded limits, run tests, commit.
- [x] 8. Add example Screen page, widget/integration tests, run tests, commit.
- [x] 9. Update README docs, run tests, commit.
- [x] 10. Final review of TODO/LOG, run final verification, commit if task files changed.

## Current Step
- 当前执行：完成

## Blockers
- 无
