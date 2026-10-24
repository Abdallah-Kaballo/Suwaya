# Suwaya Architecture

## 1. Purpose

Suwaya is an open-source Astro-Productivity Flutter application built around a pure Dart astronomical time engine (`packages/suwaya_time`). It unifies solar and prayer calculations, a V2 24-Suwaya Maghrib-to-Maghrib time model (12 Night Suwayas and 12 Day Suwayas, each representing 60 virtual minutes), casual tasks, continuous habits, routines, a dual-mode Pomodoro focus timer, a Hijri calendar with fasting recommendations, offline geolocation, notifications, full-screen lockscreen alarms, and 22-language localization.

The implementation is strictly local-first and privacy-focused. Isar Community serves as the primary read/write database for user data, while a bundled read-only SQLite database (`Cities_V2.db`) powers offline city search and reverse geocoding. The project contains no user accounts, cloud synchronization, or behavioral analytics.

For the mathematical and astronomical specification of the V2 time model (`scheduleModelVersion = 2`), see [Suwaya-Time.md](Suwaya-Time.md).

---

## 2. Architectural Principles

### 2.1 Local-First Persistence
Tasks, habits, routines, settings, and saved locations are persisted locally on the device using Isar Community. Offline city lookup and Haversine reverse geocoding run locally against `assets/db/Cities_V2.db` via `sqflite`. Dynamic documentation screens (FAQ and Privacy Policy) fetch JSON from the official GitHub repository with automatic local caching in `SharedPreferences` so they remain accessible offline.

### 2.2 Dependency Injection via Riverpod
Shared infrastructure is exposed through Riverpod providers. Widgets must not instantiate Isar, repositories, notification services, alarm services, or location services directly. During startup, the initialized `Isar` instance is injected into a `ProviderContainer` via `isarProvider.overrideWithValue(isar)` and supplied to the widget tree through an `UncontrolledProviderScope`.

### 2.3 Schema and Schedule Model Versioning (`MigrationService`)
Persistent scheduling models (`TaskModel` and `RoutineModel`) carry a `scheduleModelVersion` field (currently `2`). During application bootstrap—immediately after Isar initialization and before mounting the main UI—`MigrationService` inspects active tasks and routines. Any legacy V1 records (`scheduleModelVersion < 2`) are safely migrated to V2 defaults so user data is never lost across astronomical model upgrades.

### 2.4 Feature-Oriented Organization
- `lib/core/`: Reusable application services, database initialization, routing, localization, notifications, theme adapters, and repositories.
- `lib/features/`: Feature modules (`home`, `ibadat`, `tasks`, `routines`, `calendar`, `pomodoro`, `settings`, `onboarding`, `alarm`, `layout`) with their specific screens, providers, and custom painters.
- `lib/models/`: Persistent Isar collection/embedded models and generated `*.g.dart` adapters.
- `lib/shared/`: Cross-feature UI components (`AppDrawer`, `ClockTimeText`, `SuwayaTimeText`, `TaskCard`).
- `packages/suwaya_time/`: The pure Dart astronomical domain engine.

### 2.5 Pure Domain Logic
The `packages/suwaya_time` package is 100% pure Dart and depends only on `adhan`. It must never import Flutter, Riverpod, `BuildContext`, localization, or platform plugins. It accepts explicit coordinates, dates, calculation parameters, and manual offsets, returning deterministic domain models.

### 2.6 Layer Ownership

| Layer | Responsibility |
|---|---|
| **Screen / Widget / Painter** | UI rendering, hit-testing, gestures, and user interaction. |
| **Provider / Notifier** | Reactive state orchestration, caching, and business workflows. |
| **Repository** | Transactional Isar reads, queries, and writes. |
| **Service** | Platform/OS integration (Notifications, Alarms, SQLite Geo DB, Permissions, Migrations). |
| **Model** | Persistent Isar data structures and embedded objects. |
| **`suwaya_time`** | Prayer timings, Qiyam parts, 7 periods, 24-Suwaya distribution, and virtual time calculation. |

---

## 3. Project Structure

```text
lib/
├── main.dart
├── core/
│   ├── astro_engine/       # AstroNotifier & ValueNotifiers for live virtual time
│   ├── bootstrap/          # AppBootstrap early platform initialization
│   ├── database/           # DatabaseService & isarProvider
│   ├── localization/       # AppLocales (22 supported locales)
│   ├── location/           # GeoDatabaseService (SQLite), LocationService, PermissionsNotifier
│   ├── notification/       # NotificationService, NotificationScheduler (Isolate), RoutineTimeResolver
│   ├── providers/          # Shared UI state providers (e.g., isDrawerOpenProvider)
│   ├── repositories/       # TaskRepository, RoutineRepository, SettingsRepository
│   ├── router/             # go_router configuration & StartupGate
│   ├── services/           # AlarmService & MigrationService
│   ├── theme/              # AppTheme, ThemeColorNotifier, DialDesignNotifier, Astro UI extensions
│   └── utils/              # Civil & Suwaya time formatters and fixed astro mapping
├── features/
│   ├── alarm/              # Unified AlarmRingScreen (lockscreen & hardware buttons)
│   ├── calendar/           # CalendarScreen, Hijri & Gregorian dual view, Fasting rules
│   ├── home/               # HomeScreen, LocationHeader, PremiumAstroDial & custom painters
│   ├── ibadat/             # IbadatScreen & AstroTimelineScreen
│   ├── layout/             # MainLayout with glassmorphic floating bottom navigation bar
│   ├── onboarding/         # OnboardingLanguageScreen & OnboardingLocationScreen
│   ├── pomodoro/           # PomodoroScreen, PomodoroEngine (Traditional & Suwaya modes)
│   ├── routines/           # RoutinesNotifier & routineArcsProvider
│   ├── settings/           # Settings, AstroCalculations, ManualOffsets, Notifications, Support
│   └── tasks/              # TasksScreen, TasksNotifier, UniversalAddScreen & wheel pickers
├── models/                 # geo_models, routine_model, settings_model, task_model (+ .g.dart)
└── shared/widgets/         # Reusable application widgets
packages/suwaya_time/lib/
├── suwaya_time.dart
└── src/
    ├── calculators/        # prayer_calculator.dart, night_division.dart
    ├── engine/             # suwaya_time_engine.dart, temporal_context_engine.dart
    ├── generators/         # period_generator.dart, suwaya_distributor.dart
    └── models/             # astro_models.dart

```

---

## 4. Application Startup Sequence

Startup is decoupled into two stages so database initialization and data migrations never freeze the initial frame:

1. `main()` calls `WidgetsFlutterBinding.ensureInitialized()` and awaits `AppBootstrap.initialize()`.


2. `AppBootstrap` initializes `EasyLocalization`, registers `FlutterError.onError`, and initializes `NotificationService` and `Alarm.init()`.


3. `runApp(const LoadingBootstrapScreen())` renders a lightweight dark loading screen immediately.


4. `_loadDatabase()` opens Isar via `DatabaseService.init()` and ensures default settings exist.


5. A `ProviderContainer` is created with `isarProvider.overrideWithValue(isar)`.


6. `container.read(migrationServiceProvider).runMigrationsIfNeeded()` upgrades legacy records to `scheduleModelVersion = 2`.


7. The app mounts `UncontrolledProviderScope` -> `EasyLocalization` -> `SuwayaApp`.


8. `SuwayaApp` listens to `Alarm.ringStream` to push `AlarmRingScreen` over `rootNavigatorKey` whenever an alarm triggers.


9. Initial route `/startup` (`StartupGate`) awaits `settingsProvider.notifier.initialized` and redirects to `/onboarding` (if `isFirstLaunch == true`) or `/home`.


10. If Isar fails to open, `BootstrapFailureScreen` displays localized error details with a retry button.



---

## 5. State Management and Astronomical Runtime

Riverpod manages all application state:

* **`astroProvider` (`AstroNotifier`):**
* Watches a composite fingerprint of `settingsProvider` (active coordinates, timezone, calculation method, Madhab, high-latitude rule, custom angles, and manual offsets).


* Generates the astronomical cycle using `TemporalContextEngine`, anchoring correctly to today's or yesterday's Maghrib.


* **Smart State Timer (`_stateTimer`):** Sleeps until the exact microsecond of the next Suwaya transition.


* **UI Ticker (`_uiTimer`):** Ticks to update `virtualDateTimeNotifier` and `virtualTimeNotifier`, driving smooth needle movement on `PremiumAstroDial` without rebuilding the widget tree.




* **`settingsProvider` (`SettingsNotifier`):**
* Manages preferences, location selection, smart country defaults, global streak tracking, streak freezes, Hijri offsets, and night part mutual-exclusivity rules.




* **`tasksProvider` (`TasksNotifier`) & `routinesProvider` (`RoutinesNotifier`):**
* Partition active tasks into `nowTasks`, `todayTasks`, and `horizonTasks`. Support drag-and-drop rescheduling directly from the astronomical dial.




* **`pomodoroProvider` (`PomodoroEngine`):**
* Orchestrates both **Traditional Pomodoro** (customizable work/break cycles) and **Suwaya Pomodoro** (automatically dividing time between now and the next prayer into scaled 25/5 virtual Pomodoros).





---

## 6. Persistence and Offline Geolocation

### 6.1 Isar Community Collections

1. `TaskModel`: Casual tasks and recurring habits, completion history, streaks, dial visibility, and V2 astro/civil scheduling fields.


2. `RoutineModel`: Astro or civil time intervals, dial fill patterns, recurrence days, and alert configurations.


3. `SettingsModel`: Global preferences, embedded `SavedLocation`, and embedded `PeriodConfig` (alerts, sounds, manual offsets).


4. `GeoCountry`: Country metadata and default calculation parameters.



### 6.2 Offline SQLite City Database (`GeoDatabaseService`)

* Copies `assets/db/Cities_V2.db` to the application documents directory on first access and opens it in read-only mode via `sqflite`.


* Normalizes Arabic diacritics and administrative prefixes for clean city search.


* Provides offline reverse geocoding using a bounding-box SQL query followed by the Haversine distance formula to identify the nearest city without internet access.



---

## 7. Background Scheduling, Notifications, and Alarms

### 7.1 Isolate-Based 7-Day Scheduler (`NotificationScheduler`)

`notificationSchedulerProvider` listens to changes in tasks, routines, and settings with a debounce timer and state hash to prevent redundant rescheduling.

1. **Parallel Computation:** Spawns `Isolate.run` to compute `IbadatTimings` and periods for the next **7 days** off the UI thread.


2. **Deterministic ID Namespaces:** Prevents overlapping IDs across Prayers (100000+), Qiyam (200000+), Routines (300000+), and Tasks (400000+).


3. **Differential Cleanup:** Stops obsolete alarms via `Alarm.stop` and cancels outdated notifications via `NotificationService`.



### 7.2 Full-Screen Lockscreen Alarms

* **NotificationService:** Sweeps legacy channels and registers V3 Android channels using `AndroidScheduleMode.exactAllowWhileIdle`.


* **AlarmService & `AlarmRingScreen`:** Schedules full-screen alarms with audio fade-in. When ringing, it invokes a platform channel (`com.suwaya.app/lockscreen`) to wake the screen over the OS lockscreen. Supports interactive horizontal swipe-to-stop/snooze.



---

## 8. Routing and Navigation (`go_router`)

Defined in `lib/core/router/app_router.dart` using `rootNavigatorKey`:

* **Primary Shell (`StatefulShellRoute.indexedStack` -> `MainLayout`):**
1. `/tasks` (TasksScreen: Casual, Habits, Routines).


2. `/ibadat` (IbadatScreen: Next prayer countdown, 5 prayers, Qiyam parts).


3. `/home` (HomeScreen: Interactive `PremiumAstroDial`).


4. `/calendar` (CalendarScreen: Hijri/Civil dual calendar with agenda).


5. `/pomodoro` (PomodoroScreen: Dual-mode focus timer).




* **Full-Screen Root Routes:**
* `/startup`, `/onboarding`, `/add-task`, `/ibadat/timeline`, `/settings` (with nested routes like `notifications`, `astro`, `manual-offsets`), `/faq`, `/privacy`, `/support`.





---

## 9. Custom Painting and UI Rendering (`PremiumAstroDial`)

The astronomical dial is decomposed into layered `CustomPainter` classes wrapped in `RepaintBoundary` for optimal 60/120fps performance:

* **Static Layers:** `BackgroundPainter`, `IslamicRetePainter`, `RoutinesRingPainter`, `PeriodRingPainter`, `OuterRingPainter`, and `RailwayRingPainter` (collision-avoiding layout for markers).


* **Dynamic Layer:** `DynamicNeedlePainter` driven by `virtualDateTimeNotifier` and wrapped in `Transform.rotate` for auto-rotation or manual touch rotation with elastic snap-back.



---

## 10. Localization, Themes, and Verification

* **Localization:** 22 locales defined in `AppLocales` (with `ar` as fallback). Time displays enforce proper directional rendering (RTL/LTR) via `ClockTimeText` and `SuwayaTimeText`.


* **Themes:** 4 color palettes (Gold, Ocean, Forest, Desert) across `light`, `dark` (OLED), `system`, and `mixed` (auto-switches based on the sun's position).



Before opening a pull request or releasing a build, verify:

```bash
dart run build_runner build --delete-conflicting-outputs
dart format .
flutter analyze
flutter test

