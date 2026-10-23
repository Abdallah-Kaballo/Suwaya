# Suwaya Time

A comprehensive reference for Suwaya's astronomical time system (Schedule Model V2) and the pure Dart `packages/suwaya_time` package. This package transforms continuously changing solar events and prayer timings into a highly structured 24-Suwaya virtual day, perfectly divided into 12 Night Suwayas and 12 Day Suwayas.

> **Note:** This document describes the V2 behavior implemented in the current codebase (`scheduleModelVersion = 2`).

## 1. Core Concept

Civil time measures the day with fixed 60-minute clock hours starting at midnight. Suwaya shifts the paradigm by starting from the astronomical and Islamic cycle—where the night precedes the day (**Maghrib to the following Maghrib**)—and dividing this cycle into meaningful periods anchored by prayer times and solar events:

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
