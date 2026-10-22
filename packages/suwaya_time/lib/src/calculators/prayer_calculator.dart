import 'package:adhan/adhan.dart';
import '../models/astro_models.dart';
import 'night_division.dart';

class PrayerCalculator {
  /// 🌟 ربط جميع طرق الحساب الـ 14 بمعاملاتها الفلكية الدقيقة في مكتبة adhan
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
        break;
      case HighLatitudeRuleType.middleOfTheNight:
        params.highLatitudeRule = HighLatitudeRule.middle_of_the_night;
        break;
    }
    return params;
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
  }) {
    final coordinates = Coordinates(lat, lng);
    final params = _getParams(
      methodType,
      madhabType,
      highLatRuleType,
      customFajr,
      customIsha,
    );
    final today = PrayerTimes(coordinates, DateComponents.from(date), params);
    final tomorrow = PrayerTimes(
      coordinates,
      DateComponents.from(date.add(const Duration(days: 1))),
      params,
    );

    final allowedManualOffsets = <PrayerKey, int>{};
    if (manualOffsets != null) {
      for (final entry in manualOffsets.entries) {
        if (entry.key != PrayerKey.sunrise) {
          allowedManualOffsets[entry.key] = entry.value.clamp(-30, 30);
        }
      }
    }

    final effectiveNextOffset = nextDayCityOffset ?? cityOffset;

    // 🌟 حساب اللحظات العالمية الفعلية (UTC Instants) أولاً
    final rawSunsetUtc = today.maghrib.toUtc();
    final fajrUtc = _applyOffset(today.fajr.toUtc(), PrayerKey.fajr, allowedManualOffsets);
    final sunriseUtc = today.sunrise.toUtc();
    final dhuhrUtc = _applyOffset(today.dhuhr.toUtc(), PrayerKey.dhuhr, allowedManualOffsets);
    final asrUtc = _applyOffset(today.asr.toUtc(), PrayerKey.asr, allowedManualOffsets);
    final maghribUtc = _applyOffset(rawSunsetUtc, PrayerKey.maghrib, allowedManualOffsets);
    final ishaUtc = _applyOffset(today.isha.toUtc(), PrayerKey.isha, allowedManualOffsets);
    final nextFajrUtc = _applyOffset(tomorrow.fajr.toUtc(), PrayerKey.fajr, allowedManualOffsets);

    DateTime toEveningWall(DateTime utc) =>
        utc.add(offsetResolver != null ? offsetResolver(utc) : cityOffset);
    DateTime toNextDayWall(DateTime utc) =>
        utc.add(offsetResolver != null ? offsetResolver(utc) : effectiveNextOffset);

    // 🌟 دالة تحويل ذكية لأجزاء الليل تراعي لحظة عبور التوقيت الصيفي
    DateTime toNightWall(DateTime utc) {
      if (offsetResolver != null) return utc.add(offsetResolver(utc));
      // عند عدم تمرير محلل منطقة زمنية، نستخدم إزاحة المساء قبل منتصف الليل وإزاحة الصباح بعده
      final halfNightUtc = maghribUtc.add(nextFajrUtc.difference(maghribUtc) ~/ 2);
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
  }) {
    final coordinates = Coordinates(lat, lng);
    final params = _getParams(
      methodType,
      madhabType,
      highLatRuleType,
      customFajr,
      customIsha,
    );

    final dayD = PrayerTimes(
      coordinates,
      DateComponents.from(targetDate),
      params,
    );
    final dayDPlus1 = PrayerTimes(
      coordinates,
      DateComponents.from(targetDate.add(const Duration(days: 1))),
      params,
    );

    final allowedManualOffsets = <PrayerKey, int>{};
    if (manualOffsets != null) {
      for (final entry in manualOffsets.entries) {
        if (entry.key != PrayerKey.sunrise) {
          allowedManualOffsets[entry.key] = entry.value.clamp(-30, 30);
        }
      }
    }

    final effectiveNextOffset = nextDayCityOffset ?? cityOffset;

    // 🌟 1. حساب جميع المراسي بالتوقيت العالمي الفعلي (UTC)
    final rawStartSunsetUtc = dayD.maghrib.toUtc();
    final rawEndSunsetUtc = dayDPlus1.maghrib.toUtc();

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
    final cycleSunriseUtc = dayDPlus1.sunrise.toUtc();
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

    // 🌟 2. حساب منتصف الليل الشرعي بالزمن العالمي الفعلي (وليس بطرح ساعات الحائط)
    final realNightMicroseconds =
        cycleFajrUtc.difference(cycleStartMaghribUtc).inMicroseconds;
    final sharIMidnightUtc = cycleStartMaghribUtc.add(
      Duration(microseconds: realNightMicroseconds ~/ 2),
    );

    // 🌟 3. إسقاط اللحظات العالمية على التوقيت المحلي للمدينة
    DateTime toEveningWall(DateTime utc) =>
        utc.add(offsetResolver != null ? offsetResolver(utc) : cityOffset);
    DateTime toNextDayWall(DateTime utc) =>
        utc.add(offsetResolver != null ? offsetResolver(utc) : effectiveNextOffset);

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