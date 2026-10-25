import '../models/astro_models.dart';

class PeriodGenerator {
  static List<AstroPeriod> generatePeriods(
    SuwayaCycleAnchors anchors,
    List<int> distribution,
  ) {
    if (!anchors.isValidSequence) {
      throw Exception(
        'Invalid Astro Sequence: Boundaries overlap or are backwards.',
      );
    }

    return [
      AstroPeriod(
        id: 1,
        periodKey: PeriodKey.nightMaghribIsha,
        nameKey: 'periods.maghrib',
        startTime: anchors.cycleStartMaghrib,
        endTime: anchors.cycleIsha,
        startUtc: anchors.cycleStartMaghribUtc,
        endUtc: anchors.cycleIshaUtc,
        suwayasCount: distribution[0],
        colorValue: 0xFFE53935,
      ),
      AstroPeriod(
        id: 2,
        periodKey: PeriodKey.nightIshaMidnight,
        nameKey: 'periods.isha',
        startTime: anchors.cycleIsha,
        endTime: anchors.sharIMidnight,
        startUtc: anchors.cycleIshaUtc,
        endUtc: anchors.sharIMidnightUtc,
        suwayasCount: distribution[1],
        colorValue: 0xFF1A237E,
      ),
      AstroPeriod(
        id: 3,
        periodKey: PeriodKey.nightMidnightFajr,
        nameKey: 'periods.qiyam',
        startTime: anchors.sharIMidnight,
        endTime: anchors.cycleFajr,
        startUtc: anchors.sharIMidnightUtc,
        endUtc: anchors.cycleFajrUtc,
        suwayasCount: distribution[2],
        colorValue: 0xFF311B92,
      ),
      AstroPeriod(
        id: 4,
        periodKey: PeriodKey.nightFajrSunrise,
        nameKey: 'periods.fajr',
        startTime: anchors.cycleFajr,
        endTime: anchors.cycleSunrise,
        startUtc: anchors.cycleFajrUtc,
        endUtc: anchors.cycleSunriseUtc,
        suwayasCount: distribution[3],
        colorValue: 0xFF64B5F6,
      ),
      AstroPeriod(
        id: 5,
        periodKey: PeriodKey.daySunriseDhuhr,
        nameKey: 'periods.duha',
        startTime: anchors.cycleSunrise,
        endTime: anchors.cycleDhuhr,
        startUtc: anchors.cycleSunriseUtc,
        endUtc: anchors.cycleDhuhrUtc,
        suwayasCount: distribution[4],
        colorValue: 0xFFFFF176,
      ),
      AstroPeriod(
        id: 6,
        periodKey: PeriodKey.dayDhuhrAsr,
        nameKey: 'periods.dhuhr',
        startTime: anchors.cycleDhuhr,
        endTime: anchors.cycleAsr,
        startUtc: anchors.cycleDhuhrUtc,
        endUtc: anchors.cycleAsrUtc,
        suwayasCount: distribution[5],
        colorValue: 0xFFFFCA28,
      ),
      AstroPeriod(
        id: 7,
        periodKey: PeriodKey.dayAsrMaghrib,
        nameKey: 'periods.asr',
        startTime: anchors.cycleAsr,
        endTime: anchors.cycleEndMaghrib,
        startUtc: anchors.cycleAsrUtc,
        endUtc: anchors.cycleEndMaghribUtc,
        suwayasCount: distribution[6],
        colorValue: 0xFFFF9800,
      ),
    ];
  }
}
