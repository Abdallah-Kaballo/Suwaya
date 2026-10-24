import 'dart:math' as math;
import 'package:adhan/adhan.dart';
import '../models/astro_models.dart';
import 'night_division.dart';
import 'polar_cycle_synthesizer.dart';

class PrayerCalculator {
  static CalculationParameters _getParams(
    CalculationMethodType methodType,
    MadhabType madhabType,
    HighLatitudeRuleType highLatRuleType,
    double customFajr,
    double customIsha,
  ) {
    CalculationParameters params;
    switch (methodType) {
      case CalculationMethodType.muslimWorldLeague:
        params = CalculationMethod.muslim_world_league.getParameters();
        break;
      case CalculationMethodType.egyptian:
        params = CalculationMethod.egyptian.getParameters();
        break;
      case CalculationMethodType.karachi:
        params = CalculationMethod.karachi.getParameters();
        break;
      case CalculationMethodType.ummAlQura:
        params = CalculationMethod.umm_al_qura.getParameters();
        break;
      case CalculationMethodType.dubai:
        params = CalculationMethod.dubai.getParameters();
        break;
      case CalculationMethodType.qatar:
        params = CalculationMethod.qatar.getParameters();
        break;
      case CalculationMethodType.kuwait:
        params = CalculationMethod.kuwait.getParameters();
        break;
      case CalculationMethodType.singapore:
        params = CalculationMethod.singapore.getParameters();
        break;
      case CalculationMethodType.northAmerica:
        params = CalculationMethod.north_america.getParameters();
        break;
      case CalculationMethodType.tehran:
        params = CalculationMethod.tehran.getParameters();
        break;
      case CalculationMethodType.turkey:
        params = CalculationMethod.turkey.getParameters();
        break;
      case CalculationMethodType.franceUoif:
        params = CalculationMethod.other.getParameters();
        params.fajrAngle = 12.0;
        params.ishaAngle = 12.0;
        break;
      case CalculationMethodType.russia:
        params = CalculationMethod.other.getParameters();
        params.fajrAngle = 16.0;
        params.ishaAngle = 15.0;
        break;
      case CalculationMethodType.custom:
        params = CalculationMethod.other.getParameters();
        params.fajrAngle = customFajr;
        params.ishaAngle = customIsha;
        break;
    }

    params.madhab =
        (madhabType == MadhabType.hanafi) ? Madhab.hanafi : Madhab.shafi;

    switch (highLatRuleType) {
      case HighLatitudeRuleType.seventhOfTheNight:
        params.highLatitudeRule = HighLatitudeRule.seventh_of_the_night;
        break;
      case HighLatitudeRuleType.twilightAngle:
        params.highLatitudeRule = HighLatitudeRule.twilight_angle;
        // في طريقتي أم القرى وقطر تكون ishaInterval = 90 و ishaAngle = null؛
        // تزويد زاوية شفق مرجعية يمنع انهيار nightPortions() في adhan مع بقاء العشاء معتمداً على ishaInterval
        params.ishaAngle ??= 18.0;
        break;
      case HighLatitudeRuleType.middleOfTheNight:
        params.highLatitudeRule = HighLatitudeRule.middle_of_the_night;
        break;
    }
    return params;
  }

  /// استدعاء آمن لمكتبة adhan يمنع انهيار TimeComponents.fromDouble(NaN) في العروض القطبية والعليا
  static ({PrayerTimes day1, PrayerTimes day2, double effectiveLat})
      _safeComputePrayerTimesPair({
    required double lat,
    required double lng,
    required DateTime date,
    required CalculationParameters params,
  }) {
    final safeLng = lng.clamp(-180.0, 180.0);
    final d1 = DateComponents.from(date);
    final d2 = DateComponents.from(date.add(const Duration(days: 1)));

    if (lat.abs() <= PolarCycleSynthesizer.polarThresholdLatitude) {
      try {
        final coords = Coordinates(lat, safeLng);
        final p1 = PrayerTimes(coords, d1, params);
        final p2 = PrayerTimes(coords, d2, params);
        return (day1: p1, day2: p2, effectiveLat: lat);
      } catch (_) {
        // السقوط الآمن إلى خط العرض القياسي ±45° عند حدوث NaN في زاوية الشفق أو الشروق/الغروب
      }
    }

    final clampedLat = lat >= 0 ? 45.0 : -45.0;
    final fallbackCoords = Coordinates(clampedLat, safeLng);
    return (
      day1: PrayerTimes(fallbackCoords, d1, params),
      day2: PrayerTimes(fallbackCoords, d2, params),
      effectiveLat: clampedLat,
    );
  }

  static Duration _computeElevationHorizonDip(
    double latitude,
    double elevationMeters,
  ) {
    if (elevationMeters <= 0.0) return Duration.zero;
    final dipDegrees = 0.0347 * math.sqrt(elevationMeters);
    final latRad = (latitude.abs().clamp(0.0, 60.0)) * (math.pi / 180.0);
    final minutesShift = (dipDegrees * 4.0) / math.cos(latRad);
    return Duration(microseconds: (minutesShift * 60 * 1000000).round());
  }

  static DateTime _applyOffset(
    DateTime time,
    PrayerKey key,
    Map<PrayerKey, int> allowedManualOffsets,
  ) {
    if (allowedManualOffsets.containsKey(key)) {
      return time.add(Duration(minutes: allowedManualOffsets[key]!));
    }
    return time;
  }

  static IbadatTimings getIbadatTimings(
    double lat,
    double lng,
    DateTime date,
    CalculationMethodType methodType,
    MadhabType madhabType,
    HighLatitudeRuleType highLatRuleType,
    double customFajr,
    double customIsha,
    Duration cityOffset, {
    Duration? nextDayCityOffset,
    Map<PrayerKey, int>? manualOffsets,
    Duration Function(DateTime utcInstant)? offsetResolver,
    double elevationMeters = 0.0,
  }) {
    final params = _getParams(
      methodType,
      madhabType,
      highLatRuleType,
      customFajr,
      customIsha,
    );

    final pair = _safeComputePrayerTimesPair(
      lat: lat,
      lng: lng,
      date: date,
      params: params,
    );
    final today = pair.day1;
    final tomorrow = pair.day2;

    final allowedManualOffsets = <PrayerKey, int>{};
    if (manualOffsets != null) {
      for (final entry in manualOffsets.entries) {
        if (entry.key != PrayerKey.sunrise) {
          allowedManualOffsets[entry.key] = entry.value.clamp(-30, 30);
        }
      }
    }

    final effectiveNextOffset = nextDayCityOffset ?? cityOffset;
    final elevationShift =
        _computeElevationHorizonDip(pair.effectiveLat, elevationMeters);

    final rawSunsetUtc = today.maghrib.toUtc().add(elevationShift);
    var fajrUtc = _applyOffset(
      today.fajr.toUtc(),
      PrayerKey.fajr,
      allowedManualOffsets,
    );
    final sunriseUtc = today.sunrise.toUtc().subtract(elevationShift);
    var dhuhrUtc = _applyOffset(
      today.dhuhr.toUtc(),
      PrayerKey.dhuhr,
      allowedManualOffsets,
    );
    var asrUtc = _applyOffset(
      today.asr.toUtc(),
      PrayerKey.asr,
      allowedManualOffsets,
    );
    var maghribUtc = _applyOffset(
      rawSunsetUtc,
      PrayerKey.maghrib,
      allowedManualOffsets,
    );
    var ishaUtc = _applyOffset(
      today.isha.toUtc(),
      PrayerKey.isha,
      allowedManualOffsets,
    );
    var nextFajrUtc = _applyOffset(
      tomorrow.fajr.toUtc(),
      PrayerKey.fajr,
      allowedManualOffsets,
    );

    // إذا تسببت التعديلات اليدوية الحادة في قلب ترتيب المغرب والعشاء والفجر، نعتمد المواقيت الفلكية الصافية
    if (!maghribUtc.isBefore(ishaUtc) || !ishaUtc.isBefore(nextFajrUtc)) {
      maghribUtc = rawSunsetUtc;
      ishaUtc = today.isha.toUtc();
      nextFajrUtc = tomorrow.fajr.toUtc();
    }

    DateTime toEveningWall(DateTime utc) =>
        utc.add(offsetResolver != null ? offsetResolver(utc) : cityOffset);
    DateTime toNextDayWall(DateTime utc) => utc.add(
          offsetResolver != null ? offsetResolver(utc) : effectiveNextOffset,
        );

    DateTime toNightWall(DateTime utc) {
      if (offsetResolver != null) return utc.add(offsetResolver(utc));
      final halfNightUtc =
          maghribUtc.add(nextFajrUtc.difference(maghribUtc) ~/ 2);
      return utc.isBefore(halfNightUtc)
          ? utc.add(cityOffset)
          : utc.add(effectiveNextOffset);
    }

    final maghribWall = toEveningWall(maghribUtc);
    final nextFajrWall = toNextDayWall(nextFajrUtc);

    return IbadatTimings(
      fajr: toEveningWall(fajrUtc),
      sunrise: toEveningWall(sunriseUtc),
      dhuhr: toEveningWall(dhuhrUtc),
      asr: toEveningWall(asrUtc),
      maghrib: maghribWall,
      isha: toEveningWall(ishaUtc),
      nextFajr: nextFajrWall,
      calculatedSunset: toEveningWall(rawSunsetUtc),
      nightParts: NightDivision.calculateNightParts(
        maghribWall,
        nextFajrWall,
        maghribUtc: maghribUtc,
        nextFajrUtc: nextFajrUtc,
        toWallClock: toNightWall,
      ),
    );
  }

  static SuwayaCycleAnchors getCycleAnchors(
    double lat,
    double lng,
    DateTime targetDate,
    CalculationMethodType methodType,
    MadhabType madhabType,
    HighLatitudeRuleType highLatRuleType,
    double customFajr,
    double customIsha,
    Duration cityOffset, {
    Duration? nextDayCityOffset,
    Map<PrayerKey, int>? manualOffsets,
    Duration Function(DateTime utcInstant)? offsetResolver,
    double elevationMeters = 0.0,
  }) {
    final rawAnchors = computeRawCycleAnchors(
      lat,
      lng,
      targetDate,
      methodType,
      madhabType,
      highLatRuleType,
      customFajr,
      customIsha,
      cityOffset,
      nextDayCityOffset: nextDayCityOffset,
      manualOffsets: manualOffsets,
      offsetResolver: offsetResolver,
      elevationMeters: elevationMeters,
    );

    return PolarCycleSynthesizer.ensureValidAnchors(
      candidateAnchors: rawAnchors,
      latitude: lat,
      longitude: lng,
      targetDate: targetDate,
      methodType: methodType,
      madhabType: madhabType,
      highLatRuleType: highLatRuleType,
      customFajr: customFajr,
      customIsha: customIsha,
      cityOffset: cityOffset,
      nextDayCityOffset: nextDayCityOffset,
      manualOffsets: manualOffsets,
      offsetResolver: offsetResolver,
    );
  }

  static SuwayaCycleAnchors computeRawCycleAnchors(
    double lat,
    double lng,
    DateTime targetDate,
    CalculationMethodType methodType,
    MadhabType madhabType,
    HighLatitudeRuleType highLatRuleType,
    double customFajr,
    double customIsha,
    Duration cityOffset, {
    Duration? nextDayCityOffset,
    Map<PrayerKey, int>? manualOffsets,
    Duration Function(DateTime utcInstant)? offsetResolver,
    double elevationMeters = 0.0,
  }) {
    final params = _getParams(
      methodType,
      madhabType,
      highLatRuleType,
      customFajr,
      customIsha,
    );

    final pair = _safeComputePrayerTimesPair(
      lat: lat,
      lng: lng,
      date: targetDate,
      params: params,
    );
    final dayD = pair.day1;
    final dayDPlus1 = pair.day2;

    final allowedManualOffsets = <PrayerKey, int>{};
    if (manualOffsets != null) {
      for (final entry in manualOffsets.entries) {
        if (entry.key != PrayerKey.sunrise) {
          allowedManualOffsets[entry.key] = entry.value.clamp(-30, 30);
        }
      }
    }

    final effectiveNextOffset = nextDayCityOffset ?? cityOffset;
    final elevationShift =
        _computeElevationHorizonDip(pair.effectiveLat, elevationMeters);

    final rawStartSunsetUtc = dayD.maghrib.toUtc().add(elevationShift);
    final rawEndSunsetUtc = dayDPlus1.maghrib.toUtc().add(elevationShift);

    final cycleStartMaghribUtc = _applyOffset(
      rawStartSunsetUtc,
      PrayerKey.maghrib,
      allowedManualOffsets,
    );
    final cycleIshaUtc = _applyOffset(
      dayD.isha.toUtc(),
      PrayerKey.isha,
      allowedManualOffsets,
    );
    final cycleFajrUtc = _applyOffset(
      dayDPlus1.fajr.toUtc(),
      PrayerKey.fajr,
      allowedManualOffsets,
    );
    final cycleSunriseUtc = dayDPlus1.sunrise.toUtc().subtract(elevationShift);
    final cycleDhuhrUtc = _applyOffset(
      dayDPlus1.dhuhr.toUtc(),
      PrayerKey.dhuhr,
      allowedManualOffsets,
    );
    final cycleAsrUtc = _applyOffset(
      dayDPlus1.asr.toUtc(),
      PrayerKey.asr,
      allowedManualOffsets,
    );
    final cycleEndMaghribUtc = _applyOffset(
      rawEndSunsetUtc,
      PrayerKey.maghrib,
      allowedManualOffsets,
    );

    final realNightMicroseconds =
        cycleFajrUtc.difference(cycleStartMaghribUtc).inMicroseconds;
    final sharIMidnightUtc = cycleStartMaghribUtc.add(
      Duration(microseconds: realNightMicroseconds ~/ 2),
    );

    DateTime toEveningWall(DateTime utc) =>
        utc.add(offsetResolver != null ? offsetResolver(utc) : cityOffset);
    DateTime toNextDayWall(DateTime utc) => utc.add(
          offsetResolver != null ? offsetResolver(utc) : effectiveNextOffset,
        );

    return SuwayaCycleAnchors(
      cycleStartMaghrib: toEveningWall(cycleStartMaghribUtc),
      cycleIsha: toEveningWall(cycleIshaUtc),
      sharIMidnight: toEveningWall(sharIMidnightUtc),
      cycleFajr: toNextDayWall(cycleFajrUtc),
      cycleSunrise: toNextDayWall(cycleSunriseUtc),
      cycleDhuhr: toNextDayWall(cycleDhuhrUtc),
      cycleAsr: toNextDayWall(cycleAsrUtc),
      cycleEndMaghrib: toNextDayWall(cycleEndMaghribUtc),
      cycleStartMaghribUtc: cycleStartMaghribUtc,
      cycleIshaUtc: cycleIshaUtc,
      sharIMidnightUtc: sharIMidnightUtc,
      cycleFajrUtc: cycleFajrUtc,
      cycleSunriseUtc: cycleSunriseUtc,
      cycleDhuhrUtc: cycleDhuhrUtc,
      cycleAsrUtc: cycleAsrUtc,
      cycleEndMaghribUtc: cycleEndMaghribUtc,
      calculatedStartSunset: toEveningWall(rawStartSunsetUtc),
      calculatedEndSunset: toNextDayWall(rawEndSunsetUtc),
      calculatedStartSunsetUtc: rawStartSunsetUtc,
      calculatedEndSunsetUtc: rawEndSunsetUtc,
    );
  }
}
