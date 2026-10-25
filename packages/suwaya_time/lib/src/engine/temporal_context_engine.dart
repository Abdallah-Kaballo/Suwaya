import 'package:hijri/hijri_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import '../calculators/polar_cycle_synthesizer.dart';
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

  Map<String, dynamic> toJson() => {
    'year': year,
    'month': month,
    'day': day,
    'weekday': weekday,
  };

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

  Map<String, dynamic> toJson() => {
    'year': year,
    'month': month,
    'day': day,
    'lengthOfMonth': lengthOfMonth,
    'calendarSystem': calendarSystem.name,
    'adjustmentDays': adjustmentDays,
    'confidence': confidence.name,
  };
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

/// التنفيذ الهجين المعتمد على تقويم أم القرى مع مسار حسابي قياسي (Tabular Fallback) للتواريخ خارج نطاق الجدول
class UmmAlQuraHijriProvider implements HijriCalendarProvider {
  const UmmAlQuraHijriProvider();

  @override
  HijriDate dateForGregorianDate({
    required CivilDate date,
    int adjustmentDays = 0,
  }) {
    final clampedAdj = adjustmentDays.clamp(-2, 2);
    final targetGreg = date.addDays(clampedAdj).toDateTimeUtc();

    try {
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
    } catch (_) {
      return _tabularHijriFromGregorian(targetGreg, clampedAdj);
    }
  }

  @override
  CivilDate gregorianForHijriDate({
    required int hYear,
    required int hMonth,
    required int hDay,
    int adjustmentDays = 0,
  }) {
    final clampedAdj = adjustmentDays.clamp(-2, 2);
    try {
      final rawGreg = HijriCalendar().hijriToGregorian(hYear, hMonth, hDay);
      final adjusted = DateTime.utc(
        rawGreg.year,
        rawGreg.month,
        rawGreg.day,
      ).subtract(Duration(days: clampedAdj));
      return CivilDate(adjusted.year, adjusted.month, adjusted.day);
    } catch (_) {
      return _tabularGregorianFromHijri(hYear, hMonth, hDay, clampedAdj);
    }
  }

  int daysInHijriMonth(int hYear, int hMonth) {
    final safeMonth = hMonth.clamp(1, 12);
    try {
      return HijriCalendar().getDaysInMonth(hYear, safeMonth);
    } catch (_) {
      return (safeMonth.isOdd || (safeMonth == 12 && _isTabularLeap(hYear)))
          ? 30
          : 29;
    }
  }

  /// خوارزمية التقويم الهجري القياسي (Kuwaiti/Tabular Arithmetic) للتواريخ البعيدة خارج جدول أم القرى
  static HijriDate _tabularHijriFromGregorian(
    DateTime gregUtc,
    int adjustmentDays,
  ) {
    final int jd = _gregorianToJulianDay(
      gregUtc.year,
      gregUtc.month,
      gregUtc.day,
    );
    final int l = jd - 1948440 + 10632;
    final int n = (l - 1) ~/ 10631;
    final int l2 = l - 10631 * n + 354;
    final int j =
        ((10985 - l2) ~/ 5316) * ((50 * l2) ~/ 17719) +
        (l2 ~/ 5670) * ((43 * l2) ~/ 15238);
    final int l3 =
        l2 -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) +
        29;
    final int hMonth = (24 * l3) ~/ 709;
    final int hDay = l3 - (709 * hMonth) ~/ 24;
    final int hYear = 30 * n + j - 30;
    final int monthLen =
        (hMonth.isOdd || (hMonth == 12 && _isTabularLeap(hYear))) ? 30 : 29;

    return HijriDate(
      year: hYear,
      month: hMonth.clamp(1, 12),
      day: hDay.clamp(1, 30),
      lengthOfMonth: monthLen,
      calendarSystem: HijriCalendarSystem.tabular,
      adjustmentDays: adjustmentDays,
      confidence: TemporalConfidence.fallback,
    );
  }

  static CivilDate _tabularGregorianFromHijri(
    int hYear,
    int hMonth,
    int hDay,
    int adjustmentDays,
  ) {
    final int jd =
        ((11 * hYear + 3) ~/ 30) +
        354 * hYear +
        30 * hMonth -
        ((hMonth - 1) ~/ 2) +
        hDay +
        1948440 -
        385;
    final raw = _julianDayToGregorian(jd);
    return raw.addDays(-adjustmentDays);
  }

  static bool _isTabularLeap(int hYear) => ((11 * hYear + 14) % 30) < 11;

  static int _gregorianToJulianDay(int y, int m, int d) {
    final int a = (14 - m) ~/ 12;
    final int y2 = y + 4800 - a;
    final int m2 = m + 12 * a - 3;
    return d +
        ((153 * m2 + 2) ~/ 5) +
        365 * y2 +
        (y2 ~/ 4) -
        (y2 ~/ 100) +
        (y2 ~/ 400) -
        32045;
  }

  static CivilDate _julianDayToGregorian(int jd) {
    final int l = jd + 68569;
    final int n = (4 * l) ~/ 146097;
    final int l2 = l - ((146097 * n + 3) ~/ 4);
    final int i = (4000 * (l2 + 1)) ~/ 1461001;
    final int l3 = l2 - ((1461 * i) ~/ 4) + 31;
    final int j = (80 * l3) ~/ 2447;
    final int day = l3 - ((2447 * j) ~/ 80);
    final int l4 = j ~/ 11;
    final int month = j + 2 - 12 * l4;
    final int year = 100 * (n - 49) + i + l4;
    return CivilDate(year, month, day);
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

  Map<String, dynamic> toJson() => {
    'timezoneId': timezoneId,
    'utcOffsetMinutes': utcOffset.inMinutes,
    'isDaylightSavingTime': isDaylightSavingTime,
    'confidence': confidence.name,
  };
}

class TimezoneResolver {
  static const int _maxCachedLocations = 32;
  static final Map<String, tz.Location> _locationCache = {};

  static tz.Location? _getLocationCached(String timezoneId) {
    final trimmed = timezoneId.trim();
    if (trimmed.isEmpty) return null;

    final existing = _locationCache.remove(trimmed);
    if (existing != null) {
      // إعادة الإدراج في النهاية للحفاظ على ترتيب LRU
      _locationCache[trimmed] = existing;
      return existing;
    }

    try {
      final loc = tz.getLocation(trimmed);
      if (_locationCache.length >= _maxCachedLocations) {
        _locationCache.remove(_locationCache.keys.first);
      }
      _locationCache[trimmed] = loc;
      return loc;
    } catch (_) {
      return null;
    }
  }

  /// حساب تصحيح الشروق والغروب الناتج عن الارتفاع عن سطح البحر (بالمتر)
  /// يبكر الشروق ويتأخر الغروب بمقدار ~0.0347 درجة لكل جذر تربيعي للمتر
  static Duration elevationDipTimeAdjustment(
    double elevationMeters,
    double latitudeDegrees,
  ) {
    if (elevationMeters <= 0) return Duration.zero;
    final dipDegrees =
        0.0347 * (elevationMeters > 10000 ? 100.0 : _sqrt(elevationMeters));
    // كل درجة قوسية للشمس تعادل 4 دقائق زمنية عند خط الاستواء وتزداد مع جيب تمام خط العرض
    final latRad =
        (latitudeDegrees.abs().clamp(0.0, 60.0)) * 0.017453292519943295;
    final cosLat = _cosApprox(latRad);
    final extraMinutes = (4.0 * dipDegrees) / (cosLat > 0.25 ? cosLat : 0.25);
    return Duration(microseconds: (extraMinutes * 60 * 1000000).round());
  }

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double z = x;
    for (int i = 0; i < 8; i++) {
      z = 0.5 * (z + x / z);
    }
    return z;
  }

  static double _cosApprox(double rad) {
    final x2 = rad * rad;
    return 1.0 - (x2 / 2.0) + (x2 * x2 / 24.0);
  }

  static TimezoneContext resolveForInstant(
    DateTime instantUtc, {
    String? timezoneId,
    Duration? fallbackOffset,
  }) {
    final utc = instantUtc.toUtc();
    if (timezoneId != null && timezoneId.isNotEmpty) {
      final location = _getLocationCached(timezoneId);
      if (location != null) {
        final tzInstant = tz.TZDateTime.from(utc, location);
        return TimezoneContext(
          timezoneId: location.name,
          utcOffset: tzInstant.timeZoneOffset,
          isDaylightSavingTime: tzInstant.timeZone.isDst,
          confidence: TemporalConfidence.exact,
        );
      }
    }

    if (fallbackOffset != null) {
      return TimezoneContext(
        timezoneId: null,
        utcOffset: fallbackOffset,
        isDaylightSavingTime: false,
        confidence: TemporalConfidence.adjusted,
      );
    }

    // حساب إزاحة النظام المحلي في نفس اللحظة التاريخية/المستقبلية المطلوبة وليس اللحظة الحالية
    final localAtInstant = utc.toLocal();
    return TimezoneContext(
      timezoneId: null,
      utcOffset: localAtInstant.timeZoneOffset,
      isDaylightSavingTime: false,
      confidence: TemporalConfidence.fallback,
    );
  }

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

/// السياق الزمني الموحد (النواة المرجعية للزمن في سُويعة)
class SuwayaTemporalContext {
  final DateTime instantUtc;
  final DateTime cityWallTime;
  final TimezoneContext timezone;

  final CivilDate civilDate;
  final int civilWeekday;

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

  Map<String, dynamic> toJson() => {
    'instantUtc': instantUtc.toIso8601String(),
    'cityWallTime': cityWallTime.toIso8601String(),
    'timezone': timezone.toJson(),
    'civilDate': civilDate.toJson(),
    'islamicLogicalGregorianDate': islamicLogicalGregorianDate.toJson(),
    'hijriDate': hijriDate.toJson(),
    'isIslamicNight': isIslamicNight,
    'astroState': astroState.toJson(),
  };
}

class TemporalContextEngine {
  static const HijriCalendarProvider _defaultHijriProvider =
      UmmAlQuraHijriProvider();

  static const int _maxCachedDays = 24;
  static final Map<String, SuwayaDay> _internalDayCache = {};
  static final Map<String, IbadatTimings> _internalCivilIbadatCache = {};

  /// مسح الذاكرة المؤقتة الداخلية (مفيد عند الاختبارات أو إعادة التعيين)
  static void clearCache() {
    _internalDayCache.clear();
    _internalCivilIbadatCache.clear();
  }

  static String _buildConfigKey({
    required double latitude,
    required double longitude,
    required String? timezoneId,
    required Duration? fallbackOffset,
    required CalculationMethodType methodType,
    required MadhabType madhabType,
    required HighLatitudeRuleType highLatRuleType,
    required double customFajrAngle,
    required double customIshaAngle,
    required Map<PrayerKey, int>? manualOffsets,
    required PolarResolutionPolicy polarPolicy,
  }) {
    final latKey = (latitude * 10000).round();
    final lngKey = (longitude * 10000).round();
    final fallbackKey = fallbackOffset?.inMinutes.toString() ?? 'none';
    final offsetsKey = manualOffsets == null || manualOffsets.isEmpty
        ? ''
        : (manualOffsets.entries.toList()
                ..sort((a, b) => a.key.index.compareTo(b.key.index)))
              .map((e) => '${e.key.index}:${e.value}')
              .join(',');
    return '$latKey:$lngKey:${timezoneId ?? ''}:$fallbackKey:${methodType.index}:'
        '${madhabType.index}:${highLatRuleType.index}:'
        '$customFajrAngle:$customIshaAngle:${polarPolicy.index}:$offsetsKey';
  }

  /// توليد السياق الزمني الكامل للحظة معينة مع تخزين مؤقت تلقائي عالي السرعة O(1)
  static SuwayaTemporalContext evaluate({
    required DateTime instantUtc,
    required double latitude,
    required double longitude,
    String? timezoneId,
    Duration? fallbackOffset,
    CalculationMethodType methodType = CalculationMethodType.muslimWorldLeague,
    MadhabType madhabType = MadhabType.shafi,
    HighLatitudeRuleType highLatRuleType =
        HighLatitudeRuleType.middleOfTheNight,
    double customFajrAngle = 18.0,
    double customIshaAngle = 18.0,
    Map<PrayerKey, int>? manualOffsets,
    int hijriAdjustmentDays = 0,
    HijriCalendarProvider hijriProvider = _defaultHijriProvider,
    PolarResolutionPolicy polarPolicy = PolarResolutionPolicy.nearestLatitude45,
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
    final civilDate = CivilDate(
      cityNowWall.year,
      cityNowWall.month,
      cityNowWall.day,
    );

    final configKey = _buildConfigKey(
      latitude: latitude,
      longitude: longitude,
      timezoneId: timezoneId,
      fallbackOffset: fallbackOffset,
      methodType: methodType,
      madhabType: madhabType,
      highLatRuleType: highLatRuleType,
      customFajrAngle: customFajrAngle,
      customIshaAngle: customIshaAngle,
      manualOffsets: manualOffsets,
      polarPolicy: polarPolicy,
    );

    final civilCacheKey =
        '${civilDate.year}-${civilDate.month}-${civilDate.day}_${currentTz.utcOffset.inMinutes}_$configKey';

    IbadatTimings? todayIbadat = _internalCivilIbadatCache.remove(
      civilCacheKey,
    );
    if (todayIbadat != null) {
      _internalCivilIbadatCache[civilCacheKey] = todayIbadat;
    } else {
      final nextCivilDayWall = cityNowWall.add(const Duration(days: 1));
      final nextCivilOffset = offsetAt(
        DateTime.utc(
          nextCivilDayWall.year,
          nextCivilDayWall.month,
          nextCivilDayWall.day,
          12,
        ),
      );
      todayIbadat = PrayerCalculator.getIbadatTimings(
        latitude,
        longitude,
        cityNowWall,
        methodType,
        madhabType,
        highLatRuleType,
        customFajrAngle,
        customIshaAngle,
        currentTz.utcOffset,
        nextDayCityOffset: nextCivilOffset,
        manualOffsets: manualOffsets,
        offsetResolver: offsetAt,
      );
      if (_internalCivilIbadatCache.length >= _maxCachedDays) {
        _internalCivilIbadatCache.remove(_internalCivilIbadatCache.keys.first);
      }
      _internalCivilIbadatCache[civilCacheKey] = todayIbadat;
    }

    final DateTime anchorDateForCycle =
        cityNowWall.isBefore(todayIbadat.maghrib)
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

    final cycleCacheKey =
        '${anchorDateForCycle.year}-${anchorDateForCycle.month}-${anchorDateForCycle.day}_'
        '${cycleStartOffset.inMinutes}_${cycleNextDayOffset.inMinutes}_$configKey';

    SuwayaDay? baseDay = cachedDay ?? _internalDayCache.remove(cycleCacheKey);
    if (baseDay != null) {
      _internalDayCache[cycleCacheKey] = baseDay;
    } else {
      baseDay = SuwayaTimeEngine.generateDay(
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
        civilDayIbadatOverride: todayIbadat,
        polarPolicy: polarPolicy,
      );
      if (_internalDayCache.length >= _maxCachedDays) {
        _internalDayCache.remove(_internalDayCache.keys.first);
      }
      _internalDayCache[cycleCacheKey] = baseDay;
    }

    final suwayaDay = baseDay.withCivilDayIbadat(todayIbadat);
    final astroState = SuwayaTimeEngine.calculateCurrentState(
      suwayaDay,
      cityNowWall,
      nowUtc: utcNow,
    );

    final astronomicalSunsetWall =
        todayIbadat.calculatedSunset ?? todayIbadat.maghrib;
    final bool isAfterTodaySunset = !cityNowWall.isBefore(
      astronomicalSunsetWall,
    );

    final CivilDate islamicLogicalDate = isAfterTodaySunset
        ? civilDate.addDays(1)
        : civilDate;

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
