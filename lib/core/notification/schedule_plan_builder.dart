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
  /// توليد نافذة البيانات الفلكية لـ 8 أيام (-1 إلى +6) داخل Isolate مع محلل المنطقة الزمنية الدقيق
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
      // تهيئة قاعدة بيانات المناطق الزمنية داخل الـ Isolate لضمان تطابق الحساب مع الواجهة 100%
      tz_data.initializeTimeZones();

      final List<ScheduledDayAstroWindow> windows = [];

      for (int index = 0; index < 8; index++) {
        final int dayOffset = index - 1;
        final DateTime targetDate =
            isolatedCityNow.add(Duration(days: dayOffset));
        final Duration dayCityOffset = fallbackDayOffsets[index];
        final Duration nextDayOffset = fallbackDayOffsets[index + 1];

        Duration resolveOffset(DateTime utcInstant) {
          return TimezoneResolver.resolveForInstant(
            utcInstant,
            timezoneId: timezoneId,
            fallbackOffset: dayCityOffset,
          ).utcOffset;
        }

        final generatedDay = SuwayaTimeEngine.generateDay(
          latitude,
          longitude,
          targetDate,
          calcMethod,
          madhab,
          hlRule,
          fajrAngle,
          ishaAngle,
          dayCityOffset,
          nextDayCityOffset: nextDayOffset,
          manualOffsets: manualOffsets,
          offsetResolver: resolveOffset,
        );

        windows.add(
          ScheduledDayAstroWindow(
            dayOffset: dayOffset,
            targetDate: targetDate,
            ibadat: generatedDay.ibadatTimings,
            periods: generatedDay.periods,
          ),
        );
      }

      return windows;
    });
  }
}