# Suwaya

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.2%2B-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/license-GPL--3.0-blue)](LICENSE)
[![Languages](https://img.shields.io/badge/languages-22-green)](assets/translations/)

Suwaya is an open-source time and productivity system that organizes the day around astronomical events rather than treating every clock hour as identical.

It combines prayer times, astronomical periods, tasks, routines, focus sessions, notifications, and productivity tracking around the natural rhythm of the sun.

> Suwaya is not only a prayer-times application and not only a task manager.  
> It is an attempt to build a meaningful time layer between astronomical reality and everyday productivity.

## Contents

- [Overview](#overview)
- [Why Suwaya](#why-suwaya)
- [How Suwaya Time Works](#how-suwaya-time-works)
- [Features](#features)
- [Product Philosophy](#product-philosophy)
- [Architecture](#architecture)
- [Repository Structure](#repository-structure)
- [Technology Stack](#technology-stack)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Testing](#testing)
- [Accuracy and Calculation Methodology](#accuracy-and-calculation-methodology)
- [Localization](#localization)
- [Data and Privacy](#data-and-privacy)
- [Permissions](#permissions)
- [Known Limitations](#known-limitations)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [Security](#security)
- [FAQ](#faq)
- [License](#license)
- [Acknowledgments](#acknowledgments)

## Overview

Civil time presents the day as a sequence of equal clock hours:

```text
08:00  09:00  10:00  11:00
```

However, the actual length of daylight and darkness changes according to location, date, season, and astronomical conditions.

Suwaya models the day using astronomical events such as:

- Fajr
- Sunrise
- Dhuhr
- Asr
- Maghrib
- Isha
- The next Fajr

These events form meaningful boundaries for prayer, daily routines, focus sessions, and productivity planning.

The application is designed to work offline first. Core data is stored locally, while optional authentication and cloud synchronization allow selected data to be synchronized across devices.

## Why Suwaya?

### The Problem

Traditional productivity systems often assume that all hours of the day have the same meaning and duration.

That assumption does not reflect the changing relationship between:

- Daylight and darkness
- Location and timezone
- Seasons
- Prayer times
- Energy and daily routines

### The Idea

Suwaya adds an astronomical time layer above civil clock time.

Instead of forcing every activity into fixed blocks, it allows the user to understand and organize activities according to the actual structure of the day.

### The Result

The same time model can support:

- Prayer and worship
- Tasks
- Focus sessions
- Routines
- Reminders
- Statistics
- Daily planning

## How Suwaya Time Works

At a high level, the system follows this flow:

```text
Location + Date
       |
       v
Astronomical calculations
       |
       v
Prayer and solar events
       |
       v
Day and night periods
       |
       v
Suwaya distribution
       |
       v
Virtual time representation
       |
       v
Tasks, focus sessions, routines, and statistics
```

A typical astronomical day is represented as:

```text
Fajr
  |
Morning
  |
Sunrise
  |
Dhuhr
  |
Afternoon
  |
Asr
  |
Evening
  |
Maghrib
  |
Night
  |
Isha
  |
Next Fajr
```

The day is divided into 48 Suwayas. The distribution of these units changes according to the calculated duration of the daily periods.

The implementation maintains the following core invariants:

- The total daily distribution is always 48 Suwayas.
- Generated periods are contiguous.
- The periods cover the actual interval from Fajr to the next Fajr.
- Prayer times remain chronologically ordered.
- The night interval extends from Maghrib to the following Fajr.
- Manual offsets affect only the selected prayer.

The mathematical model and its assumptions are documented in the astronomical engine and its tests.

## Features

### Time System

- Astronomical day and night periods
- 48-Suwaya daily distribution
- Civil time and Suwaya time
- Interactive astronomical dials
- Prayer and solar event boundaries

### Productivity

- Task management
- Routines
- Pomodoro and focus sessions
- Productivity statistics
- Activity tracking
- Time-aware daily planning

### Prayer and Daily Rhythm

- Prayer time calculations
- Multiple calculation methods
- Madhab selection
- High-latitude rules
- Manual prayer offsets
- Night-part calculations
- Fajr-to-Fajr daily period generation

### Platform Features

- Offline-first local storage
- Optional cloud synchronization
- Authentication
- Google Sign-In support
- Notifications
- Alarms
- Location-based calculations
- RTL and LTR interfaces
- 22 localization files

## Product Philosophy

Suwaya is built around these principles:

1. Time should reflect the environment in which it occurs.
2. Astronomical events provide meaningful boundaries for the day.
3. Productivity should adapt to time instead of forcing time into rigid blocks.
4. Core functionality should remain useful without network access.
5. Calculations should be deterministic, understandable, and testable.
6. Personal data should remain transparent and under the user's control.
7. The application should support both spiritual and practical daily routines without treating them as unrelated systems.

## Architecture

Suwaya uses a feature-oriented Flutter architecture.

```text
+-----------------------------+
|         Flutter UI          |
+-----------------------------+
| Riverpod State Management   |
+-----------------------------+
| Providers and Notifiers     |
+-----------------------------+
| Application Services        |
+-----------------------------+
| Astronomical Domain Engine  |
+-----------------------------+
| Repositories and Isar DB    |
+-----------------------------+
| Optional Supabase Sync      |
+-----------------------------+
```

The main architectural rules are:

- Widgets are responsible for rendering and user interaction.
- Providers and notifiers orchestrate state and actions.
- Repositories own application data access.
- Services integrate with external and platform APIs.
- The astronomical engine remains independent of Flutter and Riverpod.
- Local storage is the primary source of truth.
- Cloud synchronization is optional and must not replace local data.

See [ARCHITECTURE.md](ARCHITECTURE.md) for the detailed architecture rules, startup sequence, state management conventions, database rules, synchronization model, and astronomical engine requirements.

## Repository Structure

```text
lib/
├── `main.dart`
├── `firebase_options.dart`
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

- `core/`: shared infrastructure, services, repositories, synchronization, and domain logic.
- `features/`: user-facing application features.
- `models/`: persistent Isar models and generated files.
- `shared/`: reusable widgets and UI components.
- `assets/translations/`: localization files.
- `test/`: unit and widget tests.
- `docs/`: project documentation.

## Technology Stack

| Layer | Technology |
|---|---|
| Framework | Flutter |
| Language | Dart |
| State management | Riverpod |
| Routing | GoRouter |
| Local database | Isar Community |
| Cloud backend | Supabase |
| Authentication | Supabase Auth and Google Sign-In |
| Astronomy and prayer calculations | Adhan and custom Dart domain logic |
| Location | Geolocator and Geocoding |
| Localization | Easy Localization |
| Notifications | Flutter Local Notifications |
| Crash reporting | Firebase Crashlytics |
| Charts | FL Chart |

## Requirements

- Flutter with Dart SDK `>=3.2.3 <4.0.0`
- Android SDK for Android development
- Xcode for iOS and macOS development
- Platform-specific Flutter tooling for the target platform
- A configured Firebase project for Crashlytics and platform services
- Supabase project credentials for cloud synchronization

Verify the installed tools:

```bash
flutter --version
dart --version
flutter doctor
```

## Installation

Clone the repository:

```bash
git clone https://github.com/Abdallah-Kaballo/Suwaya.git
cd Suwaya
```

Install dependencies:

```bash
flutter pub get
```

Generate Isar files when required:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Run the application:

```bash
flutter run
```

For a specific device:

```bash
flutter devices
flutter run -d <device-id>
```

## Configuration

Supabase is initialized using compile-time environment values:

```text
SUPABASE_URL
SUPABASE_ANON_KEY
```

Run the application with:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-public-anon-key
```

Only public client-safe values should be passed to the application. Never include service-role keys, private API keys, or backend secrets in the application bundle.

Firebase platform configuration is provided through the generated Firebase configuration files. Do not expose private credentials in source control.

## Testing

Run static analysis:

```bash
flutter analyze
```

Run all tests:

```bash
flutter test
```

Format Dart files:

```bash
dart format .
```

The astronomical engine tests currently verify:

- Chronological ordering of prayer times
- Night duration and night-part coverage
- Distribution of exactly 48 Suwayas
- Manual prayer offsets
- Contiguous daily periods
- Coverage from Fajr to the following Fajr

## Accuracy and Calculation Methodology

Astronomical results depend on:

- Geographic coordinates
- Date
- Timezone and daylight-saving rules
- Calculation method
- Madhab
- High-latitude rule
- Manual offsets
- Astronomical edge cases

Different applications may produce different results when they use different calculation settings or rounding rules.

Suwaya exposes configurable calculation inputs and tests important invariants in the domain engine. Results should be validated against trusted references before being used for critical decisions.

## Localization

Suwaya includes localization files for 22 languages.

Translation files are stored in:

```text
assets/translations/
```

The application supports:

- Left-to-right interfaces
- Right-to-left interfaces
- Dynamic localized text
- Localized date and time formatting

When adding a language:

1. Add the translation file under `assets/translations/`.
2. Register the locale in the application localization configuration.
3. Verify RTL or LTR layout behavior.
4. Run the analyzer and tests.
5. Check for missing or inconsistent translation keys.

## Data and Privacy

Most user-generated data is stored locally using Isar.

Optional cloud synchronization can store selected data in Supabase when authentication and connectivity are available. Local functionality should remain usable when the network is unavailable.

Location data is used to calculate astronomical and prayer times. According to the current privacy policy, location processing is performed locally and is not used to track user movements.

Firebase Crashlytics is used to collect crash reports and improve application stability.

Read the complete policy in [docs/privacy.md](docs/privacy.md).

## Permissions

| Permission | Purpose |
|---|---|
| Location | Astronomical and prayer-time calculations |
| Notifications | Time-aware reminders |
| Alarms | Scheduled alarm functionality |
| Internet | Optional authentication, synchronization, and remote services |

Permissions should be requested only when the related feature requires them.

## Known Limitations

- Cloud synchronization requires authentication and network connectivity.
- Astronomical results may differ between calculation methods.
- High-latitude locations require configurable fallback rules.
- Some platform features require additional native configuration.
- Widget and integration test coverage is still being expanded.
- The public documentation is evolving alongside the time model and synchronization behavior.

## Roadmap

The roadmap is intentionally focused on improving the reliability and understandability of the existing system.

### Current Focus

- Expand deterministic astronomical test coverage.
- Document the Suwaya time model in greater detail.
- Improve synchronization reliability.
- Expand widget and integration tests.
- Improve localization completeness and consistency.
- Validate high-latitude and timezone edge cases.

### Future Possibilities

- More detailed time-model visualizations.
- Broader calendar and device integrations.
- Additional platform-specific improvements.
- More advanced productivity analytics.

Future items are exploratory and should not be interpreted as currently available features.

## Contributing

Contributions are welcome in:

- Flutter and Dart development
- Astronomical and prayer-time validation
- Localization
- UI and UX
- Testing
- Documentation
- Accessibility
- Performance improvements

Before opening a pull request:

```bash
dart format .
flutter analyze
flutter test
```

Please keep changes focused, preserve the architectural boundaries described in [ARCHITECTURE.md](ARCHITECTURE.md), and include tests for changes to domain calculations or synchronization behavior.

## Security

Please do not disclose security vulnerabilities publicly through regular issues.

Until a dedicated security policy is added, security reports should be sent privately to the repository owner or submitted through the repository's available GitHub security reporting channels.

Never commit:

- Supabase service-role keys
- Private API keys
- Signing credentials
- Keystores
- Passwords
- Personal access tokens

## FAQ

### Is Suwaya another prayer-times application?

No. Prayer times are one of the foundations of Suwaya's time model. The application also connects astronomical periods with tasks, routines, focus sessions, notifications, and productivity tracking.

### Is Suwaya time the same as civil time?

No. Civil time remains the ordinary clock time used by the operating system. Suwaya time is a virtual representation based on astronomical periods and the distribution of 48 daily Suwayas.

### Does Suwaya replace the normal clock?

No. Suwaya complements civil time; it does not replace the system clock or standard scheduling conventions.

### Can Suwaya work offline?

Core local functionality is designed to work offline. Authentication and cloud synchronization require network access.

### Why can prayer times differ from another application?

Results can differ because of location, timezone, calculation method, Madhab, high-latitude rules, rounding, or manual offsets.

### Where is user data stored?

Most user data is stored locally using Isar. Selected data may be synchronized through Supabase when the user is authenticated and connected.

## License

Suwaya is licensed under the GNU General Public License v3.0.

See [LICENSE](LICENSE) for the complete license text.

## Acknowledgments

Suwaya is built with and inspired by the following open-source projects:

- [Flutter](https://flutter.dev)
- [Dart](https://dart.dev)
- [Riverpod](https://riverpod.dev)
- [Isar Community](https://pub.dev/packages/isar_community)
- [Supabase](https://supabase.com)
- [Adhan](https://pub.dev/packages/adhan)
- [Easy Localization](https://pub.dev/packages/easy_localization)
- [Firebase Crashlytics](https://firebase.google.com/products/crashlytics)

The project also acknowledges the work of the developers and researchers whose astronomical and prayer-time methods make this application possible.
```
