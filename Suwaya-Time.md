# Suwaya Time

A detailed reference for Suwaya's astronomical time system and the pure Dart `packages/suwaya_time` package. The package transforms changing prayer times and solar events into a virtual day made of 48 Suwayas.

> This document describes the behavior implemented in the current codebase. It is not a separate future specification.

## 1. Core Concept

Civil time measures the day with fixed clock hours. Suwaya starts from the local astronomical day and uses prayer times and solar events to divide it into meaningful periods:

```text
Location + date + calculation settings
                 |
                 v
          Prayer and solar times
                 |
                 v
       From today's Fajr to next Fajr
                 |
                 v
       Seven contiguous astronomical periods
                 |
                 v
       48-Suwaya distribution across periods
                 |
                 v
       Current Suwaya and virtual time
```

A Suwaya is not 30 real minutes. Each Suwaya represents 30 virtual minutes, while its real duration changes according to the length of the astronomical period that contains it.

Therefore:

- A complete virtual day contains 48 Suwayas.
- A complete virtual day equals 48 x 30 minutes = 1,440 minutes = 24 virtual hours.
- The real Fajr-to-Fajr day changes with location, date, and season.
- The speed of virtual time changes from one period to another.

## 2. Package Components

The main source is located under `packages/suwaya_time/lib/`:

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

The package is pure Dart. It does not depend on Flutter, Riverpod, `BuildContext`, or platform services. Prayer calculations use the `adhan` package.

The public library exports:

- Models: `AstroPeriod`, `NightPart`, `IbadatTimings`, `SuwayaDay`, and `AstroState`.
- Engine: `SuwayaTimeEngine`.
- Calculators: `PrayerCalculator` and `NightDivision`.
- Generators: `PeriodGenerator` and `SuwayaDistributor`.
- Configuration types: `CalculationMethodType`, `MadhabType`, `HighLatitudeRuleType`, and `PrayerKey`.

## 3. Calculation Inputs

The engine generates a day from the following inputs:

| Input | Type | Meaning |
|---|---|---|
| `lat` | `double` | Latitude in degrees |
| `lng` | `double` | Longitude in degrees |
| `date` | `DateTime` | Date for which the day is calculated |
| `methodType` | `CalculationMethodType` | Prayer-time calculation method |
| `madhabType` | `MadhabType` | Asr calculation school |
| `highLatRuleType` | `HighLatitudeRuleType` | High-latitude adjustment rule |
| `customFajr` | `double` | Fajr angle when using the custom method |
| `customIsha` | `double` | Isha angle when using the custom method |
| `cityOffset` | `Duration` | Offset applied to `adhan` results |
| `distribution` | `List<int>` | Number of Suwayas assigned to each period |
| `manualOffsets` | `Map<PrayerKey, int>?` | Manual minute offsets for supported prayers |

The main call is:

```dart
final day = SuwayaTimeEngine.generateDay(
  latitude,
  longitude,
  date,
  method,
  madhab,
  highLatitudeRule,
  customFajrAngle,
  customIshaAngle,
  cityOffset,
  SuwayaDistributor.universalDistribution,
  manualOffsets: offsets,
);
```

## 4. Calculation Methods

The engine defines these calculation methods:

```dart
enum CalculationMethodType {
  muslimWorldLeague,
  egyptian,
  karachi,
  ummAlQura,
  dubai,
  northAmerica,
  kuwait,
  qatar,
  singapore,
  tehran,
  turkey,
  custom,
}
```

### 4.1 Current implementation

Inside `PrayerCalculator._getParams`, the current direct mapping is:

- `egyptian` uses `CalculationMethod.egyptian`.
- `ummAlQura` uses `CalculationMethod.umm_al_qura`.
- `karachi` uses `CalculationMethod.karachi`.
- `custom` uses `CalculationMethod.other`, then assigns the Fajr and Isha angles from the inputs.
- All other values, including `dubai`, `northAmerica`, `kuwait`, `qatar`, `singapore`, `tehran`, `turkey`, and `muslimWorldLeague`, currently use `CalculationMethod.muslim_world_league` through the `default` branch.

This means the additional method names exist in the model and UI, but they should not be treated as independent algorithms inside the package until explicit mappings are added to `PrayerCalculator`.

### 4.2 Madhab

The available schools are:

```dart
enum MadhabType { hanafi, shafi }
```

- `hanafi` configures `adhan` with `Madhab.hanafi`.
- `shafi` configures `adhan` with `Madhab.shafi`.

The Madhab primarily affects the Asr calculation.

### 4.3 High-latitude rules

```dart
enum HighLatitudeRuleType {
  middleOfTheNight,
  seventhOfTheNight,
  twilightAngle,
}
```

They map to `adhan` as follows:

| Suwaya value | Adhan value |
|---|---|
| `middleOfTheNight` | `middle_of_the_night` |
| `seventhOfTheNight` | `seventh_of_the_night` |
| `twilightAngle` | `twilight_angle` |

These rules are used when ordinary astronomical angles are difficult or impossible to calculate at high latitudes, such as during extremely short nights or long days.

### 4.4 Custom method

When `custom` is selected:

1. The engine starts from `CalculationMethod.other`.
2. It assigns `params.fajrAngle = customFajr`.
3. It assigns `params.ishaAngle = customIsha`.
4. It applies the Madhab and high-latitude rule afterward.

## 5. Prayer-Time Calculation

`PrayerCalculator.getIbadatTimings` creates two `adhan` calculations:

- One for the requested date.
- One for the following date to obtain `nextFajr`.

The resulting times are:

```text
fajr
sunrise
dhuhr
asr
maghrib
isha
nextFajr
```

After receiving the `adhan` results, the engine applies this operation to each time:

```text
Suwaya time = adhan time converted to UTC + cityOffset + manual offset, if any
```

In code:

```dart
time.toUtc().add(cityOffset)
```

Therefore, `cityOffset` must be compatible with the way the application represents time. The Flutter application calculates the offset for the active location and may use the timezone database for saved locations.

### 5.1 Sunrise

Sunrise is calculated and exposed in `IbadatTimings`, but it is not the beginning of an independent Suwaya period. Manual offsets are also not applied to sunrise.

### 5.2 Next Fajr

`nextFajr` is calculated using the following date:

```dart
final tomorrow = PrayerTimes(
  coordinates,
  DateComponents.from(date.add(const Duration(days: 1))),
  params,
);
```

The same manual Fajr offset is then applied to it, if one was provided.

## 6. Manual Offsets

Offsets can be supplied through `PrayerKey`:

```dart
enum PrayerKey {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha,
}
```

However, the internal validation allows manual offsets only for:

- Fajr.
- Dhuhr.
- Asr.
- Maghrib.
- Isha.

`sunrise` is intentionally rejected as a manual-offset target.

Every offset is clamped to:

```text
-30 minutes <= offset <= +30 minutes
```

Example:

```dart
manualOffsets: {
  PrayerKey.maghrib: 15,
  PrayerKey.isha: -5,
}
```

This results in:

- Maghrib being delayed by 15 minutes.
- Isha being advanced by 5 minutes.
- Asr, sunrise, Dhuhr, and Fajr remaining unchanged.
- Night-part boundaries moving with the new Maghrib time.

An offset does not recalculate the other prayers astronomically. It is a direct time adjustment applied only to the selected prayer.

## 7. Night Division

The Suwaya night begins at:

```text
Maghrib -> nextFajr
```

If:

```text
nightDuration = nextFajr - maghrib
```

then `NightDivision` creates 11 objects representing different views of the same night:

### Two halves

```text
half_1: from Maghrib to the midpoint of the night
half_2: from the midpoint to next Fajr
```

### Three thirds

```text
third_1: from Maghrib to one third of the night
third_2: from one third to two thirds
third_3: from two thirds to next Fajr
```

### Six sixths

```text
sixth_1 ... sixth_6
```

Each sixth equals `nightDuration / 6`.

The final list contains:

```text
2 halves + 3 thirds + 6 sixths = 11 parts
```

These are not 11 sequential periods that should be added together. The halves, thirds, and sixths are overlapping representations of the same night. Each group starts at Maghrib and ends at next Fajr.

The implementation uses integer microsecond division, so very small remainder differences may occur when the duration is divided.

## 8. The Seven Periods

`PeriodGenerator.generatePeriods` creates seven contiguous periods. The default distribution assigns each period this number of Suwayas:

| ID | Name | Start | End | Default count | Color |
|---:|---|---|---|---:|---|
| 1 | Fajr | Fajr | Midpoint between Fajr and Dhuhr | 7 | `0xFF64B5F6` |
| 2 | Duha | Midpoint between Fajr and Dhuhr | Dhuhr | 7 | `0xFFFFF176` |
| 3 | Dhuhr | Dhuhr | Asr | 7 | `0xFFFFCA28` |
| 4 | Asr | Asr | Maghrib | 6 | `0xFFFF9800` |
| 5 | Maghrib | Maghrib | First third of the night | 7 | `0xFFE53935` |
| 6 | Middle Third | First third of the night | Two thirds of the night | 7 | `0xFF1A237E` |
| 7 | Last Third | Two thirds of the night | Next Fajr | 7 | `0xFF311B92` |

### 8.1 Exact period boundaries

Let the prayer times be:

```text
F = fajr
S = sunrise
D = dhuhr
A = asr
M = maghrib
N = nextFajr
```

The engine calculates:

```text
mid = F + (D - F) / 2
nightDuration = N - M
third = nightDuration / 3
firstNightEnd = M + third
secondNightEnd = firstNightEnd + third
```

The periods are then:

```text
Period 1: F                 -> mid
Period 2: mid               -> D
Period 3: D                 -> A
Period 4: A                 -> M
Period 5: M                 -> firstNightEnd
Period 6: firstNightEnd     -> secondNightEnd
Period 7: secondNightEnd    -> N
```

Important notes:

- Sunrise `S` is not used as a period boundary.
- The Fajr period ends at the time midpoint between Fajr and Dhuhr, not at sunrise.
- The Duha period starts at that midpoint and ends at Dhuhr.
- The three night periods start at Maghrib and end at next Fajr.
- The current tests verify continuity and the absence of gaps or overlaps.

### 8.2 Custom distributions

The function accepts any `List<int>` supplied by the caller. The universal distribution is:

```dart
[7, 7, 7, 6, 7, 7, 7]
```

However, `PeriodGenerator` does not validate internally that:

- The list contains exactly seven elements.
- The values are non-negative.
- The total equals 48.

The caller must therefore provide a valid list of seven numbers whose total is 48. Test distributions such as `[5, 6, 9, 7, 3, 7, 11]` work because they total 48.

## 9. Universal Suwaya Distribution

The current official constant is:

```dart
static const List<int> universalDistribution = [7, 7, 7, 6, 7, 7, 7];
```

Its total is:

```text
7 + 7 + 7 + 6 + 7 + 7 + 7 = 48
```

Period allocation:

```text
Fajr          7 Suwayas
Duha          7 Suwayas
Dhuhr         7 Suwayas
Asr           6 Suwayas
Maghrib       7 Suwayas
Middle Third  7 Suwayas
Last Third    7 Suwayas
--------------------------------
Total         48 Suwayas
```

The distribution does not divide the real day into equal parts. It fixes the number of virtual units in each period and then calculates each Suwaya's real duration from its containing period.

## 10. Real Suwaya Duration

If a period has:

```text
periodDuration = endTime - startTime
```

and contains:

```text
suwayasCount = n
```

then the real duration of one Suwaya is:

```text
realSuwayaDuration = periodDuration / n
```

In microseconds, as implemented by the engine:

```text
suwayaDurationMicroseconds =
    periodDuration.inMicroseconds / n
```

Example:

```text
A 7-hour period with 7 Suwayas
Each real Suwaya = 1 hour
Each virtual Suwaya = 30 minutes
```

Another example:

```text
A 6-hour period with 6 Suwayas
Each real Suwaya = 1 hour
```

If the period length changes while its Suwaya count remains fixed, the virtual-time speed changes automatically.

## 11. Data Model

### `AstroPeriod`

Represents one period:

```dart
class AstroPeriod {
  final int id;
  final String name;
  final String nameKey;
  final DateTime startTime;
  final DateTime endTime;
  final int suwayasCount;
  final int colorValue;

  Duration get totalDuration => endTime.difference(startTime);
}
```

- `id`: Period number from 1 to 7.
- `name`: Default English name.
- `nameKey`: Localization key.
- `startTime` and `endTime`: Real-time period boundaries.
- `suwayasCount`: Number of virtual Suwayas in the period.
- `colorValue`: UI color value.
- `totalDuration`: Real duration of the period.

### `NightPart`

Represents one of the night-division views:

```dart
class NightPart {
  final String id;
  final String nameKey;
  final DateTime startTime;
  final DateTime endTime;
}
```

### `IbadatTimings`

Groups prayer times and night parts:

```dart
class IbadatTimings {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final DateTime nextFajr;
  final List<NightPart> nightParts;
}
```

### `SuwayaDay`

Represents a complete astronomical day:

```dart
class SuwayaDay {
  final IbadatTimings ibadatTimings;
  final List<AstroPeriod> periods;
}
```

### `AstroState`

Represents the current state at a given time:

```dart
class AstroState {
  final DateTime virtualTime;
  final List<AstroPeriod> periods;
  final AstroPeriod currentPeriod;
  final int currentSuwaya;
  final Duration elapsedVirtualTime;
  final double suwayaProgress;
  final double timeSpeedMultiplier;
  final IbadatTimings ibadatTimings;
  final String currentFormattedVirtualTime;
}
```

## 12. Day Generation

`SuwayaTimeEngine.generateDay` performs two steps:

```text
1. PrayerCalculator.getIbadatTimings(...)
2. PeriodGenerator.generatePeriods(ibadat, distribution)
```

It then returns:

```dart
SuwayaDay(
  ibadatTimings: ibadat,
  periods: periods,
)
```

This function does not calculate the current state. It creates the day's schedule. The current period and Suwaya are calculated by `calculateCurrentState`.

## 13. Current-State Calculation

Use:

```dart
final state = SuwayaTimeEngine.calculateCurrentState(day, now);
```

### 13.1 Selecting the current period

The engine searches for the first period satisfying:

```text
now >= period.startTime
and
now < period.endTime
```

The period start is inclusive and the period end is exclusive.

If no period is found:

- If `now` is before the first period, the first period is used.
- Otherwise, the last period is used.

This keeps the state displayable before Fajr or after next Fajr until the application selects the correct astronomical day.

### 13.2 Selecting the current Suwaya

Within the current period:

```text
elapsed = now - period.startTime
suwayaDuration = periodDuration / suwayasCount
```

Then:

```text
currentSuwaya = floor(elapsed / suwayaDuration) + 1
```

The result is clamped between:

```text
1 and suwayasCount
```

The Suwaya count therefore starts at 1 inside each period, not at 0.

### 13.3 Suwaya progress

Progress inside the current Suwaya is calculated as:

```text
progress =
  (elapsedMicroseconds modulo suwayaDurationMicroseconds)
  / suwayaDurationMicroseconds
```

The value is clamped between `0.0` and `1.0`.

Meaning:

- `0.0`: Start of the Suwaya.
- `0.5`: Middle of the Suwaya.
- Near `1.0`: End of the Suwaya.

### 13.4 Virtual time inside the Suwaya

Each Suwaya represents 1,800 virtual seconds, or 30 minutes:

```text
virtualElapsedSeconds = floor(progress x 1800)
```

### 13.5 Time speed

The Suwaya speed multiplier is calculated as:

```text
speedMultiplier = 1800 / realSuwayaDurationInSeconds
```

Interpretation:

- If the real Suwaya lasts 30 minutes, the multiplier is `1.0`.
- If the real Suwaya lasts one hour, the multiplier is `0.5`; virtual time moves more slowly than real time.
- If the real Suwaya lasts 15 minutes, the multiplier is `2.0`; virtual time moves faster than real time.

This multiplier does not change astronomical calculations. It describes how quickly a real period maps to a fixed 30-minute virtual unit.

## 14. Global Suwaya Index

To display continuous virtual time across the entire day, the engine adds the Suwaya counts from previous periods:

```text
globalSuwayaIndex = sum of previous period Suwayas
                    + currentSuwaya - 1
```

With the universal distribution:

```text
Period 1: indices 0..6
Period 2: indices 7..13
Period 3: indices 14..20
Period 4: indices 21..26
Period 5: indices 27..33
Period 6: indices 34..40
Period 7: indices 41..47
```

The internal global index starts at 0, while `currentSuwaya` starts at 1.

## 15. Virtual-Time Formatting

`currentFormattedVirtualTime` is built as:

```text
globalSuwayaIndex : virtual minutes inside the current Suwaya
```

The current format is:

```dart
'${globalSuwayaIndex.toString().padLeft(2, '0')}:$minutes'
```

Example:

```text
07:12
```

This means:

- The current Suwaya has global index 7.
- 12 virtual minutes have elapsed inside the current Suwaya.

The first component is not an ordinary civil clock hour. It is a global Suwaya index displayed in a clock-like format.

`elapsedVirtualTime` contains only the virtual time elapsed inside the current Suwaya, not the total virtual time since the beginning of the day.

## 16. Converting Any Time to Virtual Time

`AstroState.toVirtualTime(targetTime)` converts a real timestamp to continuous virtual time since the beginning of the first period.

Algorithm:

1. Iterate over the periods in order.
2. If the target time is after a period's end, add:

```text
period.suwayasCount x 30 minutes
```

3. If the target time is inside a period, calculate the period progress:

```text
progress = elapsedInsidePeriod / periodDuration
```

Then add:

```text
progress x (period.suwayasCount x 30 minutes)
```

4. Convert total virtual minutes to hours and minutes.

Current test example:

```text
Period from 05:00 to 12:00
7 Suwayas
Virtual duration = 7 x 30 = 210 minutes
```

At 08:30, the midpoint of the period:

```text
210 / 2 = 105 minutes = 01:45
```

At 12:00:

```text
210 minutes = 03:30
```

If the target reaches exactly the end of the virtual day, `24:00` is displayed as `00:00`.

## 17. `currentFormattedVirtualTime` vs. `toVirtualTime`

### `currentFormattedVirtualTime`

Produced inside `calculateCurrentState`. It uses:

- The global Suwaya index.
- Virtual minutes inside the current Suwaya.

Example:

```text
07:12
```

### `toVirtualTime`

Converts a target time to total virtual minutes since the beginning of the day, then displays those minutes as hours and minutes:

```text
01:45
03:30
```

The two outputs must not be assumed to have the same meaning. The first identifies the current Suwaya and its internal progress, while the second represents total virtual time since the beginning of the periods.

## 18. Flutter Adapter and Runtime Behavior

The Flutter adapter is located at:

```text
lib/core/astro_engine/astro_provider.dart
```

`AstroNotifier` does the following:

1. Watches the active location and calculation settings.
2. Builds a fingerprint containing:
   - Latitude.
   - Longitude.
   - Timezone.
   - Calculation method.
   - Madhab.
   - High-latitude rule.
   - Custom Fajr angle.
   - Custom Isha angle.
   - Manual period offsets.
3. Obtains the current time in the location's timezone.
4. Generates an astronomical day or retrieves it from a small cache.
5. Selects the previous day if the current time is before Fajr.
6. Selects the next day if the current time is at or after next Fajr.
7. Calculates `AstroState`.
8. Starts a smart update timer and a lightweight display ticker.

### 18.1 Cache

The application uses an in-memory cache with a key similar to:

```text
YYYY-M-D_fingerprint
```

It keeps a limited number of generated days. When the cache grows beyond the small configured limit, it is cleared and days are regenerated as needed.

### 18.2 Smart state timer

The smart timer does not run every second. It calculates the beginning of the next Suwaya and sleeps until then. It then:

1. Reads the current time.
2. Calculates the new state.
3. Compares the previous period and Suwaya identifiers.
4. Updates Riverpod state only when one of them changes.
5. Schedules the next wake-up.

### 18.3 Display ticker

A lightweight five-second ticker updates `virtualTimeNotifier`, the displayed virtual-time text, without rebuilding the complete application state.

The purpose is to separate:

- Important state updates at Suwaya boundaries.
- More frequent visible clock-text updates.

## 19. Time Before Fajr and After Next Fajr

`calculateCurrentState` alone handles times outside the period boundaries by using the first or last period. In the Flutter application, `AstroNotifier` also selects the correct day:

```text
If now < fajr:
    use yesterday

If now >= nextFajr:
    use tomorrow

Otherwise:
    use today
```

This matters because the Suwaya astronomical day is not necessarily midnight-to-midnight. It runs from Fajr to the following Fajr.

## 20. Failure States and Fallback

If the period list is empty, the engine returns `getFallbackState(now)`.

The fallback state contains:

- Prayer times approximately equal to the current time.
- `nextFajr` 24 hours later.
- One period lasting one hour.
- Seven Suwayas.
- Virtual time `00:00`.
- Speed multiplier `1.0`.

If an exception occurs while generating the day, `AstroNotifier` also returns a fallback state instead of allowing the entire application to fail.

This is a temporary availability state. It is not a valid astronomical result for decision-making.

## 21. Timezone Handling

The package itself does not manage a timezone database. It receives `cityOffset` as a `Duration` and applies it after converting `adhan` results to UTC.

In the Flutter layer:

- Automatic location may use the device timezone offset when appropriate.
- A saved location may use a named timezone through the `timezone` package.
- A timezone change becomes part of the `AstroNotifier` fingerprint, so the day is regenerated.

The local/UTC meaning of every `DateTime` must be clear when values cross layer boundaries. Mixing the two can produce calculations that are mathematically consistent but displayed in the wrong timezone.

The current daylight-saving test focuses on period continuity and the absence of gaps when the civil clock changes.

## 22. Cases Covered by Tests

The current tests cover:

- Ordering of Fajr, sunrise, and the remaining prayer times.
- The fixed number of night parts: 11.
- Generation of seven periods.
- Period continuity from Fajr to next Fajr.
- The absence of overlaps or negative durations.
- The universal distribution and its total of 48.
- Conversion from real time to virtual time.
- Manual offsets and their limited effect.
- High latitudes with very short or long nights.
- A simulated daylight-saving transition.
- February 29 and the transition of `nextFajr` to March 1.

Important test files:

```text
test/astro_engine_test.dart
test/astro/period_generation_test.dart
test/astro/suwaya_distribution_test.dart
test/astro/virtual_time_mapping_test.dart
test/astro/manual_offsets_test.dart
test/astro/polar_test.dart
test/astro/dst_test.dart
test/astro/leap_year_test.dart
```

## 23. Invariants to Preserve

When modifying the engine, preserve the following unless the design intentionally changes:

1. The default distribution contains seven periods.
2. The distribution total is 48.
3. The first period starts at `fajr`.
4. The last period ends at `nextFajr`.
5. Each period's end equals the next period's start.
6. Every period has a positive duration for valid input data.
7. Sunrise does not become an independent period without an explicit model change.
8. Manual offsets are limited to +/-30 minutes.
9. A manual offset does not propagate to other prayers.
10. Night is measured from Maghrib to next Fajr.
11. Each Suwaya represents 30 virtual minutes.
12. `currentSuwaya` starts at 1 within each period.
13. `suwayaProgress` stays between 0 and 1.
14. Pure calculation code does not depend on Flutter.

## 24. Complete Calculation Example

Assume the calculated astronomical results are:

```text
Fajr      = 05:00
Dhuhr     = 12:00
Asr       = 15:30
Maghrib   = 18:00
Next Fajr = 05:00 on the following day
```

### Creating period boundaries

```text
Fajr-Dhuhr midpoint = 08:30
Night duration      = 11 hours
Night third         = approximately 3 hours 40 minutes
```

The boundaries are approximately:

```text
Fajr        05:00 -> 08:30
Duha        08:30 -> 12:00
Dhuhr       12:00 -> 15:30
Asr         15:30 -> 18:00
Maghrib     18:00 -> 21:40
Middle      21:40 -> 01:20
Last Third  01:20 -> 05:00
```

Then apply the distribution:

```text
[7, 7, 7, 6, 7, 7, 7]
```

If the time is 07:00:

- Current period: Fajr.
- Fajr period duration: 3.5 hours.
- Elapsed time: 2 hours.
- Suwayas in the period: 7.
- Real Suwaya duration: 30 minutes.
- Current Suwaya: approximately 5.
- Progress is calculated from the remainder after the completed Suwayas.

If the time is 13:00:

- Current period: Dhuhr.
- The Suwayas from Fajr and Duha are added to the global index.
- The Dhuhr period begins at global index 14.
- The engine calculates the Suwaya within Dhuhr and adds it to that index.

## 25. Engine Modification Guidelines

When adding new behavior:

1. Update the data models first if the time concepts change.
2. Keep calculations inside `packages/suwaya_time`.
3. Do not import Flutter or Riverpod into the pure package.
4. Add a test for both normal and edge-case behavior.
5. Test the Suwaya total and period continuity.
6. Test timezone and daylight-saving behavior when dates or offsets are involved.
7. Test that an offset affects only its selected prayer.
8. Update this document if period boundaries or virtual-time semantics change.

Verification commands:

```bash
dart format packages/suwaya_time test
flutter analyze
flutter test
```

## 26. Quick Summary

```text
Astronomical day:
    Fajr -> nextFajr

Periods:
    1. Fajr
    2. Duha
    3. Dhuhr
    4. Asr
    5. Maghrib
    6. Middle Third
    7. Last Third

Distribution:
    7 + 7 + 7 + 6 + 7 + 7 + 7 = 48

Suwaya value:
    30 virtual minutes

Real Suwaya duration:
    Real period duration / period Suwaya count

Night:
    Maghrib -> nextFajr
    Two halves + three thirds + six sixths = 11 representations

Engine:
    Prayer times -> periods -> distribution -> current state -> virtual time
```
