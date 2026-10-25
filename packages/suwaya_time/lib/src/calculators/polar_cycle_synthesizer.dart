import '../models/astro_models.dart';
import 'prayer_calculator.dart';

/// سياسة المعالجة الفلكية عند انعدام شروق أو غروب الشمس في المناطق القطبية (> 65°)
enum PolarResolutionPolicy {
  /// إسقاط المواقيت من أقرب خط عرض معتدل (45° شمالاً أو جنوباً) على نفس خط الطول والمنطقة الزمنية
  nearestLatitude45,

  /// تقسيم اليوم الفلكي تناسبياً (12 ساعة ليل / 12 ساعة نهار) ارتكازاً على الزوال الشمسي
  equinoxProportional,
}

class PolarCycleSynthesizer {
  static const double polarThresholdLatitude = 65.0;

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
    PolarResolutionPolicy policy = PolarResolutionPolicy.nearestLatitude45,
  }) {
    final bool isPolarLatitude = latitude.abs() > polarThresholdLatitude;

    if (isPolarLatitude &&
        policy == PolarResolutionPolicy.equinoxProportional) {
      return _synthesizeEquinoxCycle(
        targetDate: targetDate,
        cityOffset: cityOffset,
        nextDayCityOffset: nextDayCityOffset ?? cityOffset,
        offsetResolver: offsetResolver,
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
        );
        if (_isHealthySpan(projectedClean)) {
          return projectedClean;
        }
      }
    }

    return _synthesizeEquinoxCycle(
      targetDate: targetDate,
      cityOffset: cityOffset,
      nextDayCityOffset: nextDayCityOffset ?? cityOffset,
      offsetResolver: offsetResolver,
    );
  }

  static SuwayaCycleAnchors _synthesizeEquinoxCycle({
    required DateTime targetDate,
    required Duration cityOffset,
    required Duration nextDayCityOffset,
    Duration Function(DateTime utcInstant)? offsetResolver,
  }) {
    final baseLocalDayUtc = DateTime.utc(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      18,
      0,
    ).subtract(cityOffset);

    final startMaghribUtc = baseLocalDayUtc;
    final ishaUtc = startMaghribUtc.add(const Duration(hours: 1, minutes: 30));
    final midnightUtc = startMaghribUtc.add(
      const Duration(hours: 5, minutes: 15),
    );
    final fajrUtc = startMaghribUtc.add(const Duration(hours: 10, minutes: 30));
    final sunriseUtc = startMaghribUtc.add(const Duration(hours: 12));
    final dhuhrUtc = startMaghribUtc.add(const Duration(hours: 18));
    final asrUtc = startMaghribUtc.add(const Duration(hours: 21));
    final endMaghribUtc = startMaghribUtc.add(const Duration(hours: 24));

    DateTime toNextWall(DateTime u) =>
        u.add(offsetResolver != null ? offsetResolver(u) : nextDayCityOffset);

    return SuwayaCycleAnchors(
      cycleStartMaghrib: startMaghribUtc.add(
        offsetResolver?.call(startMaghribUtc) ?? cityOffset,
      ),
      cycleIsha: ishaUtc.add(offsetResolver?.call(ishaUtc) ?? cityOffset),
      sharIMidnight: midnightUtc.add(
        offsetResolver?.call(midnightUtc) ?? cityOffset,
      ),
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
      calculatedStartSunset: startMaghribUtc.add(
        offsetResolver?.call(startMaghribUtc) ?? cityOffset,
      ),
      calculatedEndSunset: toNextWall(endMaghribUtc),
      calculatedStartSunsetUtc: startMaghribUtc,
      calculatedEndSunsetUtc: endMaghribUtc,
    );
  }
}
