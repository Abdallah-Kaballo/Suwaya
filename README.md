# Suwaya

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.2%2B-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/license-GPL--3.0-blue)](LICENSE)
[![Languages](https://img.shields.io/badge/languages-22-green)](assets/translations/)

Suwaya is a Flutter application that organizes the day around astronomical events and prayer times. It combines a 48-Suwaya virtual time model with tasks, routines, focus sessions, notifications, alarms, and location-aware calculations.

The project is currently local-first: settings, tasks, routines, and location data are stored on the device. The application does not currently depend on a cloud backend or user authentication.

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

Civil time treats every clock hour as equal. Suwaya adds an astronomical layer based on the actual day at the selected location:

```text
Location + date
      |
      v
Prayer and solar event calculations
      |
      v
Fajr-to-Fajr periods
      |
      v
48 Suwayas distributed across the periods
      |
      v
Current period, virtual time, tasks, routines, and focus sessions
```

The main day boundaries are Fajr, sunrise, Dhuhr, Asr, Maghrib, Isha, and the following Fajr. Period lengths vary with the calculated astronomical timings, while the complete day always contains 48 Suwayas.

## How Suwaya Time Works

The pure Dart `suwaya_time` package calculates prayer timings, night parts, daily periods, and the Suwaya distribution. The Flutter application supplies the active location, date, timezone offset, calculation method, Madhab, high-latitude rule, and manual prayer offsets.

The runtime engine maintains these invariants:

- Prayer timings are chronologically ordered.
- Generated periods are contiguous.
- Periods cover the interval from Fajr to the next Fajr.
- The daily distribution contains exactly 48 Suwayas.
- The night interval extends from Maghrib to the following Fajr.
- A manual offset changes only its selected prayer.

The app caches a small number of generated days. Its state timer wakes at the next Suwaya boundary, while a lightweight five-second ticker updates the displayed virtual clock without rebuilding the full application state.

## Suwaya Time Reference

For the complete calculation model, period boundaries, 48-Suwaya distribution, virtual-time mapping, timezone behavior, edge cases, and test invariants, see [Suwaya-Time.md](Suwaya-Time.md).

## Current Features

### Main experience

- Home screen with mini and premium astronomical dials.
- Ibadat screen with prayer timings and an astronomical timeline.
- Tasks with date, period, Suwaya, pattern, and completion handling.
- Routines and routine list management.
- Pomodoro/focus screen linked to the current Suwaya progress.
- Onboarding for language and location selection.

### Calculations and device services

- Adhan-based prayer calculations with configurable method and Madhab.
- High-latitude rules, custom Fajr/Isha angles, and manual offsets.
- Saved locations, geocoding, and timezone-aware calculations.
- Local notifications and alarms.
- Permission handling for location, notifications, and alarms.
- Light/dark themes, day-aware theme behavior, and RTL/LTR layouts.
- 22 translation files under `assets/translations/`.

## Architecture

Suwaya uses a feature-oriented Flutter architecture:

```text
Flutter screens and shared widgets
              |
      Riverpod providers/notifiers
              |
 Repositories and platform services
              |
        Isar local database
              |
     Pure Dart suwaya_time package
```

Widgets render state and collect user actions. Providers and notifiers coordinate state. Repositories own Isar access, while services wrap notifications, alarms, location, and geocoding. The astronomical calculations live in `packages/suwaya_time` and do not depend on Flutter or Riverpod.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the implementation rules and startup sequence.

## Repository Structure

```text
lib/
├── main.dart
├── core/
│   ├── astro_engine/       # Flutter adapter and current astronomical state
│   ├── bootstrap/          # Lightweight application initialization
│   ├── database/           # Isar initialization and provider
│   ├── localization/       # Supported locales and translation path
│   ├── location/           # Location, geocoding, and permissions
│   ├── notification/       # Notification services and scheduling
│   ├── repositories/       # Task, routine, and settings persistence
│   ├── router/             # go_router configuration
│   ├── services/           # Alarm service
│   ├── theme/              # Themes and astronomical UI color adapters
│   └── providers/          # Shared UI providers
├── features/               # Home, ibadat, tasks, routines, pomodoro, settings, etc.
├── models/                 # Isar models and generated adapters
└── shared/widgets/         # Reusable application widgets
packages/suwaya_time/       # Pure Dart astronomical domain package
Suwaya-Time.md              # Detailed Suwaya time and calculation reference
test/                       # Domain, provider, model, and widget tests
assets/translations/        # 22 localization files
docs/privacy.md             # Privacy policy
```

## Technology Stack

| Area | Technology |
|---|---|
| Application | Flutter and Dart |
| State management | Riverpod |
| Routing | go_router |
| Local persistence | Isar Community |
| Prayer calculations | adhan |
| Astronomical domain engine | Local `suwaya_time` Dart package |
| Location | Geolocator and Geocoding |
| Localization | Easy Localization and intl |
| Notifications | Flutter Local Notifications |
| Alarms | alarm |
| Charts and animation | FL Chart and flutter_animate |

## Requirements and Installation

Requirements:

- Flutter with Dart SDK `>=3.2.3 <4.0.0`.
- Android, iOS, desktop, or web tooling for the target platform.

```bash
git clone https://github.com/Abdallah-Kaballo/Suwaya.git
cd Suwaya
flutter pub get
flutter run
```

Generate Isar adapters after changing persistent models:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Configuration

The application has no required cloud credentials. Platform configuration may still be needed for location, notifications, exact alarms, and other native capabilities. Review the platform project files and request permissions only when the related feature is used.

Translation assets, the city database, app icons, and notification audio are declared in `pubspec.yaml`.

## Testing

```bash
flutter analyze
flutter test
dart format .
```

The test suite covers prayer and period calculations, daylight-saving and leap-year behavior, polar/high-latitude cases, manual offsets, the 48-Suwaya distribution, virtual-time mapping, task logic, settings cloning, task providers, and widgets.

## Calculation Methodology

Results depend on coordinates, date, timezone offset, calculation method, Madhab, high-latitude rule, custom angles, and manual offsets. Different applications can therefore produce different results. Suwaya exposes these inputs in settings and tests the domain invariants rather than claiming universal agreement with every reference implementation.

## Localization

Supported locales are registered in `lib/core/localization/app_locales.dart`. Translation files are stored in `assets/translations/`, with Arabic as the fallback locale. User-visible text should be localized, and both RTL and LTR layouts must be checked when adding or changing UI.

## Data, Privacy, and Permissions

Tasks, routines, settings, and saved locations are stored locally in Isar. Location is used to calculate prayer and astronomical times. Read [docs/privacy.md](docs/privacy.md) for the current privacy policy.

| Permission | Purpose |
|---|---|
| Location | Location-aware calculations and saved places |
| Notifications | Prayer, task, and routine reminders |
| Alarms | Alarm scheduling and ringing |
| Internet | Platform or package functionality that requires it; no cloud sync is currently configured |

## Known Limitations

- Calculation results vary between methods and high-latitude rules.
- Some alarm and notification behavior requires platform-specific native permissions.
- Location and timezone data can change when the user travels or changes the active location.
- Cloud synchronization, authentication, analytics, and statistics screens are not part of the current implementation.
- Widget and integration coverage is smaller than the domain test coverage.

## Contributing

Keep domain calculations in `packages/suwaya_time`, persistence behind repositories, and platform APIs behind services. Add translation keys for user-visible text and tests for calculation, state, or persistence changes.

Before opening a pull request:

```bash
dart format .
flutter analyze
flutter test
```

## Security

Do not commit signing credentials, private API keys, passwords, or personal access tokens. Report security issues privately to the repository owner or through the repository's available GitHub security channels.

## License

Suwaya is licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE).
