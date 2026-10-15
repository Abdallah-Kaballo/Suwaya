# Suwaya (سُويعَة)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.2%2B-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/license-GPL--3.0-blue)](LICENSE)
[![Languages](https://img.shields.io/badge/languages-22-green)](assets/translations/)

Suwaya is an open-source Astro-Productivity Flutter application that organizes the day around astronomical events and prayer times[cite: 3]. It combines a 24-Suwaya Maghrib-to-Maghrib virtual time model (12 Night Suwayas and 12 Day Suwayas, each representing 60 virtual minutes) with casual tasks, continuous habits, routines, dual-mode Pomodoro focus sessions, offline geolocation, notifications, full-screen lockscreen alarms, and multi-language support[cite: 1, 2, 3].

The project is strictly local-first and privacy-focused: settings, tasks, routines, and saved locations are stored locally using Isar Community, while offline city search relies on a bundled SQLite database (`cities.db`)[cite: 1, 3]. The application does not require a cloud backend or user authentication[cite: 3].

## Contents

- [Overview](#overview)
- [How Suwaya Time Works](#how-suwaya-time-works)
- [Suwaya Time Reference](#suwaya-time-reference)
- [Current Features](#current-features)
- [Architecture](#architecture)
- [Repository Structure](#repository-structure)
- [Technology Stack](#technology-stack)
- [Requirements and Installation](#requirements-and-installation)
- [Configuration](#configuration)
- [Testing](#testing)
- [Calculation Methodology](#calculation-methodology)
- [Localization](#localization)
- [Data, Privacy, and Permissions](#data-privacy-and-permissions)
- [Known Limitations](#known-limitations)
- [Contributing](#contributing)
- [Security](#security)
- [License](#license)

## Overview

Civil time treats every clock hour as equal[cite: 3]. Suwaya adds an astronomical layer based on the actual day at the selected location[cite: 3]:

```text
Location + date
      |
      v
Prayer and solar event calculations
      |
      v
Maghrib-to-Maghrib astronomical cycle
      |
      v
24 Suwayas distributed across 7 contiguous periods
      |
      v
Current period, virtual time, tasks, routines, and focus sessions

```

The main day boundaries follow the Islamic astronomical cycle (Maghrib to the following Maghrib) and are divided into 7 contiguous periods: Maghrib, Isha, Second Half of the Night (Qiyam), Fajr, Duha, Dhuhr, and Asr. Period lengths vary with calculated astronomical timings, while the complete cycle always contains 24 Suwayas.

## How Suwaya Time Works

The pure Dart `packages/suwaya_time` package calculates prayer timings, night parts, daily periods, and the Suwaya distribution. The Flutter application supplies the active location, date, timezone offset, calculation method, Madhab, high-latitude rule, and manual prayer offsets.

The runtime engine maintains these invariants:

* Prayer timings are chronologically ordered.


* Generated periods are contiguous.


* Periods cover the interval from Maghrib to the next Maghrib.


* The daily cycle contains exactly 24 Suwayas (12 Night, 12 Day).


* The night interval extends from Maghrib to the following Fajr.


* Qiyam parts are precisely defined within the second half of the night.


* A manual offset changes only its selected prayer.



The app caches generated astronomical cycles. Its smart state timer wakes at the next Suwaya boundary, while a lightweight five-second ticker updates the displayed virtual clock without rebuilding the full application state.

## Suwaya Time Reference

For the complete calculation model, period boundaries, 24-Suwaya distribution, virtual-time mapping, timezone behavior, edge cases, and test invariants, see [Suwaya-Time.md](https://www.google.com/search?q=Suwaya-Time.md).

## Current Features

### Main Experience

* Home screen with a Hijri night/day header, mini astronomical dial, and an interactive, touch-rotatable `PremiumAstroDial` with drag-and-drop task rescheduling.


* Ibadat screen with next-prayer countdowns, prayer timings, sunrise toggle, and 5 canonical Qiyam night parts (`half_2`, `third_3`, `sixth_4`, `sixth_5`, `sixth_6`).


* Tasks screen with three tabs (Casual Tasks, Continuous Habits, and Routines), streak tracking, and freeze protection[cite: 1, 2].
* Dual-mode Pomodoro focus screen (Traditional Pomodoro with customizable cycles and Suwaya Pomodoro linked to prayer times and flow speeds).


* Onboarding flow for language selection (22 languages) and smart location configuration.



### Calculations and Device Services

* Adhan-based prayer calculations with configurable calculation methods and Madhabs (Shafi/Hanafi).


* High-latitude rules, custom Fajr/Isha angles, and manual offsets.


* Offline city search and Haversine reverse geocoding via a bundled SQLite database (`cities.db`).


* Background 7-day notification and alarm scheduling via `Isolate.run`.


* Full-screen lockscreen alarms with hardware volume button snoozing and interactive swipe-to-stop/snooze.


* Light, dark (OLED), system, and mixed themes, with RTL/LTR layout support.



## Architecture

Suwaya uses a feature-oriented Flutter architecture:

```text
Flutter screens and shared widgets
              |
      Riverpod providers/notifiers
              |
 Repositories and platform services
              |
  Isar local DB & SQLite city DB
              |
     Pure Dart suwaya_time package

```

Widgets render state and collect user actions. Providers and notifiers coordinate state. Repositories own Isar persistence, while services wrap notifications, alarms, location, geocoding, and database migrations. The astronomical calculations live in `packages/suwaya_time` and do not depend on Flutter or Riverpod.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the implementation rules and startup sequence.

## Repository Structure

```text
lib/
├── main.dart
├── core/
│   ├── astro_engine/       # Flutter adapter and current astronomical state[cite: 3]
│   ├── bootstrap/          # Lightweight application initialization[cite: 3]
│   ├── database/           # Isar initialization and provider[cite: 3]
│   ├── localization/       # Supported locales and translation path[cite: 3]
│   ├── location/           # SQLite Geo database, location service, and permissions[cite: 1, 3]
│   ├── notification/       # Notification services, Isolate scheduler, and time resolver[cite: 1, 3]
│   ├── repositories/       # Task, routine, and settings persistence[cite: 3]
│   ├── router/             # go_router configuration and startup gate[cite: 1, 3]
│   ├── services/           # Alarm service and data migration service[cite: 1, 3]
│   ├── theme/              # Themes, color themes, dial designs, and UI color adapters[cite: 1, 3]
│   └── providers/          # Shared UI providers[cite: 3]
├── features/               # Home, ibadat, tasks, routines, pomodoro, settings, alarm, etc.[cite: 1, 3]
├── models/                 # Persistent Isar models and generated adapters[cite: 3]
└── shared/widgets/         # Reusable application widgets[cite: 3]
packages/suwaya_time/       # Pure Dart astronomical domain package[cite: 3]
Suwaya-Time.md              # Detailed Suwaya time and calculation reference[cite: 3]
test/                       # Domain, provider, model, and widget tests[cite: 3]
assets/translations/        # 22 localization files[cite: 3]
docs/privacy.md             # Privacy policy[cite: 3]

```

## Technology Stack

| Area | Technology |
| --- | --- |
| Application | Flutter and Dart

 |
| State management | Riverpod

 |
| Routing | go_router

 |
| Local persistence | Isar Community & SQLite (`sqflite`)

 |
| Prayer calculations | adhan

 |
| Astronomical domain engine | Local `suwaya_time` Dart package

 |
| Location & Geocoding | Geolocator and Geocoding

 |
| Localization | Easy Localization and intl

 |
| Notifications | Flutter Local Notifications

 |
| Alarms | alarm

 |
| In-app updates & support | in_app_update & purchases_flutter

 |

## Requirements and Installation

Requirements:

* Flutter with Dart SDK `>=3.2.3 <4.0.0`.


* Android, iOS, desktop, or web tooling for the target platform.



```bash
git clone [https://github.com/Abdallah-Kaballo/Suwaya.git](https://github.com/Abdallah-Kaballo/Suwaya.git)
cd Suwaya
flutter pub get
flutter run

```

Generate Isar adapters after changing persistent models:

```bash
dart run build_runner build --delete-conflicting-outputs

```

## Configuration

The application has no required cloud credentials. Platform configuration may still be needed for location, notifications, exact alarms, and wake-lock capabilities. Review platform project files and request permissions only when the related feature is used.

Translation assets, the city database (`cities.db`), app icons, and notification audio are declared in `pubspec.yaml`.

## Testing

```bash
flutter analyze
flutter test
dart format .

```

The test suite covers prayer and period calculations, daylight-saving and leap-year behavior, polar/high-latitude cases, manual offsets, the 24-Suwaya distribution, virtual-time mapping, task logic, settings cloning, task providers, and widgets.

## Calculation Methodology

Results depend on coordinates, date, timezone offset, calculation method, Madhab, high-latitude rule, custom angles, and manual offsets. Different applications can therefore produce different results. Suwaya exposes these inputs in settings and tests the domain invariants rather than claiming universal agreement with every reference implementation.

## Localization

Supported locales are registered in `lib/core/localization/app_locales.dart`. Translation files are stored in `assets/translations/`, with Arabic as the fallback locale. User-visible text should be localized, and both RTL and LTR layouts must be checked when adding or changing UI.

## Data, Privacy, and Permissions

Tasks, routines, settings, and saved locations are stored locally in Isar. Location is used to calculate prayer and astronomical times. Read [docs/privacy.md](https://www.google.com/search?q=docs/privacy.md) for the privacy policy.

| Permission | Purpose |
| --- | --- |
| Location | Location-aware calculations and saved places

 |
| Notifications | Prayer, task, and routine reminders

 |
| Alarms | Full-screen alarm scheduling and ringing

 |
| Internet | Dynamic FAQ/Privacy updates from GitHub; no cloud sync is configured

 |

## Known Limitations

* Calculation results vary between calculation methods and high-latitude rules.


* Some alarm and notification behaviors require platform-specific native permissions.


* Location and timezone data can change when the user travels or changes the active location.


* Cloud synchronization, user authentication, and remote analytics are not part of the current implementation.



## Contributing

Keep domain calculations in `packages/suwaya_time`, persistence behind repositories, and platform APIs behind services. Add translation keys for user-visible text and tests for calculation, state, or persistence changes.

Before opening a pull request:

```bash
dart format .
flutter analyze
flutter test

```

## Security

Do not commit signing credentials, private API keys, passwords, or personal access tokens. Report security issues privately to the repository owner or through available GitHub security channels.

## License

Suwaya is licensed under the GNU General Public License v3.0. See [LICENSE](https://www.google.com/search?q=LICENSE).