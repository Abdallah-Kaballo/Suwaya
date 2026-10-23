# Suwaya Time

A comprehensive reference for Suwaya's astronomical time system (Schedule Model V2) and the pure Dart `packages/suwaya_time` package[cite: 3]. This package transforms continuously changing solar events and prayer timings into a highly structured 24-Suwaya virtual day, perfectly divided into 12 Night Suwayas and 12 Day Suwayas[cite: 1, 3].

> **Note:** This document describes the V2 behavior implemented in the current codebase (`scheduleModelVersion = 2`)[cite: 1, 3].

## 1. Core Concept

Civil time measures the day with fixed 60-minute clock hours starting at midnight[cite: 3]. Suwaya shifts the paradigm by starting from the astronomical and Islamic cycle—where the night precedes the day (**Maghrib to the following Maghrib**)—and dividing this cycle into meaningful periods anchored by prayer times and solar events[cite: 1, 3]:

```text
Location + Date + Calculation Settings
                 |
                 v
   Prayer and Solar Event Timings (via Adhan)
                 |
                 v
   From Active Maghrib to Next Maghrib
                 |
                 v
   Seven Contiguous Astronomical Periods
 (4 Night Periods = 12 Suwayas | 3 Day Periods = 12 Suwayas)
                 |
                 v
 Current Period, SuwayaClockTime, and Virtual Flow Speed

```

A Suwaya does not consist of a fixed 60 real-world minutes. Instead, **each Suwaya represents exactly 60 virtual minutes (3,600 virtual seconds)**. Its *real* duration expands and contracts according to the physical length of the astronomical period that contains it.

**Key Invariants:**

* A complete astronomical cycle runs from **Maghrib to the next Maghrib** (`cycleEndMaghrib`).


* A complete cycle contains exactly **24 Suwayas**.


* **Night Phase (`SuwayaPhase.night`):** 12 Suwayas (from Maghrib to Sunrise), numbered `01` to `12` (`🌑` / `ل` / `N`).


* **Day Phase (`SuwayaPhase.day`):** 12 Suwayas (from Sunrise to next Maghrib), numbered `01` to `12` (`☀️` / `ن` / `D`).




* A complete virtual day always equals `24 × 60 = 1,440 virtual minutes`.


* Global Suwaya indices run from `0` to `23` (`0..11` for Night, `12..23` for Day).


* The speed of virtual time (`timeSpeedMultiplier` / `flowSpeed`) dynamically accelerates or decelerates from one period to another.



## 2. Package Components

The domain logic is strictly isolated in `packages/suwaya_time/lib/`:

```text
packages/suwaya_time/lib/
├── suwaya_time.dart
└── src/
    ├── calculators/
    │   ├── prayer_calculator.dart
    │   └── night_division.dart
    ├── engine/
    │   ├── suwaya_time_engine.dart
    │   └── temporal_context_engine.dart
    ├── generators/
    │   ├── period_generator.dart
    │   └── suwaya_distributor.dart
    └── models/
        └── astro_models.dart

```

The package is **pure Dart**. It has zero dependencies on Flutter, Riverpod, `BuildContext`, localization, or platform channels, ensuring calculations are universally testable and stable. Prayer calculations are powered by the robust `adhan` package.

## 3. Calculation Inputs

The engine generates an astronomical day based on the following precise inputs:

| Input | Type | Description |
| --- | --- | --- |
| `lat` | `double` | Latitude in degrees

 |
| `lng` | `double` | Longitude in degrees

 |
| `date` | `DateTime` | Anchor date for the Maghrib-to-Maghrib cycle

 |
| `methodType` | `CalculationMethodType` | Prayer-time calculation method (e.g., MWL, Umm Al-Qura)

 |
| `madhabType` | `MadhabType` | Asr shadow calculation school (`shafi` or `hanafi`)

 |
| `highLatRuleType` | `HighLatitudeRuleType` | High-latitude adjustment rule

 |
| `customFajr` / `customIsha` | `double` | Custom angles when the `custom` method is selected

 |
| `cityOffset` | `Duration` | Timezone offset applied to UTC `adhan` results

 |
| `manualOffsets` | `Map<PrayerKey, int>?` | Manual minute adjustments (`-30` to `+30`) per prayer

 |

## 4. The Seven Astronomical Periods (Maghrib-to-Maghrib)

`PeriodGenerator` divides the Maghrib-to-Maghrib cycle into **7 contiguous periods** (`id` 1 to 7) identified by their `PeriodKey`:

| ID | `PeriodKey` | Phase | Start Boundary | End Boundary | Suwayas | Global Indices (`0..23`) |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `nightMaghribIsha` | Night 🌑 | Maghrib | Isha | Shared with Period 2 (Total = 5) | Starts at `0` (`01 🌑`)

 |
| 2 | `nightIshaMidnight` | Night 🌑 | Isha | Astronomical Midnight | Shared with Period 1 (Total = 5) | Ends at `4` (`05 🌑`)

 |
| 3 | `nightMidnightFajr` | Night 🌑 | Astronomical Midnight | Fajr | **6** (Fixed) | `5 .. 10` (`06..11 🌑`)

 |
| 4 | `nightFajrSunrise` | Night 🌑 | Fajr | Sunrise | **1** (Fixed) | `11` (`12 🌑`)

 |
| 5 | `daySunriseDhuhr` | Day ☀️ | Sunrise | Dhuhr | Dynamic Allocation | Starts at `12` (`01 ☀️`)

 |
| 6 | `dayDhuhrAsr` | Day ☀️ | Dhuhr | Asr | Dynamic Allocation | Follows Period 5

 |
| 7 | `dayAsrMaghrib` | Day ☀️ | Asr | Next Maghrib | Dynamic Allocation | Ends at `23` (`12 ☀️`)

 |

## 5. Second-Half Night Division (Qiyam Parts)

Because the first half of the night (Maghrib to Midnight) is managed by Period 1 and Period 2, `NightDivision` focuses exclusively on dividing **Period 3 (Astronomical Midnight to Fajr, spanning 6 Suwayas)** into the 5 canonical Qiyam parts:

| ID | Name Key / Concept | Duration in Suwayas | Suwaya Start | Suwaya End |
| --- | --- | --- | --- | --- |
| `half_2` | Second Half of the Night | **6 Suwayas** | `06 | 00 🌑` |
| `third_3` | Last Third of the Night | **4 Suwayas** | `08 | 00 🌑` |
| `sixth_4` | Fourth Sixth of the Night | **2 Suwayas** | `06 | 00 🌑` |
| `sixth_5` | Fifth Sixth of the Night | **2 Suwayas** | `08 | 00 🌑` |
| `sixth_6` | Sixth Sixth of the Night | **2 Suwayas** | `10 | 00 🌑` |

**Smart Conflict Resolution:** The application enforces mutual exclusivity when displaying dial markers. Selecting `third_3` (4 Suwayas) automatically deselects the smaller subdivisions `sixth_5` and `sixth_6` to prevent visual overlapping on the Astrolabe Dial.

## 6. Real Suwaya Duration and Flow Speed (`PeriodMetrics`)

For any `AstroPeriod` with a real physical duration `period.totalDuration` and `suwayasCount = n`:

```text
actualSuwayaDuration = period.totalDuration / n

```

Because 1 Suwaya equals exactly **60 virtual minutes (3,600 virtual seconds)**, the virtual time flow speed is calculated as:

```text
flowSpeed = 3600 / actualSuwayaDurationInSeconds

```

* **`flowSpeed == 1.00x`**: 1 Suwaya lasts 60 real minutes. Virtual and civil time move at the exact same pace.


* **`flowSpeed > 1.00x`**: The real Suwaya is shorter than 60 real minutes. Virtual time flows *faster* than civil time.


* **`flowSpeed < 1.00x`**: The real Suwaya is longer than 60 real minutes. Virtual time flows *slower* than civil time.



## 7. Flutter Runtime Adapter (`AstroNotifier`)

Located at `lib/core/astro_engine/astro_provider.dart`, `AstroNotifier` securely bridges the pure `SuwayaTimeEngine` with Flutter's reactive ecosystem:

1. **Settings Fingerprint:** Re-evaluates only when core location, calculation, or timezone parameters change.


2. **Dual-Timer Architecture:**
* **Smart State Timer (`_stateTimer`):** Goes to sleep and wakes up exactly at the microsecond of the next Suwaya boundary. It minimizes rebuilds by only notifying listeners when `currentPeriod.id` or `periodLocalSlotNumber` physically changes.


* **1-Second UI Ticker (`_uiTimer`):** A lightweight 250ms periodic ticker that drives the `virtualDateTimeNotifier` and `virtualTimeNotifier`. This allows the `PremiumAstroDial` needles and digital clocks to animate smoothly at 60fps without causing heavy widget tree rebuilds.





```

---

### 2. ملف `docs/privacy.md`

```markdown
# Privacy Policy for Suwaya (سُويعَة)

**Last updated: October 2026**

Abdallah Kaballo ("we", "our", or "us") develops and maintains Suwaya, an open-source Flutter application for astronomical prayer times, virtual Suwaya time, tasks, routines, and focus sessions. This policy explains what information the current version of the application accesses, how it is used, and where it is stored[cite: 6].

## 1. Scope and Current Data Model

The current application operates on a **local-first** basis[cite: 6]. It does not provide user accounts, authentication, cloud synchronization, or a configured remote database[cite: 6]. 

Most application data is stored exclusively on your device within an Isar Community database[cite: 6]. The current database contains your customized settings, tasks, habits, routines, and saved geographic information[cite: 6]. The application also bundles a read-only SQLite database for local offline city search and location matching[cite: 6].

## 2. Information the Application Uses

### Location Information
When you opt to use automatic location detection, Suwaya requests location permissions and uses your device's coordinates locally to[cite: 6]:
- Calculate precise prayer and astronomical times[cite: 6].
- Select the correct timezone context[cite: 6].
- Find your approximate nearest city and country via the bundled offline city database[cite: 6].
- Suggest accurate calculation methods and Madhab defaults[cite: 6].

**These coordinates are never sent to a Suwaya server.** Suwaya does not track your movement in the background, build a location history, or sell location data[cite: 6]. You may alternatively choose a location manually and deny location permissions entirely[cite: 6].

### Application Data
Depending on the features you use, Suwaya stores locally[cite: 6]:
- Calculation preferences, UI language, visual themes, and notification settings[cite: 6].
- Tasks, task schedules, completion history, streaks, and Suwaya contexts[cite: 6].
- Focus routines and their associated parameters[cite: 6].

### Notifications and Alarms
If enabled, Suwaya schedules local notifications and full-screen exact alarms through the operating system[cite: 6]. Suwaya uses these to deliver time-sensitive reminders but does not transmit notification histories to any remote server[cite: 6].

## 3. Information We Do Not Collect & Supporter Purchases

The application does not collect or transmit[cite: 6]:
- Personal authentication identifiers or account details[cite: 6].
- Advertising identifiers or behavioral analytics tracking[cite: 6].
- Task or routine data to any cloud backend[cite: 6].

If you optionally choose to purchase a Supporter Badge, Suwaya utilizes Google Play Billing (or Apple App Store) alongside the RevenueCat SDK to verify your entitlement via an anonymous app user ID[cite: 6]. Financial and payment details are processed exclusively by the platform store and are never accessed, captured, or stored by Suwaya[cite: 6].

## 4. Data Storage, Retention, and Deletion

Local data remains on your device until you delete it through the app's interface, clear the application’s storage via your OS settings, or uninstall the application[cite: 6]. Suwaya does not retain a server-side copy of your local tasks, routines, or settings[cite: 6].

## 5. Permissions

Suwaya may request the following system permissions to function correctly[cite: 6]:

| Permission | Purpose |
|---|---|
| **Location** | For automatic location detection and location-aware prayer calculations[cite: 6]. |
| **Notifications** | To deliver local task, routine, and prayer reminders[cite: 6]. |
| **Exact Alarms** | To schedule time-sensitive, full-screen lockscreen alarms[cite: 6]. |
| **Vibration** | To provide haptic feedback during local notifications and alarms[cite: 6]. |
| **Internet** | To fetch Markdown documentation updates (FAQ/Privacy), check for app updates, and process optional Supporter badge purchases[cite: 6]. |

You can deny or revoke these permissions at any time through your operating system settings[cite: 6].

## 6. Third-Party Libraries and Network Services

Suwaya uses open-source libraries for Flutter, local persistence (`isar_community`, `sqflite`), astronomical calculations (`adhan`), geolocation, localization, and notifications[cite: 6]. Network access is strictly limited to[cite: 6]:
- Fetching FAQ and Privacy Policy JSON updates directly from the official GitHub repository[cite: 6].
- Checking for in-app updates via official store APIs (`in_app_update`)[cite: 6].
- Verifying optional supporter badge entitlements via Google Play Billing and RevenueCat[cite: 6].

## 7. Security

Local data protection depends on the security of your device and operating system[cite: 6]. We strongly recommend keeping your device protected with standard security controls (PIN/Biometrics) and advise against using rooted or compromised devices if you store sensitive personal schedules[cite: 6].

## 8. Children

Suwaya is not designed to knowingly collect personal information from children[cite: 6]. Because the application operates offline-first and provides no cloud account system, it does not intentionally create child user profiles or collect data remotely[cite: 6].

## 9. Changes to This Policy

This policy may be updated if the application's data practices evolve. The "Last updated" date at the top of this page indicates the latest revision[cite: 6]. Material changes will be reflected in the project documentation and release notes[cite: 6].

## 10. Contact

For questions, corrections, or privacy concerns, please contact the project maintainer by opening an issue on the official Suwaya GitHub repository[cite: 6]:

<https://github.com/Abdallah-Kaballo/Suwaya>

Suwaya is open-source and licensed under the GNU General Public License v3.0[cite: 6]. Its source code is publicly available for review in the repository[cite: 6].

```