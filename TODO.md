# TODO

## Goal
- Add screen events for Android and iOS in small, tested, independently committed steps.

## Acceptance Criteria
- [ ] Dart exposes `ScreenConfig`, `ScreenEvent`, and `ScreenChange`.
- [ ] `screen` is enabled by `SystemEventsConfig.defaults()` and `SystemEventsConfig.all()`.
- [ ] Android emits screen off, screen on, unlocked, and brightness events.
- [ ] iOS emits supported screen events: unlocked and brightness.
- [ ] Every feature step has unit and integration coverage or a recorded platform limitation.
- [ ] Tests pass before every feature commit.
- [ ] Example and docs are committed separately from feature implementation.

## Tasks
- [x] 1. Initialize auto-iterator task files and commit the iteration plan.
- [x] 2. Add Dart screen event API, tests, run tests, commit.
- [ ] 3. Add Android screen off event, tests, run tests, commit.
- [ ] 4. Add Android screen on event, tests, run tests, commit.
- [ ] 5. Add Android unlock event, tests, run tests, commit.
- [ ] 6. Add Android brightness event, tests, run tests, commit.
- [ ] 7. Add supported iOS screen events, tests or recorded limits, run tests, commit.
- [ ] 8. Add example Screen page, widget/integration tests, run tests, commit.
- [ ] 9. Update README docs, run tests, commit.
- [ ] 10. Final review of TODO/LOG, run final verification, commit if task files changed.

## Current Step
- 当前执行：3. Add Android screen off event, tests, run tests, commit.

## Blockers
- 无
