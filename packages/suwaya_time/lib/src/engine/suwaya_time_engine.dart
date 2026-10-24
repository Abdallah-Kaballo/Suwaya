import '../models/astro_models.dart';
import '../calculators/prayer_calculator.dart';
import '../generators/period_generator.dart';
import '../generators/suwaya_distributor.dart';
import 'suwaya_coordinate_mapper.dart';

class SuwayaTimeEngine {
  static SuwayaDay generateDay(
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
    IbadatTimings? civilDayIbadatOverride,
    SuwayaAllocationMode allocationMode = SuwayaAllocationMode.canonicalMadhab,
  }) {
    final ibadat = PrayerCalculator.getIbadatTimings(
      lat,
      lng,
      date,
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

    final anchors = PrayerCalculator.getCycleAnchors(
      lat,
      lng,
      date,
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

    final distribution = SuwayaDistributor.resolveDistribution(
      madhab: madhabType,
      anchors: anchors,
      mode: allocationMode,
    );
    final periods = PeriodGenerator.generatePeriods(anchors, distribution);

    return SuwayaDay(
      ibadatTimings: ibadat,
      civilDayIbadat: civilDayIbadatOverride ?? ibadat,
      cycleAnchors: anchors,
      periods: periods,
    );
  }

  static AstroState calculateCurrentState(
    SuwayaDay day,
    DateTime now, {
    DateTime? nowUtc,
  }) {
    if (day.periods.isEmpty) return getFallbackState(now);

    final coord = SuwayaCoordinateMapper.instantToCoordinate(
      day: day,
      instant: now,
      instantUtc: nowUtc,
    );

    final currentPeriod = day.periods.firstWhere(
      (p) => p.id == coord.periodId,
      orElse: () => day.periods.first,
    );

    final int sCount =
        currentPeriod.suwayasCount > 0 ? currentPeriod.suwayasCount : 1;
    final double actualPeriodSuwayaMicro =
        currentPeriod.totalDuration.inMicroseconds / sCount;
    final double speedMultiplier = actualPeriodSuwayaMicro > 0
        ? 3600 / (actualPeriodSuwayaMicro / 1000000)
        : 1.0;

    final clockTime = SuwayaClockTime(
      phase: coord.phase,
      phaseSlotNumber: coord.phaseSlotNumber,
      periodKey: coord.periodKey,
      periodLocalSlotNumber: coord.periodLocalSlotNumber,
      slotProgress: coord.slotProgress,
      cycleStartDate: day.cycleAnchors.cycleStartMaghrib,
      instant: nowUtc ?? now,
    );

    return AstroState(
      virtualTime: now,
      instantUtc: nowUtc,
      periods: day.periods,
      currentPeriod: currentPeriod,
      currentSuwayaTime: clockTime,
      timeSpeedMultiplier: speedMultiplier,
      ibadatTimings: day.ibadatTimings,
      civilDayIbadat: day.civilDayIbadat,
      cycleAnchors: day.cycleAnchors,
    );
  }

  static AstroState getFallbackState(DateTime now) {
    final fallbackIbadat = IbadatTimings(
      fajr: now,
      sunrise: now,
      dhuhr: now,
      asr: now,
      maghrib: now,
      isha: now,
      nextFajr: now.add(const Duration(days: 1)),
      nightParts: const [],
    );
    final fallbackAnchors = SuwayaCycleAnchors(
      cycleStartMaghrib: now,
      cycleIsha: now,
      sharIMidnight: now,
      cycleFajr: now,
      cycleSunrise: now,
      cycleDhuhr: now,
      cycleAsr: now,
      cycleEndMaghrib: now.add(const Duration(days: 1)),
    );
    final fallbackPeriod = AstroPeriod(
      id: 1,
      periodKey: PeriodKey.nightMaghribIsha,
      nameKey: 'period_maghrib',
      colorValue: 0xFFD4AF37,
      startTime: now,
      endTime: now.add(const Duration(hours: 1)),
      suwayasCount: 1,
    );
    final fallbackTime = SuwayaClockTime(
      phase: SuwayaPhase.night,
      phaseSlotNumber: 1,
      periodKey: PeriodKey.nightMaghribIsha,
      periodLocalSlotNumber: 1,
      slotProgress: 0.0,
      cycleStartDate: now,
      instant: now,
    );

    return AstroState(
      virtualTime: now,
      periods: [fallbackPeriod],
      currentPeriod: fallbackPeriod,
      currentSuwayaTime: fallbackTime,
      timeSpeedMultiplier: 1.0,
      ibadatTimings: fallbackIbadat,
      civilDayIbadat: fallbackIbadat,
      cycleAnchors: fallbackAnchors,
    );
  }
}
