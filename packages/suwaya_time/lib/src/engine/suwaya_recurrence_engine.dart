import '../models/astro_models.dart';
import 'suwaya_time_engine.dart';
import 'temporal_context_engine.dart';

/// نافذة يوم فلكي مجدول داخل نطاق متعدد الأيام
class SuwayaScheduledDayWindow {
  final int dayOffset;
  final DateTime targetDate;
  final CivilDate astroLogicalDate;
  final CivilDate civilLogicalDate;
  final SuwayaDay suwayaDay;

  const SuwayaScheduledDayWindow({
    required this.dayOffset,
    required this.targetDate,
    required this.astroLogicalDate,
    required this.civilLogicalDate,
    required this.suwayaDay,
  });

  IbadatTimings get ibadat => suwayaDay.ibadatTimings;
  List<AstroPeriod> get periods => suwayaDay.periods;
}

class SuwayaRecurrenceEngine {
  /// توليد نافذة فلكية لعدد من الأيام (افتراضياً 8 أيام: -1 إلى +6) متوافقة مع Isolate.run والـ APIs
  static List<SuwayaScheduledDayWindow> generateMultiDayWindows({
    required double latitude,
    required double longitude,
    required DateTime referenceWallTime,
    String? timezoneId,
    List<Duration>? fallbackDayOffsets,
    CalculationMethodType calcMethod = CalculationMethodType.muslimWorldLeague,
    MadhabType madhab = MadhabType.shafi,
    HighLatitudeRuleType hlRule = HighLatitudeRuleType.middleOfTheNight,
    double fajrAngle = 18.0,
    double ishaAngle = 18.0,
    Map<PrayerKey, int>? manualOffsets,
    int startDayOffset = -1,
    int daysCount = 8,
  }) {
    final List<SuwayaScheduledDayWindow> windows = [];

    for (int index = 0; index < daysCount; index++) {
      final int dayOffset = startDayOffset + index;
      final DateTime targetDate = referenceWallTime.add(
        Duration(days: dayOffset),
      );

      final Duration fallbackCurrent =
          (fallbackDayOffsets != null && index < fallbackDayOffsets.length)
          ? fallbackDayOffsets[index]
          : TimezoneResolver.resolveForInstant(
              DateTime.utc(
                targetDate.year,
                targetDate.month,
                targetDate.day,
                12,
              ),
              timezoneId: timezoneId,
            ).utcOffset;

      final Duration fallbackNext =
          (fallbackDayOffsets != null && index + 1 < fallbackDayOffsets.length)
          ? fallbackDayOffsets[index + 1]
          : TimezoneResolver.resolveForInstant(
              DateTime.utc(
                targetDate.year,
                targetDate.month,
                targetDate.day,
                12,
              ).add(const Duration(days: 1)),
              timezoneId: timezoneId,
            ).utcOffset;

      Duration resolveOffset(DateTime utcInstant) {
        return TimezoneResolver.resolveForInstant(
          utcInstant,
          timezoneId: timezoneId,
          fallbackOffset: fallbackCurrent,
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
        fallbackCurrent,
        nextDayCityOffset: fallbackNext,
        manualOffsets: manualOffsets,
        offsetResolver: resolveOffset,
      );

      final cycleEnd = generatedDay.periods.last.endTime;
      final astroLogical = CivilDate(
        cycleEnd.year,
        cycleEnd.month,
        cycleEnd.day,
      );
      final civilLogical = CivilDate(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );

      windows.add(
        SuwayaScheduledDayWindow(
          dayOffset: dayOffset,
          targetDate: targetDate,
          astroLogicalDate: astroLogical,
          civilLogicalDate: civilLogical,
          suwayaDay: generatedDay,
        ),
      );
    }

    return windows;
  }

  /// معرف رقمي ثابت وحتمي لأجزاء الليل (بدلاً من String.hashCode غير المستقر عبر المنصات)
  static int stableNightPartCode(String nightPartId) {
    switch (nightPartId.trim().toLowerCase()) {
      case 'half_1':
        return 11;
      case 'half_2':
        return 12;
      case 'third_1':
        return 21;
      case 'third_2':
        return 22;
      case 'third_3':
        return 23;
      case 'sixth_1':
        return 31;
      case 'sixth_2':
        return 32;
      case 'sixth_3':
        return 33;
      case 'sixth_4':
        return 34;
      case 'sixth_5':
        return 35;
      case 'sixth_6':
        return 36;
      default:
        int acc = 50;
        for (final unit in nightPartId.codeUnits) {
          acc = ((acc * 31) + unit) % 40 + 50;
        }
        return acc;
    }
  }

  /// منع تصادم تنبيهين في نفس الثانية الفعلية:
  /// الأولوية المطلقة للحدث الأول (الأذان) في الثانية +0s، وتُزاح الأحداث المتزامنة بمقدار +2s تتابعياً حتى سقف +30s
  static DateTime resolveCollisionSafeTime(
    DateTime desiredTime,
    Set<int> occupiedEpochSeconds, {
    int stepSeconds = 2,
    int maxOffsetSeconds = 30,
  }) {
    final cleanTime = desiredTime.isUtc
        ? DateTime.utc(
            desiredTime.year,
            desiredTime.month,
            desiredTime.day,
            desiredTime.hour,
            desiredTime.minute,
            desiredTime.second,
          )
        : DateTime(
            desiredTime.year,
            desiredTime.month,
            desiredTime.day,
            desiredTime.hour,
            desiredTime.minute,
            desiredTime.second,
          );

    int candidateSec = cleanTime.millisecondsSinceEpoch ~/ 1000;
    int offsetSeconds = 0;

    while (occupiedEpochSeconds.contains(candidateSec) &&
        offsetSeconds < maxOffsetSeconds) {
      offsetSeconds += stepSeconds;
      candidateSec += stepSeconds;
    }

    occupiedEpochSeconds.add(candidateSec);
    return cleanTime.add(Duration(seconds: offsetSeconds));
  }
}
