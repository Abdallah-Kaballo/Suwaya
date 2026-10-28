import 'dart:math' as math;
import '../models/astro_models.dart';
import 'prayer_calculator.dart';

/// سياسة المعالجة الفلكية عند انعدام شروق أو غروب الشمس في المناطق القطبية (> 65°)
enum PolarResolutionPolicy {
  /// إسقاط المواقيت من أقرب خط عرض معتدل (45° شمالاً أو جنوباً) على نفس خط الطول والمنطقة الزمنية
  nearestLatitude45,

  /// تقسيم اليوم الفلكي تناسبياً (12 ساعة ليل / 12 ساعة نهار) ارتكازاً على الزوال الشمسي الحقيقي للموقع
  equinoxProportional,
}

class PolarCycleSynthesizer {
  static const double polarThresholdLatitude = 65.56;
  static const double referenceTemperateLatitude = 45.00;
  static bool _isHealthySpan(SuwayaCycleAnchors anchors) {
    if (!anchors.isValidSequence) return false;
    final totalSpanHours =
        anchors.cycleEndMaghribUtc != null &&
            anchors.cycleStartMaghribUtc != null
        ? anchors.cycleEndMaghribUtc!
              .difference(anchors.cycleStartMaghribUtc!)
              .inHours
        : anchors.cycleEndMaghrib.difference(anchors.cycleStartMaghrib).inHours;
    return totalSpanHours >= 20 && totalSpanHours <= 28;
  }

  /// حساب معادلة الزمن الفلكية (Equation of Time) بالمايكروثانية لأي يوم في السنة
  static Duration computeEquationOfTime(DateTime dateUtc) {
    final startOfYear = DateTime.utc(dateUtc.year, 1, 1);
    final dayOfYear = dateUtc.difference(startOfYear).inDays + 1;
    final bRad = (2.0 * math.pi * (dayOfYear - 81)) / 364.0;
    final eotMinutes =
        9.87 * math.sin(2.0 * bRad) -
        7.53 * math.cos(bRad) -
        1.5 * math.sin(bRad);
    return Duration(microseconds: (eotMinutes * 60 * 1000000).round());
  }

  /// حساب إزاحة الزوال الشمسي الحقيقي للموقع مقارنةً بإزاحة المنطقة الزمنية المدنية
  static Duration computeSolarMeridianShift({
    required double longitude,
    required Duration cityOffset,
    required DateTime targetDate,
  }) {
    final safeLng = longitude.clamp(-180.0, 180.0);
    final trueSolarOffsetSeconds = (safeLng / 15.0) * 3600.0;
    // فرق خط الطول الفعلي عن خط طول المنطقة الزمنية (مقيد بـ ±3 ساعات لحماية الاختبارات الاصطناعية)
    final meridianDeltaSeconds = (cityOffset.inSeconds - trueSolarOffsetSeconds)
        .clamp(-10800.0, 10800.0);
    final eot = computeEquationOfTime(targetDate);
    return Duration(seconds: meridianDeltaSeconds.round()) - eot;
  }

  static SuwayaCycleAnchors ensureValidAnchors({
    required SuwayaCycleAnchors? candidateAnchors,
    required double latitude,
    required double longitude,
    required DateTime targetDate,
    required CalculationMethodType methodType,
    required MadhabType madhabType,
    required HighLatitudeRuleType highLatRuleType,
    required double customFajr,
    required double customIsha,
    required Duration cityOffset,
    Duration? nextDayCityOffset,
    Map<PrayerKey, int>? manualOffsets,
    Duration Function(DateTime utcInstant)? offsetResolver,
    double elevationMeters = 0.0,
    PolarResolutionPolicy policy = PolarResolutionPolicy.nearestLatitude45,
  }) {
    final bool isPolarLatitude = latitude.abs() > polarThresholdLatitude;

    if (isPolarLatitude &&
        policy == PolarResolutionPolicy.equinoxProportional) {
      return synthesizeEquinoxCycle(
        targetDate: targetDate,
        longitude: longitude,
        cityOffset: cityOffset,
        nextDayCityOffset: nextDayCityOffset ?? cityOffset,
        offsetResolver: offsetResolver,
        manualOffsets: manualOffsets,
      );
    }

    if (candidateAnchors != null && _isHealthySpan(candidateAnchors)) {
      return candidateAnchors;
    }

    if (policy == PolarResolutionPolicy.nearestLatitude45) {
      final double clampedLat = latitude.abs() > 45.0
          ? (latitude >= 0 ? 45.0 : -45.0)
          : latitude;

      final projected = PrayerCalculator.computeRawCycleAnchors(
        clampedLat,
        longitude,
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
      if (_isHealthySpan(projected)) {
        return projected;
      }

      if (manualOffsets != null && manualOffsets.isNotEmpty) {
        final projectedClean = PrayerCalculator.computeRawCycleAnchors(
          clampedLat,
          longitude,
          targetDate,
          methodType,
          madhabType,
          highLatRuleType,
          customFajr,
          customIsha,
          cityOffset,
          nextDayCityOffset: nextDayCityOffset,
          manualOffsets: const {},
          offsetResolver: offsetResolver,
          elevationMeters: elevationMeters,
        );
        if (_isHealthySpan(projectedClean)) {
          return projectedClean;
        }
      }
    }

    return synthesizeEquinoxCycle(
      targetDate: targetDate,
      longitude: longitude,
      cityOffset: cityOffset,
      nextDayCityOffset: nextDayCityOffset ?? cityOffset,
      offsetResolver: offsetResolver,
      manualOffsets: manualOffsets,
    );
  }

  /// بناء دورة اعتدالية متناسقة (12 ساعة ليل / 12 ساعة نهار) مرتكزة على الزوال الشمسي الحقيقي لخط الطول
  static SuwayaCycleAnchors synthesizeEquinoxCycle({
    required DateTime targetDate,
    double longitude = 0.0,
    required Duration cityOffset,
    required Duration nextDayCityOffset,
    Duration Function(DateTime utcInstant)? offsetResolver,
    Map<PrayerKey, int>? manualOffsets,
  }) {
    final solarShift = computeSolarMeridianShift(
      longitude: longitude,
      cityOffset: cityOffset,
      targetDate: targetDate,
    );

    // الغروب الاعتدالي يقع بعد 6 ساعات من الزوال الشمسي الحقيقي لليوم D
    final rawStartSunsetUtc = DateTime.utc(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      18,
      0,
    ).subtract(cityOffset).add(solarShift);

    final rawEndSunsetUtc = rawStartSunsetUtc.add(const Duration(hours: 24));

    int offsetMins(PrayerKey key) => (manualOffsets?[key] ?? 0).clamp(-30, 30);

    final startMaghribUtc = rawStartSunsetUtc.add(
      Duration(minutes: offsetMins(PrayerKey.maghrib)),
    );
    final ishaUtc = rawStartSunsetUtc.add(
      Duration(minutes: 90 + offsetMins(PrayerKey.isha)),
    );
    final fajrUtc = rawStartSunsetUtc.add(
      Duration(minutes: 630 + offsetMins(PrayerKey.fajr)),
    );
    final midnightUtc = startMaghribUtc.add(
      Duration(
        microseconds: fajrUtc.difference(startMaghribUtc).inMicroseconds ~/ 2,
      ),
    );
    final sunriseUtc = rawStartSunsetUtc.add(const Duration(hours: 12));
    final dhuhrUtc = rawStartSunsetUtc.add(
      Duration(minutes: 1080 + offsetMins(PrayerKey.dhuhr)),
    );
    final asrUtc = rawStartSunsetUtc.add(
      Duration(minutes: 1260 + offsetMins(PrayerKey.asr)),
    );
    final endMaghribUtc = rawEndSunsetUtc.add(
      Duration(minutes: offsetMins(PrayerKey.maghrib)),
    );

    DateTime toEveningWall(DateTime u) =>
        u.add(offsetResolver != null ? offsetResolver(u) : cityOffset);
    DateTime toNextWall(DateTime u) =>
        u.add(offsetResolver != null ? offsetResolver(u) : nextDayCityOffset);

    return SuwayaCycleAnchors(
      cycleStartMaghrib: toEveningWall(startMaghribUtc),
      cycleIsha: toEveningWall(ishaUtc),
      sharIMidnight: toEveningWall(midnightUtc),
      cycleFajr: toNextWall(fajrUtc),
      cycleSunrise: toNextWall(sunriseUtc),
      cycleDhuhr: toNextWall(dhuhrUtc),
      cycleAsr: toNextWall(asrUtc),
      cycleEndMaghrib: toNextWall(endMaghribUtc),
      cycleStartMaghribUtc: startMaghribUtc,
      cycleIshaUtc: ishaUtc,
      sharIMidnightUtc: midnightUtc,
      cycleFajrUtc: fajrUtc,
      cycleSunriseUtc: sunriseUtc,
      cycleDhuhrUtc: dhuhrUtc,
      cycleAsrUtc: asrUtc,
      cycleEndMaghribUtc: endMaghribUtc,
      calculatedStartSunset: toEveningWall(rawStartSunsetUtc),
      calculatedEndSunset: toNextWall(rawEndSunsetUtc),
      calculatedStartSunsetUtc: rawStartSunsetUtc,
      calculatedEndSunsetUtc: rawEndSunsetUtc,
    );
  }
}
