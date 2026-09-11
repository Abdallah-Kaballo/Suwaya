# Suwaya Architecture

## 1. Purpose

Suwaya is a Flutter application built around a pure Dart astronomical time engine. It combines prayer and solar calculations, a 48-Suwaya day model, tasks, routines, focus sessions, location, notifications, alarms, and localization.

The current implementation is local-first. Isar is the application data store, and the repository contains no active authentication or cloud synchronization layer. This document describes the architecture that exists today and the boundaries to preserve when extending it.

The detailed mathematical and behavioral reference for the time model is available in [Suwaya-Time.md](Suwaya-Time.md).

## 2. Architectural Principles

### 2.1 Local-first data

Tasks, routines, settings, and saved locations are read from and written to the local Isar database. Features should remain useful without a network connection. Do not introduce a remote source of truth unless the synchronization model, conflict behavior, privacy implications, and migrations are designed first.

### 2.2 Dependency injection through Riverpod

Shared infrastructure is exposed through Riverpod providers. Widgets must not create Isar instances, repositories, notification services, alarm services, or location services directly. The initialized Isar instance is supplied through `isarProvider`.

### 2.3 Feature-oriented organization

- `lib/core/` contains reusable infrastructure and application services.
- `lib/features/` contains user-facing screens, providers, and feature-specific widgets.
- `lib/models/` contains persistent Isar models and generated adapters.
- `lib/shared/` contains widgets reused by multiple features.
- `packages/suwaya_time/` contains pure Dart astronomical domain logic.

Keep a feature's screen, state, and feature-specific widgets together. Put code in `core` only when it is genuinely shared or infrastructure-oriented.

### 2.4 Pure domain logic

The `suwaya_time` package must remain independent of Flutter, Riverpod, `BuildContext`, localization, and platform APIs. It accepts explicit calculation inputs and returns domain models. This keeps calculations deterministic and testable in a Dart-only test environment.

### 2.5 Clear ownership

| Layer | Responsibility |
|---|---|
| Screen/widget | Rendering and user interaction |
| Provider/notifier | State orchestration and user actions |
| Repository | Isar reads and writes |
| Service | Platform or external API integration |
| Model | Persistent data structure |
| `suwaya_time` | Prayer, period, distribution, and virtual-time calculations |

Widgets must not contain raw database queries, persistence rules, or complex astronomical calculations.

## 3. Project Structure

```text
lib/
├── main.dart
├── core/
│   ├── astro_engine/       # Flutter state adapter for suwaya_time
│   ├── bootstrap/          # Early initialization
│   ├── database/           # Isar service and provider
│   ├── localization/       # Supported locales
│   ├── location/           # Location, geocoding, permissions
│   ├── notification/       # Notification service and scheduler
│   ├── providers/          # Shared UI providers
│   ├── repositories/       # Task, routine, and settings repositories
│   ├── router/             # go_router configuration
│   ├── services/           # Alarm integration
│   └── theme/              # Themes and domain-to-UI color adapters
├── features/
│   ├── alarm/
│   ├── home/
│   ├── ibadat/
│   ├── layout/
│   ├── onboarding/
│   ├── pomodoro/
│   ├── routines/
│   ├── settings/
│   ├── splash/
│   └── tasks/
├── models/
└── shared/widgets/
packages/suwaya_time/lib/
├── src/calculators/
├── src/engine/
├── src/generators/
└── src/models/
```

Generated `*.g.dart` files are produced by Isar's generator and must not be edited manually.

## 4. Application Startup

Startup is intentionally split so database opening does not block the first loading screen:

1. `main` awaits `AppBootstrap.initialize()`.
2. Flutter bindings and Easy Localization are initialized.
3. Global Flutter error handlers are registered.
4. Notification service and alarm support are initialized.
5. A lightweight `LoadingBootstrapScreen` is rendered.
6. `DatabaseService.init()` opens Isar and creates default settings when needed.
7. The resulting Isar instance is injected through `ProviderScope`.
8. `EasyLocalization` wraps `SuwayaApp`.
9. `MaterialApp.router` uses the Riverpod-provided `go_router` configuration.

Database failures are shown through a retryable bootstrap failure screen. New startup work should be idempotent and should not unnecessarily delay the first frame.

## 5. State Management

Riverpod is the state management solution.

- Use `Provider` for stateless services and repositories.
- Use `NotifierProvider` for state with mutations, such as settings, tasks, and the current astronomical state.
- Use `ref.watch` to rebuild widgets from state.
- Use `ref.read(...notifier)` to trigger actions.
- Keep providers independent of `BuildContext` where practical.
- Represent loading, empty, fallback, and error states explicitly.

`AstroNotifier` is the Flutter adapter around `SuwayaTimeEngine`. It watches calculation settings, generates or retrieves the active day, and exposes `AstroState` to the UI.

The astronomical state uses two timers with different responsibilities:

- A smart state timer wakes at the next Suwaya boundary and updates Riverpod state only when the period or Suwaya changes.
- A five-second display ticker updates `virtualTimeNotifier` for the formatted clock without forcing a full state rebuild.

Time-dependent features such as Pomodoro should consume the shared astronomical state, especially `suwayaProgress`, rather than creating an independent ticking clock.

## 6. Persistence

Isar Community is the local persistence layer. Current collections include tasks, settings, saved geographic data, and routines.

Rules:

- All writes occur inside `isar.writeTxn`.
- Access Isar through repositories or dedicated database services.
- Keep persistent fields stable and use explicit defaults.
- Do not store presentation-only state in models.
- Regenerate adapters after model changes with `build_runner`.
- Keep database initialization and default-settings creation in `DatabaseService`.

Repositories currently include task, routine, and settings persistence. Deletion behavior must match the model's intended lifecycle; the current task and routine repositories perform direct local deletion rather than a synchronization soft-delete protocol.

## 7. Astronomical Domain Package

`packages/suwaya_time` is a pure Dart package. Its public engine:

- Calculates prayer timings using `adhan`.
- Applies calculation method, Madhab, high-latitude rules, custom angles, timezone offset, and manual prayer offsets.
- Calculates night parts.
- Generates contiguous Fajr-to-next-Fajr periods.
- Distributes exactly 48 Suwayas across the day.
- Maps a generated day and a current time to `AstroState`, including current period, Suwaya, progress, and virtual time.

The Flutter layer supplies settings and location, then uses the returned models for rendering and scheduling. The package must not import Flutter or Riverpod.

Required invariants:

- Prayer times remain chronologically ordered.
- Periods are contiguous and cover Fajr to the following Fajr.
- The distribution totals 48 Suwayas.
- Night parts cover Maghrib to the next Fajr.
- Manual offsets affect only their selected prayer.

Changes to this package require focused tests for ordinary, high-latitude/polar, daylight-saving, leap-year, date-boundary, manual-offset, distribution, period-generation, and virtual-time cases where relevant.

## 8. Time and Date Rules

The application uses civil/local time for user-facing schedules and explicit UTC or location-aware values when calculating across timezones. A `DateTime`'s timezone meaning must be clear at every boundary.

The active astronomical day is selected relative to Fajr and the following Fajr. Location timezone changes must invalidate the calculation fingerprint and regenerate the day. Do not use the device's current time to reinterpret historical task or routine data.

## 9. Routing and Features

`go_router` owns navigation. The main shell uses `StatefulShellRoute.indexedStack` with four primary branches:

- `/tasks`
- `/ibadat`
- `/home`
- `/pomodoro`

Splash, onboarding, task creation, the astronomical timeline, and settings screens are routed outside the primary shell. Keep route arguments small and typed where possible; do not pass Isar objects between routes.

## 10. Platform Services

Platform APIs are wrapped by services and providers:

- `LocationService` and geocoding support active and saved locations.
- `NotificationService` and `SchedulerService` manage local notifications.
- `AlarmService` and the alarm feature handle alarm scheduling and ringing.
- Permission providers expose permission state to the UI.

Permission flows must handle denied, permanently denied, unsupported, and failed states. Scheduling should be idempotent so widget rebuilds do not create duplicate alarms or notifications.

## 11. Localization and UI

All user-visible text must use Easy Localization translation keys. Supported locales are defined in `AppLocales`, with Arabic as the fallback locale. UI must support RTL and LTR, light and dark themes, and long translations.

Keep UI focused on rendering and interaction. Use shared theme values and the `uiColor.adapt(context)` conversion when presenting astronomical domain colors. Custom dials and charts should receive prepared domain data instead of querying repositories.

## 12. Testing Requirements

The repository currently contains:

- Pure/domain tests for astronomy, periods, distribution, timezone behavior, and virtual-time mapping.
- Model and provider tests for task and settings behavior.
- Widget tests for application UI and bootstrap behavior.

Add regression coverage for bug fixes when practical. Run:

```bash
dart format .
flutter analyze
flutter test
```

## 13. Adding a Feature

1. Place user-facing code under `lib/features/<feature>`.
2. Add state and mutations to a provider or notifier.
3. Keep Isar access in a repository or database service.
4. Add localization keys for visible text.
5. Handle loading, empty, fallback, and error states.
6. Reuse the shared astronomical state for time-dependent behavior.
7. Add focused tests and check RTL/LTR plus light/dark themes.
8. Run formatting, analysis, and tests.

## 14. Definition of Done

A change is complete when its responsibilities remain in the correct layer, persistent writes are transactional, domain behavior has appropriate tests, user-visible text is localized, platform failures are handled, and `dart format`, `flutter analyze`, and `flutter test` pass.
