# Suwaya Time Engine (`packages/suwaya_time`)

A comprehensive architectural and mathematical specification for Suwaya's astronomical temporal kernel (**Schedule Model V2 / Solid Core**). The `packages/suwaya_time` package is a 100% pure Dart temporal engine that transforms solar events, prayer timings, and regional calendars into a deterministic 24-Suwaya virtual day (12 Night Suwayas and 12 Day Suwayas), designed to power mobile applications, wearables, calendar integrations, and cloud/edge APIs.

> **Model Version:** `scheduleModelVersion = 2` (Kernel Architecture v2.1)

## Contents

 1. [Core Philosophy & Temporal Model](#1-core-philosophy--temporal-model)

 2. [Four-Layer Kernel Architecture](#2-four-layer-kernel-architecture)

 3. [Strict Temporal Primitives (`temporal_primitives.dart`)](#3-strict-temporal-primitives-temporal_primitivesdart)

 4. [Astronomical & Calendar Inputs](#4-astronomical--calendar-inputs)

 5. [The Seven Astronomical Periods & Allocation Modes](#5-the-seven-astronomical-periods--allocation-modes)

 6. [Second-Half Night Division (`NightPart` — Qiyam Parts)](#6-second-half-night-division-nightpart--qiyam-parts)

 7. [Bi-Directional Coordinate Mapping (`SuwayaCoordinateMapper`)](#7-bi-directional-coordinate-mapping-suwayacoordinatemapper)

 8. [Polar Resilience & Topocentric Elevation (`PolarCycleSynthesizer`)](#8-polar-resilience--topocentric-elevation-polarcyclesynthesizer)

 9. [Unified Temporal Context & \$O(1)$ Caching (`TemporalContextEngine`)](#9-unified-temporal-context--o1-caching-temporalcontextengine)

10. [Islamic Seasonal & Fasting Catalog (`IslamicEventsCatalog`)](#10-islamic-seasonal--fasting-catalog-islamiceventscatalog)

11. [Suwaya Flow & Focus Planner (`SuwayaFlowPlanner`)](#11-suwaya-flow--focus-planner-suwayaflowplanner)

12. [Multi-Day Recurrence & Collision Resolution (`SuwayaRecurrenceEngine`)](#12-multi-day-recurrence--collision-resolution-suwayarecurrenceengine)

13. [47-Bit Binary Codec & ISO-Suwaya Grammar (`SuwayaBinaryCodec`)](#13-47-bit-binary-codec--iso-suwaya-grammar-suwayabinarycodec)

14. [RFC 5545 iCalendar Exporter (`SuwayaIcsExporter`)](#14-rfc-5545-icalendar-exporter-suwayaicsexporter)

15. [Flutter Runtime Adapter & Adaptive Virtual-Second Ticker](#15-flutter-runtime-adapter--adaptive-virtual-second-ticker)

16. [Mathematical Invariants & Torture Test Matrix](#16-mathematical-invariants--torture-test-matrix)

## 1. Core Philosophy & Temporal Model

Civil time divides the solar day into 24 fixed 60-minute hours anchored at midnight (`00:00`). Suwaya models the natural astronomical and Islamic cycle—where night precedes day (**Maghrib to the following Maghrib**)—and divides it into 7 contiguous periods anchored by solar and prayer events:

```
Geographic Coordinates + Instant (UTC) + Calculation Parameters
                               |
                               v
     True UTC Solar & Prayer Anchors (DST-Immune Instants)
                               |
                               v
          Active Maghrib-to-Maghrib Astronomical Cycle
                               |
                               v
        7 Contiguous Periods (4 Night Periods | 3 Day Periods)
                               |
                               v
   24 Virtual Suwayas (12 Night Suwayas | 12 Day Suwayas)
   Each Suwaya = 60 Virtual Minutes = 3,600 Virtual Seconds

```

### Fundamental Definitions

* **Astronomical Cycle:** Runs from active Maghrib (`cycleStartMaghribUtc`) to the next day's Maghrib (`cycleEndMaghribUtc`).

* **Suwaya (سُويعَة):** A flexible astronomical hour representing exactly **60 virtual minutes** ($3600$ virtual seconds). Its physical duration expands and contracts according to the real duration of the period containing it.

* **Two 12-Suwaya Phases:**

  * **Night Phase (`SuwayaPhase.night`):** Spans from Maghrib to Sunrise. Contains **12 Suwayas** numbered `01` to `12` (`🌑` / `ل` / `N`), corresponding to global indices `0..11`.

  * **Day Phase (`SuwayaPhase.day`):** Spans from Sunrise to the next Maghrib. Contains **12 Suwayas** numbered `01` to `12` (`☀️` / `ن` / `D`), corresponding to global indices `12..23`.

* **Total Virtual Day:**
  

  $$
  24 \text{ Suwayas} \times 60 \text{ Virtual Minutes} = 1440 \text{ Virtual Minutes} = 86400 \text{ Virtual Seconds}
  $$

* **Flow Speed (`timeSpeedMultiplier` / `flowSpeed`):** The ratio of virtual seconds to physical seconds within a given period:
  

  $$
  \text{Flow Speed} = \frac{3600}{\text{Actual Suwaya Duration in Physical Seconds}}
  $$

## 2. Four-Layer Kernel Architecture

The `packages/suwaya_time` package is organized into four pure-Dart layers with zero dependencies on Flutter, Riverpod, `BuildContext`, or platform channels:

```
packages/suwaya_time/lib/
├── suwaya_time.dart                       # Public barrel export
└── src/
    ├── models/                            # Layer 1: Strict Primitives & Domain Models
    │   ├── temporal_primitives.dart       # InstantUtc, ZonedWallTime, SuwayaCoordinate
    │   └── astro_models.dart              # SuwayaDay, AstroPeriod, IbadatTimings, AstroState
    ├── calculators/                       # Layer 2: Ephemeris, Polar & Seasonal Calculators
    │   ├── prayer_calculator.dart         # 14 calculation methods, manual offsets, UTC anchors
    │   ├── polar_cycle_synthesizer.dart   # High-latitude (> 65 deg) cycle synthesis
    │   ├── night_division.dart            # 5 canonical second-half Qiyam subdivisions
    │   └── islamic_events_catalog.dart    # White Days, Arafah, Ashura, Tasu'a & Tashreeq rules
    ├── generators/                        # Layer 2: Period & Slot Generators
    │   ├── suwaya_distributor.dart        # Canonical Madhab & Dynamic Proportional allocation
    │   └── period_generator.dart          # Contiguous 7-period builder
    └── engine/                            # Layer 3 & 4: Context, Mapping, Flow, RRule & Codecs
        ├── suwaya_time_engine.dart        # Cycle generation & state calculation
        ├── temporal_context_engine.dart   # Unified civil/Islamic context & O(1) LRU cache
        ├── suwaya_coordinate_mapper.dart  # Bi-directional microsecond coordinate resolution
        ├── suwaya_flow_planner.dart       # Suwaya Pomodoro flow calculator & live evaluator
        ├── suwaya_recurrence_engine.dart  # Multi-day window planner & collision resolver
        ├── suwaya_binary_codec.dart       # 47-bit integer packing & ISO-Suwaya parser
        ├── suwaya_ics_exporter.dart       # RFC 5545 iCalendar (.ics) generator
        └── suwaya_live_clock.dart         # Pure Dart reactive virtual-second stream

```

## 3. Strict Temporal Primitives (`temporal_primitives.dart`)

To prevent wall-clock vs. UTC ambiguity across Daylight Saving Time (DST) transitions, the kernel defines three immutable value objects:

### 3.1 `InstantUtc`

Wraps `int epochMicroseconds` in UTC. Guarantees that all physical duration calculations ($\Delta t = t_2 - t_1$) are immune to local clock shifts.

### 3.2 `ZonedWallTime`

Pairs an `InstantUtc instant` with its resolved `Duration utcOffset`, `String? timezoneId`, and `bool isDaylightSavingTime`. Exposes local calendar getters (`year`, `month`, `day`, `hour`, `minute`, `second`, `weekday`) via `wallClockProjection` while computing `realDifference(other)` strictly in UTC microseconds.

### 3.3 `SuwayaCoordinate`

A complete, self-contained address in Suwaya time:

* `globalSlotIndex`: `0..23` (`0..11` Night, `12..23` Day).

* `phase`: `SuwayaPhase.night` or `SuwayaPhase.day`.

* `phaseSlotNumber`: `1..12`.

* `periodId`: `1..7` and `periodKey`: `PeriodKey`.

* `periodLocalSlotNumber`: `1..suwayasCount`.

* `virtualMinute`: `0..59` and `virtualSecond`: `0..59`.

* `slotProgress`: $0.0 \le p < 1.0$.

* `totalVirtualMinutes`: `0..1439` and `totalVirtualSeconds`: `0..86399`.

## 4. Astronomical & Calendar Inputs

### 4.1 Calculation Methods (`CalculationMethodType`)

Supports 14 international standards:
`muslimWorldLeague`, `egyptian`, `karachi`, `ummAlQura`, `dubai`, `northAmerica`, `kuwait`, `qatar`, `singapore`, `tehran`, `turkey`, `franceUoif` ($12^\circ / 12^\circ$), `russia` ($16^\circ / 15^\circ$), and `custom` (configurable Fajr and Isha depression angles between $10.0^\circ$ and $20.0^\circ$).

### 4.2 Madhab (`MadhabType`) & High-Latitude Rules (`HighLatitudeRuleType`)

* **Madhab:** `shafi` (standard shadow factor $1$) and `hanafi` (shadow factor $2$, later Asr).

* **High-Latitude Rules:** `middleOfTheNight`, `seventhOfTheNight`, and `twilightAngle`.

### 4.3 Manual Prayer Offsets & Sunrise Protection

Manual offsets are supplied via `Map<PrayerKey, int>` and clamped to:

$$
-30 \text{ minutes} \le \text{offset} \le +30 \text{ minutes}
$$

* Manual offsets **never** apply to `PrayerKey.sunrise`.

* **Crucial Distinction:** `IbadatTimings` and `SuwayaCycleAnchors` preserve both the user-adjusted Maghrib (`maghrib`) and the pure astronomical sunset (`calculatedSunset` / `calculatedStartSunsetUtc`). The Hijri date transitions at pure astronomical sunset regardless of manual Adhan offsets.

## 5. The Seven Astronomical Periods & Zonal Distribution Standard

`PeriodGenerator` divides the Maghrib-to-Maghrib cycle into **7 contiguous periods** (`id` 1 to 7) totaling **24 Suwayas** (12 Night Suwayas and 12 Day Suwayas):

| ID | `PeriodKey` | Phase | Name Key | Start Anchor | End Anchor | Zone 1 & 3 (`<= 48.56°`, `> 66.56°`) Jumhur / Hanafi | Zone 2 (`48.56°..66.56°`) Summer Jumhur / Hanafi | Zone 2 (`48.56°..66.56°`) Winter Jumhur / Hanafi |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `nightMaghribIsha` | Night (`🌑`) | `periods.maghrib` | Maghrib | Isha | `1` / `1` | `2` / `2` | `1` / `1` |
| 2 | `nightIshaMidnight` | Night (`🌑`) | `periods.isha` | Isha | Shar'i Midnight | `4` / `4` | `3` / `3` | `4` / `4` |
| 3 | `nightMidnightFajr` | Night (`🌑`) | `periods.qiyam` | Shar'i Midnight | Fajr | **6** / **6** | **6** / **6** | **6** / **6** |
| 4 | `nightFajrSunrise` | Night (`🌑`) | `periods.fajr` | Fajr | Sunrise | **1** / **1** | **1** / **1** | **1** / **1** |
| 5 | `daySunriseDhuhr` | Day (`☀️`) | `periods.duha` | Sunrise | Dhuhr | **6** / **6** | **6** / **6** | **6** / **6** |
| 6 | `dayDhuhrAsr` | Day (`☀️`) | `periods.dhuhr` | Dhuhr | Asr | `3` / `4` | `3` / `4` | `2` / `3` |
| 7 | `dayAsrMaghrib` | Day (`☀️`) | `periods.asr` | Asr | Next Maghrib | `3` / `2` | `3` / `2` | `4` / `3` |

### Unified Zonal & Bi-Annual Standard (`SuwayaDistributor`)

1. **Temperate & High-Lat Zone 1 ($|\phi| \le 48.56^\circ$) and Polar Zone 3 ($|\phi| > 66.56^\circ$, projected to $45^\circ$):**
   Applies the fixed year-round canonical distributions:
   * **Jumhur (Shafi / Maliki / Hanbali):** `[1, 4, 6, 1, 6, 3, 3]`
   * **Hanafi:** `[1, 4, 6, 1, 6, 4, 2]`
2. **High-Lat Zone 2 ($48.56^\circ < |\phi| \le 66.56^\circ$):**
   Switches twice a year at the Spring and Autumn Equinoxes (`Daylight >= Night` vs. `Night > Daylight`):
   * **Summer Half-Year:** `[2, 3, 6, 1, 6, 3, 3]` (Jumhur) and `[2, 3, 6, 1, 6, 4, 2]` (Hanafi) to absorb extended summer twilight.
   * **Winter Half-Year:** `[1, 4, 6, 1, 6, 2, 4]` (Jumhur) and `[1, 4, 6, 1, 6, 3, 3]` (Hanafi) to balance low-solar-altitude afternoon intervals and keep flow speeds near $1.00\text{x}$.

## 6. Second-Half Night Division (`NightPart` — Qiyam Parts)

`NightDivision.calculateNightParts` computes the **5 canonical Qiyam subdivisions** within the second half of the night (**Period 3: Shar'i Midnight to Fajr**, spanning 6 Night Suwayas `06|00 🌑` to `11|59 🌑`) using true UTC microsecond spans:

| ID | Localization Key | Duration in Suwayas | Suwaya Start | Suwaya End | Global Indices | 
| ----- | ----- | ----- | ----- | ----- | ----- | 
| `half_2` | `night_parts.half_2` | **6 Suwayas** | \`06 | 00 🌑\` | \`11 | 
| `third_3` | `night_parts.third_3` | **4 Suwayas** | \`08 | 00 🌑\` | \`11 | 
| `sixth_4` | `night_parts.sixth_4` | **2 Suwayas** | \`06 | 00 🌑\` | \`07 | 
| `sixth_5` | `night_parts.sixth_5` | **2 Suwayas** | \`08 | 00 🌑\` | \`09 | 
| `sixth_6` | `night_parts.sixth_6` | **2 Suwayas** | \`10 | 00 🌑\` | \`11 | 

## 7. Bi-Directional Coordinate Mapping (`SuwayaCoordinateMapper`)

`SuwayaCoordinateMapper` centralizes all forward and reverse conversions between physical time and Suwaya coordinates, guaranteeing **Round-Trip Microsecond Identity**:

$$
\text{instantToCoordinate}\big(\text{coordinateToInstant}(G, M, S)\big) = (G, M, S)
$$

### Key Operations

* **Forward Resolution (`instantToCoordinate`):**
  Given a `SuwayaDay` and an instant (`nowUtc`), computes the exact `SuwayaCoordinate` using 64-bit integer microsecond math:
  

  $$
  \text{currentVirtualSecond} = \left\lfloor \frac{\text{elapsedMicro} \times (\text{suwayasCount} \times 3600)}{\text{periodMicro}} \right\rfloor
  $$

* **Reverse Resolution (`coordinateToInstant` & `periodSlotToInstant`):**
  Resolves any `(globalSlotIndex, virtualMinute, virtualSecond)` or `(period, localSuwaya, virtualMinute, virtualSecond)` to its exact `instantUtc` and local `wallTime` using ceiling integer division:
  

  $$
  \text{offsetMicro} = \left\lfloor \frac{\text{periodMicro} \times \text{requestedVirtualSeconds} + \text{totalVirtualSeconds} - 1}{\text{totalVirtualSeconds}} \right\rfloor
  $$

* **Slot Normalization:**

  * `globalToLocal(globalSlotIndex, periods)` $\leftrightarrow$ `localToGlobal(periodId, localSuwaya, periods)`

  * `uiPhaseToGlobal(uiHour, isNight)` $\leftrightarrow$ `globalToUiPhase(globalSlotIndex)`

  * `fixedBoundaryCoordinate(identifier, periods, isEnd: ...)`

  * `formatParts(...)` and `formatString(...)`

## 8. Polar Resilience & Topocentric Elevation (`PolarCycleSynthesizer`)

### 8.1 Extreme High-Latitude Synthesis ($\vert{}\text{lat}\vert{} > 65^\circ$)

In polar regions (such as Tromsø, Norway at $69.65^\circ\text{N}$ or extreme southern latitudes) during summer midnight sun or winter polar night, standard solar depression angles may fail to intersect the horizon or produce inverted timestamps.

`PrayerCalculator.getCycleAnchors` automatically passes raw anchors through `PolarCycleSynthesizer.ensureValidAnchors`:

1. Verifies `isValidSequence` and checks that the total cycle span falls within $20\text{h} \le \Delta t \le 28\text{h}$.

2. **`PolarResolutionPolicy.nearestLatitude45` (Default):** Projects solar timings from the nearest temperate parallel ($\pm 45.0^\circ$ latitude) at the same longitude and IANA timezone.

3. **`PolarResolutionPolicy.equinoxProportional` (Fallback):** Synthesizes a balanced 24-hour cycle anchored at local 18:00 so `PeriodGenerator` never throws an exception and always produces 7 valid periods and 24 Suwayas.

### 8.2 Topocentric Elevation Dip (`TimezoneResolver.elevationDipTimeAdjustment`)

For high-altitude cities, horizon dip is calculated as:

$$
\Delta \theta \approx 0.0347^\circ \times \sqrt{h_{\text{meters}}}
$$


translating to earlier sunrise and later astronomical sunset proportional to $\frac{4.0 \times \Delta \theta}{\cos(\text{lat})}$.

## 9. Unified Temporal Context & $O(1)$ Caching (`TemporalContextEngine`)

`TemporalContextEngine.evaluate` is the single entry point for evaluating any moment in time:

```
final context = TemporalContextEngine.evaluate(
  instantUtc: DateTime.now().toUtc(),
  latitude: 21.4225,
  longitude: 39.8262,
  timezoneId: 'Asia/Riyadh',
  methodType: CalculationMethodType.ummAlQura,
  madhabType: MadhabType.shafi,
  hijriAdjustmentDays: 0,
);

```

### Dual Date Separation

`SuwayaTemporalContext` simultaneously resolves two distinct logical dates:

1. **`civilDate` & `civilWeekday`:** Advances at local midnight (`00:00`). Used for civil tasks, civil routines, and `civilDayIbadat` (displaying today's 5 prayers on the Ibadat screen even before Maghrib).

2. **`islamicLogicalGregorianDate`, `islamicWeekday`, & `hijriDate`:** Advances at **astronomical sunset** (`calculatedSunset`) and **does not** double-advance at `00:00` midnight.

### Built-In Multi-City LRU Cache

* `TimezoneResolver` maintains a 32-entry LRU cache of resolved IANA `tz.Location` objects.

* `TemporalContextEngine` maintains a 24-entry LRU cache for `SuwayaDay` cycles and `IbadatTimings`, turning repeated evaluations for the same day/location into sub-microsecond $O(1)$ lookups.

## 10. Islamic Seasonal & Fasting Catalog (`IslamicEventsCatalog`)

`IslamicEventsCatalog.evaluateFastingForHijri` provides pure-domain evaluation of voluntary and seasonal fasting days:

* **Day of Arafah:** 9 Dhu al-Hijjah (`IslamicFastingType.arafah`).

* **Day of Ashura & Tasu'a:** 10 & 9 Muharram (`IslamicFastingType.ashura`, `IslamicFastingType.tasua`).

* **White Days (الأيام البيض):** 13, 14, and 15 of every Hijri month (`IslamicFastingType.whiteDays`), while **strictly excluding** Ramadan (month 9) and the 13th of Dhu al-Hijjah (the 3rd day of Tashreeq, when voluntary fasting is prohibited).

## 11. Suwaya Flow & Focus Planner (`SuwayaFlowPlanner`)

`SuwayaFlowPlanner` powers **Suwaya Pomodoro** sessions synchronized with prayer boundaries:

1. **`calculateFlowOptions(startTime, endTime)`:**
   Given an anchored start time and a target end time (e.g., the next mandatory prayer resolved via `resolveNextCyclePrayer`), finds all integer Pomodoro counts $N \in [1, 48]$ (each consisting of $25$ virtual work minutes + $5$ virtual break minutes = $1800$ virtual seconds) whose required flow speed $v$ satisfies:
   

   $$
   v = \frac{N \times 1800}{\Delta t_{\text{actualSeconds}}} \in [0.50\text{x}, 2.00\text{x}]
   $$

   
   Returns up to 3 options ordered with the speed closest to $1.00\text{x}$ first (`tag: 'recommended'`), followed by `'slower'` ($N - 1$) and `'faster'` ($N + 1$).

2. **`evaluateLiveSession(...)`:**
   Computes the real-time `SuwayaFlowLiveSnapshot` (current cycle, work vs. break phase, remaining virtual seconds, progress ratios, and the 120-second `isPrePrayerWarningActive` flag) directly from UTC timestamps.

## 12. Multi-Day Recurrence & Collision Resolution (`SuwayaRecurrenceEngine`)

`SuwayaRecurrenceEngine` provides background-isolate-ready scheduling primitives:

* **`generateMultiDayWindows(...)`:** Generates an 8-day rolling window (`dayOffset` from `-1` to `+6`) of `SuwayaScheduledDayWindow` objects with full DST transition awareness.

* **`stableNightPartCode(nightPartId)`:** Maps canonical Qiyam IDs (`half_2`, `third_3`, `sixth_4`, `sixth_5`, `sixth_6`) to deterministic integer codes (`12`, `23`, `34`, `35`, `36`), avoiding non-deterministic `String.hashCode` across isolates and app restarts.

* **`resolveCollisionSafeTime(desiredTime, occupiedEpochSeconds)`:** Guarantees that mandatory Adhan alerts fire at $+0\text{s}$ while staggering any coinciding routine or task alerts by $+2\text{s}$ increments (capped at $+30\text{s}$).

## 13. 47-Bit Binary Codec & ISO-Suwaya Grammar (`SuwayaBinaryCodec`)

For high-performance database indexing, WebAssembly/JavaScript interoperability (within IEEE 754's 53-bit safe integer limit), and REST APIs, `SuwayaBinaryCodec` provides:

### 13.1 47-Bit Integer Packing (`pack` / `unpack`)

Packs a complete Hijri date and `SuwayaCoordinate` into a single 47-bit integer that preserves chronological sort order (`a < b`):

| Bits | Width | Field | Range | 
| ----- | ----- | ----- | ----- | 
| `0..5` | 6 bits | `virtualSecond` | `0..59` | 
| `6..11` | 6 bits | `virtualMinute` | `0..59` | 
| `12..15` | 4 bits | `periodLocalSlotNumber` | `1..12` | 
| `16..18` | 3 bits | `periodId` | `1..7` | 
| `19..23` | 5 bits | `globalSlotIndex` | `0..23` | 
| `24..28` | 5 bits | `hijriDay` | `1..30` | 
| `29..32` | 4 bits | `hijriMonth` | `1..12` | 
| `33..46` | 14 bits | `hijriYear` | `0..16383` | 

### 13.2 ISO-Suwaya String Grammar (`toIsoSuwayaString` / `tryParseIsoSuwaya`)

Formats and parses standardized strings of the form:

* `SWY-N04:15` or `SWY-N04:15:30` (4th Night Suwaya, 15m 30s)

* `SWY-D09:42` or `SWY-D09:42:00` (9th Day Suwaya, 42m 00s)

## 14. RFC 5545 iCalendar Exporter (`SuwayaIcsExporter`)

`SuwayaIcsExporter.exportWindowsToIcs` serializes multi-day `SuwayaScheduledDayWindow` lists into standard RFC 5545 `VCALENDAR` / `VEVENT` payloads (`.ics`), allowing users and external tools to subscribe to Suwaya periods and Qiyam parts in Google Calendar, Apple Calendar, and Outlook.

## 15. Flutter Runtime Adapter & Adaptive Virtual-Second Ticker

In the Flutter application (`lib/core/astro_engine/astro_provider.dart`), `AstroNotifier` bridges `suwaya_time` with the UI using three coordinated mechanisms:

1. **Smart State Timer (`_stateTimer`):** Sleeps until the exact microsecond of the next Suwaya boundary (`durationUntilNextSuwaya`), rebuilding Riverpod consumers only when `currentPeriod.id` or `periodLocalSlotNumber` changes.

2. **Adaptive Virtual-Second UI Ticker (`_uiTimer`):** Instead of polling at a fixed `250ms` interval (which causes beat-frequency aliasing jitter when virtual seconds are faster or slower than physical seconds), `_startUITicker` computes the exact microsecond boundary of the **next virtual second** in the active period:
   

   $$
   \text{nextBoundaryMicro} = \left\lfloor \frac{(\text{currentVirtualSecIndex} + 1) \times \text{periodMicro} + \text{totalVirtualSeconds} - 1}{\text{totalVirtualSeconds}} \right\rfloor
   $$

   
   This eliminates visual jitter ($0\%$ aliasing) and reduces CPU wake-ups by up to $75\%$.

3. **Decoupled 15-Second Dial Quantizer (`dialQuantizedTimeNotifier`):** Updates the rotation angle of `PremiumAstroDial` once every 15 physical seconds ($0.06^\circ$ arc step) while `virtualTimeNotifier` ticks every virtual second for the central digital clock, preventing unnecessary `CustomPainter` rebuilds.

4. **Zero-Battery Background Lifecycle:** Both `_stateTimer` and `_uiTimer` are immediately canceled on `AppLifecycleState.paused` and `AppLifecycleState.hidden`, and resynchronized on `AppLifecycleState.resumed`.

## 16. Mathematical Invariants & Torture Test Matrix

Every change to `packages/suwaya_time` must pass the automated test suite (`dart test` in `packages/suwaya_time` and `flutter test` in root):

1. **Contiguity & Conservation:** Every generated day has exactly 7 periods with `periods[i].endUtc == periods[i + 1].startUtc` and $\sum \text{suwayasCount} = 24$ ($12$ Night + $12$ Day).

2. **Round-Trip Identity:** Across all $1440$ virtual minutes of the day (including Spring-Forward and Fall-Back DST nights), `instantToCoordinate(coordinateToInstant(G, M)) == (G, M)`.

3. **Strict Monotonicity (Zero-Retrograde):** Stepping forward in UTC from `cycleStartMaghribUtc` to `cycleEndMaghribUtc` produces strictly non-decreasing `totalVirtualSeconds` ($\text{sec}_{t+1} \ge \text{sec}_t$), even when local wall-clock time repeats an hour during Fall-Back DST.

4. **Polar Immunity:** For any latitude $\in [-89.9^\circ, +89.9^\circ]$ and any day of the year (tested via 250-iteration randomized fuzz testing), `SuwayaTimeEngine.generateDay` never throws and always yields positive microsecond durations.

5. **Offset Isolation:** Manual prayer offsets are clamped to $[-30, +30]$ minutes, never shift `sunrise`, and never alter `calculatedSunset` used for Hijri date rollover.