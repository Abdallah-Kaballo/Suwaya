# Suwaya (سُويعَة)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.2%2B-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/license-GPL--3.0-blue)](LICENSE)
[![Languages](https://img.shields.io/badge/languages-22-green)](assets/translations/)

Suwaya is an open-source Astro-Productivity Flutter application that organizes your day around astronomical events and prayer times. It replaces rigid civil clock hours with a dynamic **24-Suwaya Maghrib-to-Maghrib virtual time model** (12 Night Suwayas and 12 Day Suwayas, each representing 60 virtual minutes). 

The app unifies casual tasks, continuous habits, routines, a dual-mode Pomodoro focus timer, an interactive Hijri calendar with seasonal fasting recommendations, offline geolocation, and full-screen lockscreen alarms. It operates strictly **local-first** with absolute privacy, utilizing on-device databases (Isar Community & SQLite) without requiring user authentication or a cloud backend.

## Contents

- [Overview](#overview)
- [How Suwaya Time Works (V2 Model)](#how-suwaya-time-works-v2-model)
- [Current Features](#current-features)
- [Architecture & Tech Stack](#architecture--tech-stack)
- [Repository Structure](#repository-structure)
- [Requirements and Installation](#requirements-and-installation)
- [Localization](#localization)
- [Data, Privacy, and Permissions](#data-privacy-and-permissions)
- [Contributing](#contributing)
- [License](#license)

## Overview

Civil time treats every clock hour as equal. Suwaya adds an astronomical layer based on the actual sun movement at your selected location:

```text
Location + Date + Calculation Settings
                 |
                 v
   Prayer and Solar Event Timings (Adhan)
                 |
                 v
   Maghrib-to-Maghrib Astronomical Cycle
                 |
                 v
   7 Contiguous Periods = 24 Virtual Suwayas (12 Night / 12 Day)
                 |
                 v
   Tasks, Routines, Habits, and Focus Sessions Synced to Astro Time

```

The day boundaries follow the Islamic astronomical cycle (Maghrib to the following Maghrib) and are divided into 7 contiguous periods: Maghrib, Isha, Qiyam (Second Half of the Night), Fajr, Duha, Dhuhr, and Asr. Period lengths vary physically throughout the year, but the virtual cycle always scales to exactly 24 Suwayas (1,440 virtual minutes).

## How Suwaya Time Works (V2 Model)

The pure Dart `packages/suwaya_time` engine calculates prayer timings, night parts, daily periods, and Suwaya distributions.

* **24-Suwaya Distribution:** The cycle consists of exactly 24 Suwayas. 12 Suwayas form the Night phase (Maghrib to Sunrise), and 12 Suwayas form the Day phase (Sunrise to Maghrib).


* **60 Virtual Minutes:** Each Suwaya is broken down into exactly 60 virtual minutes. The real-time flow speed of these virtual minutes dynamically accelerates (`>1.0x`) or decelerates (`<1.0x`) depending on the physical length of the current period.


* **Night Parts (Qiyam):** The second half of the night is automatically subdivided into 5 canonical parts (e.g., Last Third, Fourth Sixth) for precise night prayer scheduling.


* **Independent Engine:** The engine remains 100% pure Dart and completely independent of Flutter, relying only on mathematical models and pure Dart packages (`adhan`, `timezone`, `hijri`, and `intl`).

For a deep dive into the mathematical and astronomical specifications of the V2 time model, see [Suwaya-Time.md](Suwaya-Time.md).

## Current Features

### 🧭 Main Experience

* **Interactive Premium Astro Dial:** A touch-rotatable astronomical dial on the Home screen featuring drag-and-drop task rescheduling, dynamic needles, and beautiful geometric/classic designs.
* **Worships (Ibadat):** Detailed next-prayer countdowns, timeline overviews, sunrise toggles, and exclusive Qiyam night part tracking (`half_2`, `third_3`, `sixth_4`, `sixth_5`, `sixth_6`).
* **Hijri Calendar & Fasting:** A built-in dual calendar (Civil & Hijri) highlighting seasonal fasting recommendations like Arafah, Ashura, and the White Days.
* **Smart Task Management:** Three distinct modes:
* *Casual Tasks:* One-time events.
* *Continuous Habits:* Recurring actions with streak tracking and streak-freeze protection.
* *Routines:* Time blocks (e.g., work, reading) rendered as patterned colored arcs directly on the Astro Dial.



### 🍅 Dual-Mode Pomodoro Focus Timer

* **Traditional Mode:** Customizable work/break cycles based on standard civil minutes.
* **Suwaya Mode:** Focus sessions dynamically synchronized with the astronomical flow. It calculates optimal flow speeds, deducts setup time, and automatically halts upon the arrival of the next mandatory prayer time.

### ⚙️ Engine & Device Services

* **Offline City Database:** Instant location search and Haversine reverse geocoding via a bundled SQLite database (`Cities_V2.db`), requiring zero internet access.


* **Advanced Astro Calculations:** Supports multiple calculation methods (including MWL, Umm Al-Qura, ISNA, UOIF, Russia), high-latitude rules, custom angles, and manual minute offsets.


* **Isolate-Based Background Scheduler:** Computes 7-day notification windows flawlessly in the background off the main UI thread.


* **Full-Screen Lockscreen Alarms:** High-priority alerts that wake up the device, supporting interactive swipe-to-stop/snooze and hardware volume button snooze capabilities.


* **Customization:** 4 App Color Themes (Gold, Ocean, Forest, Desert), 4 UI Modes (Light, Dark, System, Mixed), and multiple dial rendering modes.

## Architecture & Tech Stack

Suwaya employs a strictly feature-first architecture built on modern Flutter tools:

| Area | Technology |
| --- | --- |
| **Framework** | Flutter & Dart (SDK 3.2+) |
| **State Management** | Riverpod |
| **Local Database** | Isar Community (Primary DB) & `sqflite` (Read-only Geo DB) |
| **Astro Domain** | Pure Dart `suwaya_time` local package (wrapping `adhan`) |
| **Routing** | `go_router` |
| **Location & Geocoding** | `geolocator` |
| **Notifications & Alarms** | `flutter_local_notifications` & `alarm` |
| **Localization** | `easy_localization` (22 supported languages) |
| **In-App Purchases** | `purchases_flutter` (RevenueCat for optional Supporter Badges) |

For a detailed breakdown of the application structure, startup sequence, and dependency injection patterns, see [ARCHITECTURE.md](ARCHITECTURE.md).

## Repository Structure

```text
lib/
├── main.dart
├── core/               # App bootstrap, Database, Theme, Notifications, Router, Repositories
├── features/           # Home, Ibadat, Tasks, Calendar, Pomodoro, Settings, Alarm
├── models/             # Isar persistent models & generated adapters
└── shared/widgets/     # Reusable UI components (AppDrawer, SuwayaTimeText, etc.)
packages/suwaya_time/   # Pure Dart astronomical engine package
assets/
├── db/                 # Bundled SQLite databases (Cities_V2.db)
├── icons/              # App icons and dial graphical assets
└── translations/       # 22 language JSON files

```

## Requirements and Installation

**Requirements:**

* Flutter SDK (3.24.0 or higher)
* Dart SDK (`>=3.2.3 <4.0.0`)
* Android / iOS build tools

**Installation:**

```bash
git clone [https://github.com/Abdallah-Kaballo/Suwaya.git](https://github.com/Abdallah-Kaballo/Suwaya.git)
cd Suwaya
flutter pub get

```

*Note: If you modify persistent Isar models (`lib/models/`), you must regenerate the adapters:*

```bash
dart run build_runner build --delete-conflicting-outputs

```

## Localization

Suwaya globally supports **22 languages**, seamlessly handling Right-To-Left (RTL) and Left-To-Right (LTR) UI paradigms, complete with localized numerals and calendar data. The default fallback language is Arabic (`ar`). Translations are managed via JSON files in `assets/translations/`.

## Data, Privacy, and Permissions

**100% Privacy Focused:** Suwaya is designed as a local-first tool. Tasks, habits, routines, settings, and location data never leave your device. The app utilizes on-device SQLite databases to resolve cities to coordinates.

**Permissions Used:**

* **Location:** Strictly calculated on-device to determine accurate sun positions.
* **Notifications & Exact Alarms:** Used exclusively to trigger your localized scheduled reminders, prayers, and task notifications.
* **Internet:** Used minimally to fetch dynamic JSON documentation updates (FAQ/Privacy), check for app updates, or verify optional supporter tier purchases (via RevenueCat/Google Play Billing).

Read [docs/privacy.md](docs/privacy.md) for the comprehensive privacy policy.

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Keep the `packages/suwaya_time` engine pure (No Flutter/Riverpod imports).


2. Maintain data persistence exclusively through Repository wrappers.
3. Ensure UI changes are tested in both RTL and LTR locales.
4. Run `dart format .`, `flutter analyze`, and `flutter test` before submitting a pull request.



## License

Suwaya is open-source software licensed under the **GNU General Public License v3.0**. See the [LICENSE](LICENSE) file for more details.

