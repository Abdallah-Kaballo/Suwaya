# Suwaya Time

A comprehensive reference for Suwaya's astronomical time system (Schedule Model V2) and the pure Dart `packages/suwaya_time` package[cite: 1, 3]. The package transforms changing solar events and prayer timings into a structured 24-Suwaya virtual day divided into 12 Night Suwayas and 12 Day Suwayas[cite: 1].

> This document describes the V2 behavior implemented in the current codebase (`scheduleModelVersion = 2`)[cite: 1, 3].

## 1. Core Concept

Civil time measures the day with fixed 60-minute clock hours starting at midnight[cite: 3]. Suwaya starts from the astronomical and Islamic cycle—where night precedes day (**Maghrib to the following Maghrib**)—and divides the cycle into meaningful periods anchored by prayer and solar events[cite: 1, 3]:

```text
Location + date + calculation settings
                 |
                 v
     Prayer and solar event timings
                 |
                 v
   From active Maghrib to next Maghrib
                 |
                 v
     Seven contiguous astronomical periods
   (4 Night periods: 12 Suwayas | 3 Day periods: 12 Suwayas)
                 |
                 v
   Current Period, SuwayaClockTime, and Virtual Flow Speed

```

A Suwaya is not a fixed 60 real minutes. Each Suwaya represents **60 virtual minutes (3,600 virtual seconds)**, while its real duration expands and contracts according to the length of the astronomical period that contains it.

Therefore:

* A complete astronomical cycle runs from **Maghrib to the next Maghrib** (`cycleEndMaghrib`).


* A complete cycle contains **24 Suwayas**:


* **Night Phase (`SuwayaPhase.night`):** 12 Suwayas (from Maghrib to Sunrise), numbered `01` to `12` (`🌑` / `ل` / `N`).


* **Day Phase (`SuwayaPhase.day`):** 12 Suwayas (from Sunrise to next Maghrib), numbered `01` to `12` (`☀️` / `ن` / `D`).




* A complete virtual day equals `24 × 60 virtual minutes = 1,440 virtual minutes`.


* Global Suwaya indices run from `0` to `23` (`0..11` for Night, `12..23` for Day).


* The speed of virtual time (`timeSpeedMultiplier` / `flowSpeed`) changes dynamically from one period to another.



## 2. Package Components

The domain source is located under `packages/suwaya_time/lib/`:

```text
packages/suwaya_time/lib/
├── suwaya_time.dart
└── src/
    ├── calculators/
    │   ├── prayer_calculator.dart
    │   └── night_division.dart
    ├── engine/
    │   └── suwaya_time_engine.dart
    ├── generators/
    │   ├── period_generator.dart
    │   └── suwaya_distributor.dart
    └── models/
        └── astro_models.dart

```

The package is pure Dart. It does not depend on Flutter, Riverpod, `BuildContext`, localization, or platform services. Prayer calculations use the `adhan` package.

The public library exports:

* Models: `AstroPeriod`, `NightPart`, `IbadatTimings`, `CycleAnchors`, `SuwayaClockTime`, `SuwayaPhase`, `PeriodKey`, `SuwayaDay`, and `AstroState`.


* Engine: `SuwayaTimeEngine`.


* Calculators: `PrayerCalculator` and `NightDivision`.


* Generators: `PeriodGenerator` and `SuwayaDistributor`.


* Configuration types: `CalculationMethodType`, `MadhabType`, `HighLatitudeRuleType`, and `PrayerKey`.



## 3. Calculation Inputs

The engine generates an astronomical day from the following inputs:

| Input | Type | Meaning |
| --- | --- | --- |
| `lat` | `double` | Latitude in degrees

 |
| `lng` | `double` | Longitude in degrees

 |
| `date` | `DateTime` | Anchor date for the Maghrib-to-Maghrib cycle

 |
| `methodType` | `CalculationMethodType` | Prayer-time calculation method

 |
| `madhabType` | `MadhabType` | Asr shadow calculation school (`shafi` or `hanafi`)

 |
| `highLatRuleType` | `HighLatitudeRuleType` | High-latitude adjustment rule

 |
| `customFajr` | `double` | Fajr angle when using the `custom` method

 |
| `customIsha` | `double` | Isha angle when using the `custom` method

 |
| `cityOffset` | `Duration` | Timezone offset applied to UTC `adhan` results

 |
| `manualOffsets` | `Map<PrayerKey, int>?` | Manual minute adjustments (`-30` to `+30`) for prayers

 |

The main call is:

```dart
final day = SuwayaTimeEngine.generateDay(
  latitude,
  longitude,
  date,
  methodEnum,
  madhabEnum,
  highLatEnum,
  customFajrAngle,
  customIshaAngle,
  cityOffset,
  manualOffsets: manualOffsetsMap,
);

```

## 4. Calculation Methods, Madhab, and High-Latitude Rules

### 4.1 Calculation Methods

The engine and application support the following calculation methods:

* `muslimWorldLeague`
* `egyptian`
* `ummAlQura`
* `dubai`
* `qatar`
* `kuwait`
* `karachi`
* `northAmerica`
* `turkey`
* `tehran`
* `france_uoif` / `russia` / `singapore`
* `custom` (uses `customFajr` and `customIsha` angles configurable between `10.0°` and `20.0°`)



### 4.2 Madhab

```dart
enum MadhabType { hanafi, shafi }

```

* `shafi`: Standard shadow length factor.


* `hanafi`: Later Asr time.



### 4.3 High-Latitude Rules

```dart
enum HighLatitudeRuleType {
  middleOfTheNight,
  seventhOfTheNight,
  twilightAngle,
}

```

Used at high latitudes where twilight persists or nights/days are unusually short.

## 5. Prayer Timings and Manual Offsets

`PrayerCalculator.getIbadatTimings` computes prayer and solar events across the cycle boundary and applies:

```text
Adjusted Time = adhanTime.toUtc() + cityOffset + manualOffset

```

### Manual Offsets

Manual offsets are supplied via `PrayerKey` (`fajr`, `dhuhr`, `asr`, `maghrib`, `isha`) and clamped to:

```text
-30 minutes <= offset <= +30 minutes

```

* Manual offsets are not applied to `sunrise`.


* Each manual offset adjusts only its target prayer without astronomically recalculating other prayers, while period boundaries anchored to that prayer shift accordingly.



## 6. The Seven Astronomical Periods (Maghrib-to-Maghrib)

`PeriodGenerator` divides the Maghrib-to-Maghrib cycle into **7 contiguous periods** (`id` 1 to 7) identified by `PeriodKey`:

| ID | `PeriodKey` | Phase | Name Key / Role | Start Boundary | End Boundary | Suwayas | Global Indices (`0..23`) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `nightMaghribIsha` | Night (`🌑`) | `periods.maghrib` | Maghrib | Isha | Shared with Period 2 (Total = 5) | Starts at `0` (`01 🌑`)

 |
| 2 | `nightIshaMidnight` | Night (`🌑`) | `periods.isha` | Isha | Astronomical Midnight | Shared with Period 1 (Total = 5) | Ends at `4` (`05 🌑`)

 |
| 3 | `nightMidnightFajr` | Night (`🌑`) | `ibadat.qiyam_tab` (Second Half) | Astronomical Midnight | Fajr | **6** (Fixed) | `5 .. 10` (`06..11 🌑`)

 |
| 4 | `nightFajrSunrise` | Night (`🌑`) | `periods.fajr` | Fajr | Sunrise | **1** (Fixed) | `11` (`12 🌑`)

 |
| 5 | `daySunriseDhuhr` | Day (`☀️`) | `periods.duha` | Sunrise | Dhuhr | Dynamic Day Allocation | Starts at `12` (`01 ☀️`)

 |
| 6 | `dayDhuhrAsr` | Day (`☀️`) | `periods.dhuhr` | Dhuhr | Asr | Dynamic Day Allocation | Follows Period 5

 |
| 7 | `dayAsrMaghrib` | Day (`☀️`) | `periods.asr` | Asr | Next Maghrib | Dynamic Day Allocation | Ends at `23` (`12 ☀️`)

 |

### Key Structural Invariants of the 7 Periods:

1. **Night Phase Total = 12 Suwayas (Global Indices `0..11`)**:


* **Periods 1 & 2 (First Half of the Night: Maghrib -> Midnight):** Share `5` Suwayas (`0..4`, Night Suwayas `01..05 🌑`) proportionally based on their real durations.


* **Period 3 (Second Half of the Night: Midnight -> Fajr):** Always contains `6` Suwayas (`5..10`, Night Suwayas `06..11 🌑`).


* **Period 4 (Fajr -> Sunrise):** Always contains `1` Suwaya (`11`, Night Suwaya `12 🌑`).




2. **Day Phase Total = 12 Suwayas (Global Indices `12..23`)**:


* Distributed across Period 5 (`daySunriseDhuhr`), Period 6 (`dayDhuhrAsr`), and Period 7 (`dayAsrMaghrib`) so that their sum always equals `12` Suwayas (`01..12 ☀️`).




3. **Total Cycle Suwayas = 24 Suwayas**.



## 7. Second-Half Night Division (`NightPart` — Qiyam Parts)

Because the first half of the night (Maghrib to Midnight) is already represented by Period 1 (`nightMaghribIsha`) and Period 2 (`nightIshaMidnight`), `NightDivision` focuses exclusively on the **5 canonical Qiyam parts** within the second half of the night (**Period 3: Astronomical Midnight to Fajr**, spanning 6 Suwayas):

| ID | Localization Key | Duration in Suwayas | Suwaya Start | Suwaya End | Global Indices |
| --- | --- | --- | --- | --- | --- |
| `half_2` | `night_parts.half_2` (Second Half of the Night) | **6 Suwayas** | `06|00 🌑` | `11|59 🌑` (Fajr) | `5 .. 10`<br> |
| `third_3` | `night_parts.third_3` (Last Third of the Night) | **4 Suwayas** | `08|00 🌑` | `11|59 🌑` (Fajr) | `7 .. 10`<br> |
| `sixth_4` | `night_parts.sixth_4` (Fourth Sixth of the Night) | **2 Suwayas** | `06|00 🌑` | `07|59 🌑` | `5 .. 6`<br> |
| `sixth_5` | `night_parts.sixth_5` (Fifth Sixth of the Night) | **2 Suwayas** | `08|00 🌑` | `09|59 🌑` | `7 .. 8`<br> |
| `sixth_6` | `night_parts.sixth_6` (Sixth Sixth of the Night) | **2 Suwayas** | `10|00 🌑` | `11|59 🌑` (Fajr) | `9 .. 10`<br> |

### Smart Conflict Resolution Rules

Since these 5 parts represent overlapping slices of the same 6-Suwaya window (`Midnight -> Fajr`), the application enforces mutual exclusivity when toggling visible night parts and dial markers:

* Selecting `third_3` (4 Suwayas: `08..11 🌑`) automatically deselects `sixth_5` and `sixth_6` (and vice versa).


* Selecting `half_2` (all 6 Suwayas: `06..11 🌑`) automatically deselects `sixth_4` (and overlapping subdivisions).



## 8. Real Suwaya Duration and Flow Speed (`PeriodMetrics`)

For any `AstroPeriod` with real duration `period.totalDuration` and `suwayasCount = n`:

```text
actualSuwayaDuration = period.totalDuration / n

```

Because 1 Suwaya equals **60 virtual minutes (3,600 virtual seconds)**, the virtual time flow speed is:

```text
flowSpeed = 3600 / actualSuwayaDurationInSeconds

```

Interpretation:

* **`flowSpeed == 1.00x`**: 1 Suwaya lasts 60 real minutes. Virtual time and civil time move at the exact same pace.


* **`flowSpeed > 1.00x`** (e.g., `1.25x`): The real Suwaya is shorter than 60 real minutes (48 real minutes). Virtual time flows faster than civil time.


* **`flowSpeed < 1.00x`** (e.g., `0.80x`): The real Suwaya is longer than 60 real minutes (75 real minutes). Virtual time flows more slowly than civil time.



## 9. `SuwayaClockTime` and Virtual Time Formatting

At any timestamp `now`, `SuwayaTimeEngine.calculateCurrentState(day, now)` computes `currentSuwayaTime` (`SuwayaClockTime`):

* `phase`: `SuwayaPhase.night` or `SuwayaPhase.day`.


* `phaseSlotNumber`: `1` to `12` within the active phase.


* `periodLocalSlotNumber`: `1` to `period.suwayasCount` within the active period.


* `virtualMinute`: `0` to `59` within the current Suwaya.



### Visual Formatting Standard (`formatSuwayaTime`)

Suwaya time uses the vertical bar separator `|` to distinguish it visually from civil time (`:`):

* **Emoji Mode (`suwayaIconMode == 'emoji'`)**:


* Night: `04|15 🌑` (LTR) or `🌑 04|15` (RTL)


* Day: `09|42 ☀️` (LTR) or `☀️ 09|42` (RTL)




* **Text Mode (`suwayaIconMode == 'text'`)**:


* Uses `ل` / `ن` in Arabic (`RTL`) and `N` / `D` in `LTR` locales.




* **Color Coding**:


* Suwaya time is rendered in **Astro Gold (`#F2C94C`)**, while civil time is rendered in white/neutral surface text.





## 10. Resolving Scheduled Suwaya Times (`routine_time_resolver.dart`)

When a task or routine is scheduled at `(period, localSuwaya, virtualMinute)`, its exact real `DateTime` is resolved using integer microsecond arithmetic:

```dart
final count = period.suwayasCount > 0 ? period.suwayasCount : 1;
final suwayaIndex = (localSuwaya - 1).clamp(0, count - 1);
final minute = virtualMinute.clamp(0, 59);

final periodDuration = period.totalDuration.inMicroseconds;
final denominator = count * 60;
final requestedUnits = suwayaIndex * 60 + minute;
final offsetMicroseconds = (periodDuration * requestedUnits + denominator - 1) ~/ denominator;

final realTime = period.startTime.add(Duration(microseconds: offsetMicroseconds));

```

## 11. Flutter Runtime Adapter (`AstroNotifier`)

Located at `lib/core/astro_engine/astro_provider.dart`, `AstroNotifier` bridges `SuwayaTimeEngine` with Flutter:

1. **Settings Fingerprint:** Watches location coordinates, timezone, calculation method, Madhab, high-latitude rule, custom angles, and manual offsets.


2. **Maghrib-to-Maghrib Cycle Selection:**
* Evaluates today's Maghrib (`tempIbadat.maghrib`).


* If `cityNow.isBefore(tempIbadat.maghrib)`, it generates the cycle anchored to **yesterday's Maghrib** (`cityNow.subtract(const Duration(days: 1))`).


* Otherwise, it generates the cycle anchored to **today's Maghrib**.




3. **In-Memory Day Cache:** Caches up to 3 generated `SuwayaDay` instances keyed by `YYYY-M-D_fingerprint`.


4. **Dual-Timer Architecture:**
* **Smart State Timer (`_stateTimer`):** Sleeps until the exact microsecond of the next Suwaya boundary (or `cycleAnchors.cycleEndMaghrib`), rebuilding Riverpod providers only when `currentPeriod.id` or `periodLocalSlotNumber` changes.


* **1-Second UI Ticker (`_uiTimer`):** Updates `virtualDateTimeNotifier` and `virtualTimeNotifier` every second so the central dial and live clocks tick smoothly without triggering full widget-tree rebuilds.





## 12. Invariants to Preserve

1. The astronomical cycle starts at `maghrib` and ends at `cycleEndMaghrib` (next day's Maghrib).


2. Each cycle produces 7 contiguous periods with no gaps or overlaps.


3. The Night phase (`maghrib` -> `sunrise`) always totals **12 Suwayas** (global indices `0..11`).


4. The Day phase (`sunrise` -> `nextMaghrib`) always totals **12 Suwayas** (global indices `12..23`).


5. The full cycle always totals **24 Suwayas**.


6. Each Suwaya consists of **60 virtual minutes** (`0..59`), or `3,600` virtual seconds.


7. Period 3 (`nightMidnightFajr`) has `6` Suwayas and Period 4 (`nightFajrSunrise`) has `1` Suwaya.


8. Qiyam night parts are strictly the 5 second-half parts (`half_2`, `third_3`, `sixth_4`, `sixth_5`, `sixth_6`) within Period 3.


9. Manual offsets are clamped to `[-30, +30]` minutes and never apply to `sunrise`.


10. `packages/suwaya_time` remains 100% pure Dart with zero Flutter or Riverpod dependencies.
