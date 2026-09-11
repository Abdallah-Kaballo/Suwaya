# Suwaya Architecture

## 1. Purpose

Suwaya is a Flutter application that combines:

- Astronomical and Islamic prayer time calculations.
- The Suwaya time system divided into 48 daily Suwayas.
- Task, routine, worship, and productivity management.
- Offline-first local storage.
- Optional cloud synchronization.
- Localization and RTL/LTR support.
- Notifications, alarms, location, and background services.

This document defines the architectural rules and conventions that must be followed when adding or modifying features.

---

## 2. Architectural Principles

### 2.1 Offline-first

Local data is the primary source of truth during normal application usage.

Features must continue to work when:

- The device has no network connection.
- Supabase is unavailable.
- The user is not authenticated.
- Location permissions are unavailable.

Cloud synchronization is an enhancement, not a requirement for the core user experience.

### 2.2 Explicit dependency injection

Shared services and infrastructure dependencies must be provided through Riverpod.

Do not create database, authentication, synchronization, or notification service instances directly inside widgets.

The Isar instance is initialized during application bootstrap and injected through `isarProvider`.

### 2.3 Feature-oriented organization

Code belongs in one of the following locations:

- `lib/core/`: reusable infrastructure and domain services.
- `lib/features/`: user-facing features and feature-specific state.
- `lib/models/`: persistent Isar models.
- `lib/shared/`: reusable widgets and UI components.

A feature should keep its screen, provider, state, and feature-specific widgets together whenever practical.

### 2.4 Pure domain logic

Calculations that do not require Flutter should remain independent of Flutter.

The astronomical engine must not depend on:

- `BuildContext`.
- Flutter widgets.
- Riverpod.
- Platform-specific APIs.
- Localization delegates.

This allows the engine to be tested independently and executed in an isolate when necessary.

### 2.5 Clear ownership

Each layer has one responsibility:

| Layer | Responsibility |
|---|---|
| Screen/widget | Rendering and user interaction |
| Provider/notifier | State orchestration and user actions |
| Repository | Reading and writing application data |
| Service | External systems and platform APIs |
| Model | Persistent data structure |
| Domain engine | Deterministic business calculations |

Widgets should not contain database queries or synchronization rules.

---

## 3. Project Structure

```text
lib/
├── main.dart
├── firebase_options.dart
├── core/
│   ├── astro_engine/
│   ├── bootstrap/
│   ├── database/
│   ├── localization/
│   ├── location/
│   ├── notification/
│   ├── repositories/
│   ├── router/
│   ├── services/
│   ├── sync/
│   ├── theme/
│   └── utils/
├── features/
│   ├── alarm/
│   ├── analytics/
│   ├── auth/
│   ├── home/
│   ├── ibadat/
│   ├── layout/
│   ├── onboarding/
│   ├── pomodoro/
│   ├── routines/
│   ├── settings/
│   ├── splash/
│   ├── stats/
│   └── tasks/
├── models/
└── shared/
    └── widgets/

```

### `core`

Contains application-wide infrastructure, services, and domain logic.

Examples:

* Database initialization.
* Location services.
* Notifications.
* Authentication.
* Synchronization.
* Astronomical calculations.
* Theme and localization configuration.

### `features`

Contains user-facing application functionality.

A feature may contain:

* Screen widgets.
* Providers.
* State classes.
* Feature-specific UI widgets.
* Feature-specific helpers.

A feature must not access Supabase, Isar, or platform APIs directly when a core service or repository already exists.

### `models`

Contains Isar persistence models and generated files.

Generated files such as `*.g.dart` must not be edited manually.

### `shared`

Contains UI components used by more than one feature.

A widget belongs in `shared` only when it is genuinely reusable. Feature-specific widgets should remain inside their feature.

---

## 4. Application Startup

Application startup follows this sequence:

1. Flutter bindings are initialized.
2. Time zones and error handlers are configured.
3. Alarm services are initialized.
4. Isar is opened through `DatabaseService`.
5. Localization, and date formatting are initialized.
6. Background services are initialized.
7. The Isar instance is injected into `ProviderScope`.
8. `EasyLocalization` wraps the application.
9. `SuwayaApp` is rendered via `go_router`.
10. Background synchronization begins through `GlobalSyncWrapper`.

Startup failures must display a recoverable failure screen and must be reported through Crashlytics in release builds.

New startup work must be:

* Idempotent.
* Safe to execute more than once.
* Isolated from the first frame whenever possible.
* Protected from blocking the UI unnecessarily.

---

## 5. State Management

Riverpod is the standard state management solution.

Use:

* `Provider` for stateless services and repositories.
* `FutureProvider` for asynchronous read operations.
* `StreamProvider` for streams such as authentication state.
* `NotifierProvider` for feature state with mutations.
* `StateNotifierProvider` only where the existing implementation already uses it or where its semantics are required.

State rules:

* Widgets read state with `ref.watch`.
* Widgets trigger actions through `ref.read(...notifier)`.
* Business mutations belong in notifiers or repositories.
* Providers must not depend on `BuildContext`.
* Avoid duplicating the same source of truth in multiple providers.
* Loading, success, empty, and error states must be represented explicitly.

---

## 6. Database Rules

Isar is the local persistence layer.

All database writes must occur inside `isar.writeTxn`.

Persistent models must:

* Have stable fields.
* Use explicit defaults where appropriate.
* Define indexes for frequently queried fields.
* Avoid storing presentation-only values.
* Preserve backward compatibility when fields are renamed or removed.

Generated Isar files must be regenerated with the project build command and never edited manually.

The database must be accessed through repositories or dedicated services. Screens should not execute raw Isar queries.

### Database fallback

Any fallback schema must include every model required by the application. When adding a new collection, update:

* The primary Isar schema.
* The fallback schema.
* Migration or compatibility logic.
* Tests covering opening and reading the database.

---

## 7. Data Synchronization

Synchronization is based on:

* A stable `syncId`.
* `updatedAt`.
* `isSynced`.
* `isDeleted`.
* User ownership in Supabase.

Local changes are written first and marked as unsynced. Synchronization then:

1. Pulls remote changes.
2. Applies newer remote records locally.
3. Pushes unsynced local records.
4. Marks successfully uploaded records as synced.
5. Stores the last successful synchronization timestamp.

Synchronization must never delete local data merely because the network request failed.

Soft deletion must be used for records that need to be synchronized across devices.

All timestamps exchanged with the backend must be normalized to UTC.

The application currently triggers synchronization:

* At application startup.
* When returning from the background.
* After relevant authentication events.

A feature must not assume that synchronization is immediate.

---

## 8. Astronomical Engine

The astronomical engine is a pure Dart domain layer.

Its responsibilities include:

* Prayer time calculations.
* High-latitude handling.
* Madhab selection.
* Manual prayer offsets.
* Night-part calculations.
* Suwaya distribution.
* Daily period generation.

Important invariants:

* Prayer times must remain chronologically ordered.
* Night parts must cover the interval from Maghrib to the next Fajr.
* Daily periods must be contiguous.
* The total Suwaya distribution must equal 48.
* Manual offsets must affect only the selected prayer.
* Generated periods must cover the actual interval from Fajr to the next Fajr.

Long-running annual calculations should use the asynchronous isolate-based API.

Changes to the astronomical engine must include tests for:

* Normal locations.
* High-latitude locations.
* Manual offsets.
* Time-zone offsets.
* Leap years and date boundaries.
* The Fajr-to-Fajr period interval.
* The 48-Suwaya invariant.

---

## 9. Time and Date Rules

The application uses multiple concepts of time:

* Civil time.
* Local astronomical time.
* UTC timestamps for synchronization and event logs.
* The active Islamic/productivity day.
* Suwaya and period boundaries.

These concepts must not be mixed implicitly.

Rules:

* Use UTC for cloud synchronization fields.
* Use local time for user-facing schedules.
* Store the active day explicitly when calculating statistics.
* Do not derive historical statistics from the current device time.
* Always document whether a `DateTime` is UTC or local.
* Be careful when comparing dates across daylight-saving or travel changes.
* **Single Source of Truth:** Time-dependent features (like Pomodoro) must **not** run their own independent `Timer.periodic`. They must passively listen to `AstroState.suwayaProgress` to prevent desync and battery drain.

---

## 10. Localization

All user-visible text must be localized.

Rules:

* Do not hardcode user-facing strings in widgets.
* Add translation keys to the translation files.
* Keep translation keys stable.
* Support both RTL and LTR layouts.
* Avoid assumptions about text width.
* Test long translations and languages with different word lengths.
* Do not use translated display text as a database identifier.

Enums and domain values must use stable internal names. Their labels should be resolved through localization.

---

## 11. Navigation

The application uses `go_router` for state-driven routing and deep linking, implementing `StatefulShellRoute.indexedStack` to maintain tab states seamlessly across the primary layout.

Navigation rules:

* Use `context.go` or `context.push` via `go_router`.
* Keep route arguments typed.
* Avoid passing database objects across routes.
* Handle `context.mounted` after awaited operations.
* Keep navigation decisions out of repositories and pure domain services.

---

## 12. Notifications, Alarms, and Permissions

Platform services must be accessed through dedicated services.

Screens may request a permission through a provider or service, but must not contain platform-specific implementation details.

Permission flows must handle:

* Permission not requested.
* Permission denied.
* Permission permanently denied.
* Unsupported platform behavior.
* User cancellation.
* Missing exact-alarm permission.
* Notification scheduling failure.

Scheduling must be idempotent. Rebuilding a widget must not create duplicate notifications or alarms.

---

## 13. UI Rules

UI code should:

* Stay focused on rendering and interaction.
* Use shared theme values.
* Support light and dark themes.
* Support RTL and LTR.
* Handle loading, empty, and error states.
* Avoid direct database access.
* Avoid complex calculations inside `build`.
* Use stable keys for dynamic lists.
* Keep reusable widgets small and focused.
* **Color Adaptation:** Always use the `.uiColor.adapt(context)` extension when accessing `AstroPeriod` colors in the UI to maintain domain purity.

Custom astronomical dials and charts should receive prepared data rather than querying repositories internally.

---

## 14. Error Handling and Observability

Expected failures should be represented in application state and shown with a useful user-facing message.

Unexpected failures must:

* Preserve the application from crashing where possible.
* Include enough context for diagnosis.
* Be reported to Crashlytics in release builds.
* Avoid exposing secrets or private user data.

Do not log:

* Access tokens.
* Supabase keys.
* Private user information.
* Full synchronization payloads.
* Sensitive location data unless necessary for debugging.

---

## 15. Testing Requirements

Tests must be added according to risk.

### Domain tests

Required for:

* Astro calculations.
* Suwaya distribution.
* Period boundaries.
* Date and time behavior.
* Manual offsets.

### Repository tests

Required for:

* CRUD behavior.
* Soft deletion.
* Sync flags.
* Migration behavior.
* Empty database initialization.

### Provider tests

Required for:

* State transitions.
* Loading and error states.
* Mutation behavior.
* Dependency failures.

### Widget tests

Required for important flows such as:

* Onboarding.
* Adding a task.
* Completing a task.
* Changing settings.
* Permission-related screens.

Every bug fix should include a regression test when practical.

---

## 16. Adding a New Feature

When adding a feature:

1. Create a directory under `lib/features`.
2. Define the feature state and provider.
3. Keep persistence access in a repository or service.
4. Add localization keys.
5. Add loading, empty, and error states.
6. Add tests for the feature's core behavior.
7. Check RTL and LTR layouts.
8. Check light and dark themes.
9. Check offline behavior.
10. Check synchronization behavior if the feature stores user data.
11. Run formatting, analysis, and tests.

---

## 17. Dependency Rules

Before adding a package:

* Confirm that an existing package does not already solve the problem.
* Check platform support.
* Check maintenance status.
* Check license compatibility.
* Consider application size and startup cost.
* Add the dependency to the correct section of `pubspec.yaml`.
* Document important architectural consequences.

Infrastructure packages should not be imported into pure domain code.

---

## 18. Code Quality

Before submitting changes, run:

```bash
dart format .
flutter analyze
flutter test

```

Generated code must be regenerated when models change.

A change is not complete until:

* The code is formatted.
* Static analysis passes.
* Relevant tests pass.
* New behavior is documented where necessary.
* No secrets are committed.
* Platform-specific behavior has been checked.

---

## 19. Architectural Risks to Track

The following items should be reviewed as the project grows:

* Synchronization is lifecycle-triggered rather than realtime.
* Pull synchronization currently needs explicit coverage for every synchronized model.
* Fallback database schemas must remain aligned with the primary schema.
* Date/time semantics should be documented consistently across all models.
* Repositories should remain the single access point for persistent data.
* Generated Isar files must never be edited manually.

---

## 20. Definition of Done

A feature is considered complete when:

* Its responsibilities are placed in the correct layer.
* It works without network access where applicable.
* It handles loading, empty, and error states.
* It supports localization and RTL/LTR.
* It supports light and dark themes.
* It does not duplicate an existing source of truth.
* It has appropriate tests.
* It passes formatting, analysis, and test commands.
* Its synchronization and migration behavior are documented.

```