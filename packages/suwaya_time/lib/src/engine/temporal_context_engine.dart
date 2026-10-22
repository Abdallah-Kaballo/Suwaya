import 'package:hijri/hijri_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

import '../calculators/prayer_calculator.dart';
import '../models/astro_models.dart';
import 'suwaya_time_engine.dart';

/// سياسة بداية اليوم
enum DayBoundaryPolicy { maghrib, civilMidnight }

/// نظام التقويم الهجري المستخدم
enum HijriCalendarSystem { ummAlQura, tabular, custom }

/// درجة اليقين في الحساب الزمني أو التقويمي
enum TemporalConfidence { exact, adjusted, fallback }

/// تمثيل نقي للتاريخ المدني المحلي
class CivilDate {
  final int year;
  final int month;
  final int day;

  const CivilDate(this.year, this.month, this.day);

  DateTime toDateTimeUtc() => DateTime.utc(year, month, day);

  int get weekday => toDateTimeUtc().weekday;

  CivilDate addDays(int days) {
    final dt = toDateTimeUtc().add(Duration(days: days));
    return CivilDate(dt.year, dt.month, dt.day);
  }

  @override
  bool operator ==(Object other) =>
      other is CivilDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);
}

/// تمثيل غني للتاريخ الهجري مع مصدره ودرجة اليقين
class HijriDate {
  final int year;
  final int month;
  final int day;
  final int lengthOfMonth;
  final HijriCalendarSystem calendarSystem;
  final int adjustmentDays;
  final TemporalConfidence confidence;

  const HijriDate({
    required this.year,
    required this.month,
    required this.day,
    required this.lengthOfMonth,
    this.calendarSystem = HijriCalendarSystem.ummAlQura,
    this.adjustmentDays = 0,
    this.confidence = TemporalConfidence.exact,
  });
}

/// واجهة مجردة قابلة للتبديل لحساب التاريخ الهجري
abstract interface class HijriCalendarProvider {
  HijriDate dateForGregorianDate({
    required CivilDate date,
    int adjustmentDays = 0,
  });

  CivilDate gregorianForHijriDate({
    required int hYear,
    required int hMonth,
    required int hDay,
    int adjustmentDays = 0,
  });
}

/// التنفيذ الافتراضي المعتمد على تقويم أم القرى مع دعم تصحيح الأيام (-2..+2)
class UmmAlQuraHijriProvider implements HijriCalendarProvider {
  const UmmAlQuraHijriProvider();

  @override
  HijriDate dateForGregorianDate({
    required CivilDate date,
    int adjustmentDays = 0,
  }) {
    final clampedAdj = adjustmentDays.clamp(-2, 2);
    final targetGreg = date.addDays(clampedAdj).toDateTimeUtc();
    final hCal = HijriCalendar.fromDate(targetGreg);
    final monthLen = hCal.getDaysInMonth(hCal.hYear, hCal.hMonth);

    return HijriDate(
      year: hCal.hYear,
      month: hCal.hMonth,
      day: hCal.hDay,
      lengthOfMonth: monthLen,
      calendarSystem: HijriCalendarSystem.ummAlQura,
      adjustmentDays: clampedAdj,
      confidence: clampedAdj == 0
          ? TemporalConfidence.exact
          : TemporalConfidence.adjusted,
    );
  }

  @override
  CivilDate gregorianForHijriDate({
    required int hYear,
    required int hMonth,
    required int hDay,
    int adjustmentDays = 0,
  }) {
    final clampedAdj = adjustmentDays.clamp(-2, 2);
    final rawGreg = HijriCalendar().hijriToGregorian(hYear, hMonth, hDay);
    final adjusted = DateTime.utc(rawGreg.year, rawGreg.month, rawGreg.day)
        .subtract(Duration(days: clampedAdj));
    return CivilDate(adjusted.year, adjusted.month, adjusted.day);
  }
}

/// معلومات المنطقة الزمنية والتوقيت الصيفي عند لحظة محددة
class TimezoneContext {
  final String? timezoneId;
  final Duration utcOffset;
  final bool isDaylightSavingTime;
  final TemporalConfidence confidence;

  const TimezoneContext({
    required this.timezoneId,
    required this.utcOffset,
    required this.isDaylightSavingTime,
    required this.confidence,
  });
}

/// محلل المنطقة الزمنية باستخدام قاعدة بيانات IANA (timezone)
class TimezoneResolver {
  static TimezoneContext resolveForInstant(
    DateTime instantUtc, {
    String? timezoneId,
    Duration? fallbackOffset,
  }) {
    final utc = instantUtc.toUtc();
    if (timezoneId != null && timezoneId.trim().isNotEmpty) {
      try {
        final location = tz.getLocation(timezoneId.trim());
        final tzInstant = tz.TZDateTime.from(utc, location);
        return TimezoneContext(
          timezoneId: location.name,
          utcOffset: tzInstant.timeZoneOffset,
          isDaylightSavingTime: tzInstant.timeZone.isDst,
          confidence: TemporalConfidence.exact,
        );
      } catch (_) {}
    }

    final offset = fallbackOffset ?? DateTime.now().timeZoneOffset;
    return TimezoneContext(
      timezoneId: null,
      utcOffset: offset,
      isDaylightSavingTime: false,
      confidence: TemporalConfidence.fallback,
    );
  }

  /// تحويل لحظة عالمية (UTC) إلى ساعة حائط محلية للمدينة
  static DateTime toWallClock(
    DateTime instantUtc, {
    String? timezoneId,
    Duration? fallbackOffset,
  }) {
    final ctx = resolveForInstant(
      instantUtc,
      timezoneId: timezoneId,
      fallbackOffset: fallbackOffset,
    );
    return instantUtc.toUtc().add(ctx.utcOffset);
  }
}

/// 🌟 السياق الزمني الموحد (النواة المرجعية للزمن في سُويعة)
class SuwayaTemporalContext {
  final DateTime instantUtc;
  final DateTime cityWallTime;
  final TimezoneContext timezone;

  /// التاريخ المدني المحلي (يتغير عند 00:00 منتصف الليل)
  final CivilDate civilDate;
  final int civilWeekday;

  /// التاريخ المنطقي لليوم الهجري والدورة السويعية (يتقدم عند الغروب الفلكي ولا يتقدم مرة ثانية عند 00:00)
  final CivilDate islamicLogicalGregorianDate;
  final int islamicWeekday;
  final HijriDate hijriDate;
  final bool isIslamicNight;

  final SuwayaDay suwayaDay;
  final AstroState astroState;

  const SuwayaTemporalContext({
    required this.instantUtc,
    required this.cityWallTime,
    required this.timezone,
    required this.civilDate,
    required this.civilWeekday,
    required this.islamicLogicalGregorianDate,
    required this.islamicWeekday,
    required this.hijriDate,
    required this.isIslamicNight,
    required this.suwayaDay,
    required this.astroState,
  });
}

class TemporalContextEngine {
  static const HijriCalendarProvider _defaultHijriProvider =
      UmmAlQuraHijriProvider();

  /// توليد السياق الزمني الكامل للحظة معينة من مصدر موحد
  static SuwayaTemporalContext evaluate({
    required DateTime instantUtc,
    required double latitude,
    required double longitude,
    String? timezoneId,
    Duration? fallbackOffset,
    CalculationMethodType methodType = CalculationMethodType.muslimWorldLeague,
    MadhabType madhabType = MadhabType.shafi,
    HighLatitudeRuleType highLatRuleType = HighLatitudeRuleType.middleOfTheNight,
    double customFajrAngle = 18.0,
    double customIshaAngle = 18.0,
    Map<PrayerKey, int>? manualOffsets,
    int hijriAdjustmentDays = 0,
    HijriCalendarProvider hijriProvider = _defaultHijriProvider,
    SuwayaDay? cachedDay,
  }) {
    final utcNow = instantUtc.toUtc();
    Duration offsetAt(DateTime utc) => TimezoneResolver.resolveForInstant(
          utc,
          timezoneId: timezoneId,
          fallbackOffset: fallbackOffset,
        ).utcOffset;

    final currentTz = TimezoneResolver.resolveForInstant(
      utcNow,
      timezoneId: timezoneId,
      fallbackOffset: fallbackOffset,
    );
    final cityNowWall = utcNow.add(currentTz.utcOffset);
    final civilDate =
        CivilDate(cityNowWall.year, cityNowWall.month, cityNowWall.day);

    // فحص مواقيت اليوم المدني الحالي لمعرفة موقع اللحظة الحالية بالنسبة للمغرب والغروب الفلكي
    final todayIbadat = PrayerCalculator.getIbadatTimings(
      latitude,
      longitude,
      cityNowWall,
      methodType,
      madhabType,
      highLatRuleType,
      customFajrAngle,
      customIshaAngle,
      currentTz.utcOffset,
      manualOffsets: manualOffsets,
      offsetResolver: offsetAt,
    );

    // الدورة السويعية تبدأ من المغرب
    final DateTime anchorDateForCycle = cityNowWall.isBefore(todayIbadat.maghrib)
        ? cityNowWall.subtract(const Duration(days: 1))
        : cityNowWall;

    final nextDayAnchor = anchorDateForCycle.add(const Duration(days: 1));
    final cycleStartOffset = offsetAt(
      DateTime.utc(
        anchorDateForCycle.year,
        anchorDateForCycle.month,
        anchorDateForCycle.day,
        12,
      ),
    );
    final cycleNextDayOffset = offsetAt(
      DateTime.utc(
        nextDayAnchor.year,
        nextDayAnchor.month,
        nextDayAnchor.day,
        12,
      ),
    );

    final suwayaDay = cachedDay ??
        SuwayaTimeEngine.generateDay(
          latitude,
          longitude,
          anchorDateForCycle,
          methodType,
          madhabType,
          highLatRuleType,
          customFajrAngle,
          customIshaAngle,
          cycleStartOffset,
          nextDayCityOffset: cycleNextDayOffset,
          manualOffsets: manualOffsets,
          offsetResolver: offsetAt,
        );

    final astroState = SuwayaTimeEngine.calculateCurrentState(
      suwayaDay,
      cityNowWall,
      nowUtc: utcNow,
    );

    // 🌟 قاعدة اليوم الهجري الشرعي والليلة:
    // يتقدم التاريخ الهجري عند الغروب الفلكي الصافي (calculatedSunset) ولا يتقدم مرة ثانية عند 00:00 منتصف الليل!
    final astronomicalSunsetWall =
        todayIbadat.calculatedSunset ?? todayIbadat.maghrib;
    final bool isAfterTodaySunset =
        !cityNowWall.isBefore(astronomicalSunsetWall);

    final CivilDate islamicLogicalDate =
        isAfterTodaySunset ? civilDate.addDays(1) : civilDate;

    // الليلة الشرعية تمتد من الغروب حتى الفجر
    final bool isIslamicNight =
        isAfterTodaySunset || cityNowWall.isBefore(todayIbadat.fajr);

    final hijriDate = hijriProvider.dateForGregorianDate(
      date: islamicLogicalDate,
      adjustmentDays: hijriAdjustmentDays,
    );

    return SuwayaTemporalContext(
      instantUtc: utcNow,
      cityWallTime: cityNowWall,
      timezone: currentTz,
      civilDate: civilDate,
      civilWeekday: civilDate.weekday,
      islamicLogicalGregorianDate: islamicLogicalDate,
      islamicWeekday: islamicLogicalDate.weekday,
      hijriDate: hijriDate,
      isIslamicNight: isIslamicNight,
      suwayaDay: suwayaDay,
      astroState: astroState,
    );
  }
}