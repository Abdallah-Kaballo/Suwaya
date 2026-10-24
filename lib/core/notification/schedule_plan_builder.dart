import 'dart:isolate';
import 'package:suwaya_time/suwaya_time.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;

class ScheduledDayAstroWindow {
  final int dayOffset;
  final DateTime targetDate;
  final IbadatTimings ibadat;
  final List<AstroPeriod> periods;

  const ScheduledDayAstroWindow({
    required this.dayOffset,
    required this.targetDate,
    required this.ibadat,
    required this.periods,
  });
}

class SchedulePlanBuilder {
  /// توليد نافذة البيانات الفلكية لـ 8 أيام (-1 إلى +6) داخل Isolate عبر محرك التكرار في النواة
  static Future<List<ScheduledDayAstroWindow>> computeWeekAstroWindows({
    required double latitude,
    required double longitude,
    required String? timezoneId,
    required DateTime isolatedCityNow,
    required List<Duration> fallbackDayOffsets,
    required CalculationMethodType calcMethod,
    required MadhabType madhab,
    required HighLatitudeRuleType hlRule,
    required double fajrAngle,
    required double ishaAngle,
    required Map<PrayerKey, int> manualOffsets,
  }) {
    return Isolate.run(() {
      tz_data.initializeTimeZones();

      final coreWindows = SuwayaRecurrenceEngine.generateMultiDayWindows(
        latitude: latitude,
        longitude: longitude,
        referenceWallTime: isolatedCityNow,
        timezoneId: timezoneId,
        fallbackDayOffsets: fallbackDayOffsets,
        calcMethod: calcMethod,
        madhab: madhab,
        hlRule: hlRule,
        fajrAngle: fajrAngle,
        ishaAngle: ishaAngle,
        manualOffsets: manualOffsets,
      );

      return coreWindows
          .map(
            (w) => ScheduledDayAstroWindow(
              dayOffset: w.dayOffset,
              targetDate: w.targetDate,
              ibadat: w.ibadat,
              periods: w.periods,
            ),
          )
          .toList();
    });
  }
}
