# Suwaya Architecture

## 1. Purpose

Suwaya is an open-source Astro-Productivity Flutter application built around a pure Dart astronomical time engine (`packages/suwaya_time`)[cite: 1, 3]. It unifies solar and prayer calculations, a 24-Suwaya Maghrib-to-Maghrib time model (12 Night Suwayas and 12 Day Suwayas, each representing 60 virtual minutes), casual tasks, continuous habits, routines, dual-mode Pomodoro focus sessions, offline geolocation, notifications, full-screen lockscreen alarms, and 22-language localization[cite: 1, 2, 3].

The implementation is strictly local-first and privacy-focused[cite: 3]. Isar Community (`isar_community`) serves as the primary read/write database for user data, while a bundled read-only SQLite database (`Cities_V2.db`) powers offline city search and reverse geocoding[cite: 1, 3]. The project contains no user accounts, cloud synchronization, or behavioral analytics[cite: 3].

For the mathematical and astronomical specification of the V2 time model (`scheduleModelVersion = 2`), see [Suwaya-Time.md](Suwaya-Time.md)[cite: 1, 3].

---

## 2. Architectural Principles

### 2.1 Local-First Persistence

Tasks, habits, routines, settings, and saved locations are persisted locally on the device using Isar Community[cite: 1, 3]. Offline city lookup and Haversine reverse geocoding run locally against `assets/db/Cities_V2.db` via `sqflite`[cite: 1]. Dynamic documentation screens (FAQ and Privacy Policy) fetch JSON from the official GitHub repository with automatic local caching in `SharedPreferences` so they remain accessible offline[cite: 2].

### 2.2 Dependency Injection via Riverpod

Shared infrastructure is exposed through Riverpod providers[cite: 1, 3]. Widgets must not instantiate Isar, repositories, notification services, alarm services, or location services directly[cite: 3]. During startup, the initialized `Isar` instance is injected into a `ProviderContainer` via `isarProvider.overrideWithValue(isar)` and supplied to the widget tree through `UncontrolledProviderScope`[cite: 1].

### 2.3 Schema and Schedule Model Versioning (`MigrationService`)

Persistent scheduling models (`TaskModel` and `RoutineModel`) carry a `scheduleModelVersion` field (currently `2`)[cite: 3]. During application bootstrap—immediately after Isar initialization and before mounting the main UI—`MigrationService` inspects active tasks and routines[cite: 1]. Any legacy V1 records (`scheduleModelVersion < 2`) are safely migrated to V2 defaults so user data is never lost across astronomical model upgrades[cite: 1].

### 2.4 Feature-Oriented Organization

- `lib/core/` contains reusable application services, database initialization, routing, localization, notifications, theme adapters, and repositories[cite: 1, 3].
- `lib/features/` contains feature modules (`home`, `ibadat`, `tasks`, `routines`, `pomodoro`, `settings`, `onboarding`, `alarm`, `layout`) with their screens, providers, and custom painters/widgets[cite: 1, 3].
- `lib/models/` contains persistent Isar collection/embedded models and generated `*.g.dart` adapters[cite: 1, 3].
- `lib/shared/` contains cross-feature UI components (`AppDrawer`, `ClockTimeText`, `SuwayaTimeText`, `TaskCard`)[cite: 1, 3].
- `packages/suwaya_time/` contains the pure Dart astronomical domain engine[cite: 1, 3].

### 2.5 Pure Domain Logic

The `packages/suwaya_time` package is 100% pure Dart and depends only on `adhan`[cite: 3]. It must never import Flutter, Riverpod, `BuildContext`, localization, or platform plugins[cite: 3]. It accepts explicit coordinates, dates, calculation parameters, and manual offsets, returning deterministic domain models[cite: 1, 3].

### 2.6 Layer Ownership

| Layer | Responsibility |
|---|---|
| Screen / Widget / Painter | UI rendering, hit-testing, gestures, and user interaction[cite: 1, 3] |
| Provider / Notifier | Reactive state orchestration, caching, and business workflows[cite: 1, 2, 3] |
| Repository | Transactional Isar reads, queries, and writes[cite: 1, 3] |
| Service | Platform/OS integration (Notifications, Alarms, SQLite Geo DB, Permissions, Migrations)[cite: 1, 3] |
| Model | Persistent Isar data structures and embedded objects[cite: 2, 3] |
| `suwaya_time` | Prayer timings, second-half Qiyam parts, 7 periods, 24-Suwaya distribution, and virtual time[cite: 1, 3] |

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
│   ├── home/               # HomeScreen, LocationHeader, MiniAstroDial, PremiumAstroDial & painters
│   ├── ibadat/             # IbadatScreen & AstroTimelineScreen
│   ├── layout/             # MainLayout with glassmorphic floating bottom navigation bar
│   ├── onboarding/         # OnboardingLanguageScreen & OnboardingLocationScreen
│   ├── pomodoro/           # PomodoroScreen, PomodoroEngine, SuwayaAstrolabeTimer
│   ├── routines/           # RoutinesNotifier & routineArcsProvider
│   ├── settings/           # SettingsScreen, AstroCalculations, ManualOffsets, Notifications, FAQ, Privacy, Support
│   └── tasks/              # TasksScreen, TasksNotifier, UniversalAddScreen & wheel pickers
├── models/                 # geo_models, routine_model, settings_model, task_model (+ .g.dart)
└── shared/widgets/         # app_drawer, suwaya_time_text, task_card
packages/suwaya_time/lib/
├── suwaya_time.dart
└── src/
    ├── calculators/        # prayer_calculator.dart, night_division.dart
    ├── engine/             # suwaya_time_engine.dart
    ├── generators/         # period_generator.dart, suwaya_distributor.dart
    └── models/             # astro_models.dart

```

Generated `*.g.dart` files are produced by `isar_community_generator` and must not be edited manually.

---

## 4. Application Startup Sequence

Startup is decoupled into two stages so database initialization and data migrations never freeze the initial frame:

1. `main()` calls `WidgetsFlutterBinding.ensureInitialized()` and awaits `AppBootstrap.initialize()`.


2. `AppBootstrap` initializes `EasyLocalization`, registers `FlutterError.onError` and `PlatformDispatcher.instance.onError`, and initializes `NotificationService` (including V3 Android notification channel sweeping) and `Alarm.init()`.


3. `runApp(const LoadingBootstrapScreen())` renders a lightweight dark loading screen immediately.


4. `_LoadingBootstrapScreenState._loadDatabase()` opens Isar via `DatabaseService.init()` and ensures default settings (`id = 1`) exist.


5. A `ProviderContainer` is created with `isarProvider.overrideWithValue(isar)`.


6. `container.read(migrationServiceProvider).runMigrationsIfNeeded()` upgrades any V1 tasks or routines to `scheduleModelVersion = 2`.


7. The app mounts `UncontrolledProviderScope` -> `EasyLocalization` -> `SuwayaApp`.


8. `SuwayaApp` listens to `Alarm.ringStream.stream` to push `AlarmRingScreen` over `rootNavigatorKey` whenever an alarm triggers, and configures `MaterialApp.router` with `goRouter`.


9. Initial route `/startup` (`StartupGate`) awaits `settingsProvider.notifier.initialized` and redirects to `/onboarding` (if `isFirstLaunch == true`) or `/home`.


10. If Isar fails to open, `BootstrapFailureScreen` displays localized error details with a retry button.



---

## 5. State Management and Astronomical Runtime

Riverpod manages all application state:

* **`astroProvider` (`AstroNotifier`):**
* Watches a composite fingerprint of `settingsProvider` (active coordinates, timezone, calculation method, Madhab, high-latitude rule, custom Fajr/Isha angles, and manual prayer offsets).


* Evaluates `tempIbadat.maghrib` for the active city's current time (`_getCityNow`). If `cityNow` is before today's Maghrib, it generates the cycle anchored to yesterday's Maghrib; otherwise, it anchors to today's Maghrib.


* Maintains an in-memory cache (`_dayCache`, max 3 entries) of `SuwayaDay` objects.


* **Smart State Timer (`_stateTimer`):** Sleeps until the exact microsecond of the next Suwaya transition (or `cycleEndMaghrib` to invalidate and roll over the cycle), updating Riverpod state only when `currentPeriod.id` or `periodLocalSlotNumber` changes.


* **UI Ticker (`_uiTimer`):** Ticks every 1 second to update `virtualDateTimeNotifier` and `virtualTimeNotifier`, driving smooth needle movement on `PremiumAstroDial` and live digital clocks without rebuilding the widget tree.




* **`settingsProvider` (`SettingsNotifier`):**
* Manages user preferences, location selection, smart country astro defaults (`AstroSmartDefaults`), global streak tracking, streak freezes (`validateAndApplyStreakFreezes`), and mutual-exclusivity rules for second-half night parts (`toggleVisibleNightPart` and `toggleNightMarker`).




* **`tasksProvider` (`TasksNotifier`) & `routinesProvider` (`RoutinesNotifier`):**
* Partition active tasks into `nowTasks`, `todayTasks`, and `horizonTasks`, support drag-and-drop rescheduling directly from the astronomical dial (`rescheduleTask`), and compute `RoutineArcData` angles for `RoutinesRingPainter`.




* **`pomodoroProvider` (`PomodoroEngine`):**
* Orchestrates both **Traditional Pomodoro** (customizable work `25..60m`, short break `5/10m`, long break `20..40m`, and cycles `1..6` persisted in `SharedPreferences`) and **Suwaya Pomodoro** (anchored start time, next-prayer or custom end time between `15m` and `12h`, automatic `25/5` virtual Pomodoro division with `0.5x..2.0x` flow speed options, setup-time deduction from the first Pomodoro, and mandatory stop at prayer time).





---

## 6. Persistence and Offline Geolocation

### 6.1 Isar Community Collections

Initialized in `DatabaseService.init()`:

1. `TaskModel`: Casual tasks (`TaskType.casual`) and recurring habits (`TaskType.permanent`), completion history, streaks, category neon colors, dial visibility, and V2 astro/civil scheduling fields.


2. `RoutineModel`: Astro or civil time intervals, dial fill patterns (`linear`, `hexagon`, `stone`, `trihex`), recurrence days, and alert configurations.


3. `SettingsModel`: Global preferences, embedded `SavedLocation` (active and saved list), and embedded `PeriodConfig` list (per-period alert level, sound, volume, and manual offset minutes).


4. `GeoCountry`: Country metadata and default calculation parameters.



### 6.2 Offline SQLite City Database (`GeoDatabaseService`)

* Copies `assets/db/Cities_V2.db` to the application documents directory on first access and opens it in read-only mode via `sqflite`.


* Normalizes Arabic diacritics and administrative prefixes (`محافظة`, `مدينة`, `Governorate`, etc.) for clean city search.


* Provides offline reverse geocoding (`getNearestLocationData`) using a bounding-box SQL query (`±2.0°` lat/lng) followed by the Haversine distance formula (`calculateDistance`) to identify the nearest city and country code without internet access.



---

## 7. Background Scheduling, Notifications, and Alarms

### 7.1 Isolate-Based 7-Day Scheduler (`NotificationScheduler`)

`notificationSchedulerProvider` listens to changes in `tasksProvider`, `routinesProvider`, and relevant fields of `settingsProvider` with a 1,000ms debounce timer and a state hash (`_lastScheduleHash`) to prevent redundant rescheduling.

When a schedule update is required:

1. **Parallel Isolate Computation:** Spawns `Isolate.run` to compute `IbadatTimings` and `SuwayaTimeEngine.generateDay` periods for the next **7 days** off the UI thread.


2. **Deterministic ID Namespaces:**
* Mandatory Prayers (`Fajr`, `Dhuhr`, `Asr`, `Maghrib`, `Isha`): `100000 + (dayOffset * 1000) + numericId`.


* Qiyam Night Parts (`half_2`, `third_3`, `sixth_4`, `sixth_5`, `sixth_6`): `200000 + (dayOffset * 1000) + nightIdSafe`.


* Routines: `300000 + (dayOffset * 10000) + routine.id`.


* Tasks & Habits: `400000 + (dayOffset * 10000) + ((task.id % 1000) * 10) + effectiveSuwayaNum`.




3. **Differential Cleanup:** Stops obsolete alarms via `Alarm.stop` and cancels outdated notifications via `NotificationService.cancel`.



### 7.2 Notification Channels and Full-Screen Lockscreen Alarms

* **NotificationService (`flutter_local_notifications`):** Sweeps legacy V2 channels and registers V3 Android channels (`suwaya_system_standard_v3`, `suwaya_system_alarm_v3`, `suwaya_system_vibrate_v3`) using `AndroidScheduleMode.exactAllowWhileIdle`.


* **AlarmService & `AlarmRingScreen` (`alarm`):**
* Alert level `2` schedules full-screen alarms with `VolumeSettings.fade`.


* When ringing, `SuwayaApp` pushes `AlarmRingScreen`, which invokes `MethodChannel('com.suwaya.app/lockscreen')` (`showOnLockScreen` / `hideFromLockScreen`) in `MainActivity.kt` to wake the screen over the OS lockscreen.


* Supports interactive horizontal swipe-to-stop / swipe-to-snooze and hardware volume button snoozing up to `maxSnoozeCount`.





---

## 8. Routing and Navigation (`go_router`)

Defined in `lib/core/router/app_router.dart` using `rootNavigatorKey`:

* **Primary Shell (`StatefulShellRoute.indexedStack` -> `MainLayout`):**
1. `/tasks` (`TasksScreen`: Casual Tasks, Continuous Habits, and Routines tabs).


2. `/ibadat` (`IbadatScreen`: Next prayer countdown, 5 prayers, sunrise toggle, and 5 Qiyam night parts).


3. `/home` (`HomeScreen`: Hijri night/day header, `MiniAstroDial`, interactive `PremiumAstroDial`, and dial indicators legend).


4. `/pomodoro` (`PomodoroScreen`: Suwaya Pomodoro & Traditional Pomodoro).




* **Full-Screen Root Routes:**
* `/startup` (`StartupGate`)


* `/onboarding` (`OnboardingLanguageScreen`) & `/onboarding-location` (`OnboardingLocationScreen`)


* `/add-task` (`UniversalAddScreen`)


* `/ibadat/timeline` (`AstroTimelineScreen`)


* `/settings` (`SettingsScreen`) with sub-routes: `notifications`, `astro`, `permissions`, `manual-offsets`

* `/faq` (`FAQScreen`), `/privacy` (`PrivacyScreen`), `/support` (`SupportScreen`)





---

## 9. Custom Painting and UI Rendering (`PremiumAstroDial`)

The astronomical dial in `lib/features/home/widgets/` is decomposed into layered `CustomPainter` classes wrapped in `RepaintBoundary` for 60/120fps performance:

* Static/Semi-Static Layers (`heavyDialStack`): `BackgroundPainter`, `IslamicRetePainter` / `GeometricRetePainter`, `RoutinesRingPainter`, `PeriodRingPainter`, `OuterRingPainter` (supports `suwaya48`/`24` pins and `civil24` pins), `CrownPainter` (Maghrib crown marker), `DividerRingPainter`, and `RailwayRingPainter` (3-track collision-avoiding layout for prayer markers and task arrows).


* Dynamic Layer: `DynamicNeedlePainter` driven by `virtualDateTimeNotifier` and wrapped in `Transform.rotate` for auto-rotation or manual touch rotation with elastic snap-back.



---

## 10. Localization, Themes, and Verification

* **Localization:** 22 locales defined in `AppLocales` (`ar`, `en`, `tr`, `ru`, `ur`, `hi`, `bn`, `th`, `ja`, `zh`, `ug`, `pt`, `ff`, `az`, `id`, `ms`, `da`, `de`, `es`, `fr`, `it`, `nl`) with Arabic (`ar`) as fallback. All time displays enforce proper directional rendering via `ClockTimeText` and `SuwayaTimeText`.


* **Themes:** 4 color palettes (`gold`, `ocean`, `forest`, `desert`) across `light`, `dark` (OLED), `system`, and `mixed` (automatically switches between light during `SuwayaPhase.day` and dark during `SuwayaPhase.night`).



Before opening a pull request or releasing a build, verify:

```bash
dart run build_runner build --delete-conflicting-outputs
dart format .
flutter analyze
flutter test
