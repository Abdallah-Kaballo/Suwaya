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

    // 🌟 استخدام إزاحة اليوم التالي لـ nextFajr لمعالجة عبور التوقيت الصيفي/الشتوي في منتصف الليل
    final effectiveNextOffset = nextDayCityOffset ?? cityOffset;

    final fajr = _applyOffset(
      today.fajr.toUtc().add(cityOffset),
      PrayerKey.fajr,
      allowedManualOffsets,
    );
    final sunrise = today.sunrise.toUtc().add(cityOffset);
    final dhuhr = _applyOffset(
      today.dhuhr.toUtc().add(cityOffset),
      PrayerKey.dhuhr,
      allowedManualOffsets,
    );
    final asr = _applyOffset(
      today.asr.toUtc().add(cityOffset),
      PrayerKey.asr,
      allowedManualOffsets,
    );
    final maghrib = _applyOffset(
      today.maghrib.toUtc().add(cityOffset),
      PrayerKey.maghrib,
      allowedManualOffsets,
    );
    final isha = _applyOffset(
      today.isha.toUtc().add(cityOffset),
      PrayerKey.isha,
      allowedManualOffsets,
    );
    final nextFajr = _applyOffset(
      tomorrow.fajr.toUtc().add(effectiveNextOffset),
      PrayerKey.fajr,
      allowedManualOffsets,
    );

    return IbadatTimings(
      fajr: fajr,
      sunrise: sunrise,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
      isha: isha,
      nextFajr: nextFajr,
      nightParts: NightDivision.calculateNightParts(maghrib, nextFajr),
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

    // 🌟 تطبيق cityOffset على أحداث المساء (dayD) وتطبيق effectiveNextOffset على أحداث اليوم التالي (dayDPlus1)
    final effectiveNextOffset = nextDayCityOffset ?? cityOffset;

    final cycleStartMaghrib = _applyOffset(
      dayD.maghrib.toUtc().add(cityOffset),
      PrayerKey.maghrib,
      allowedManualOffsets,
    );
    final cycleIsha = _applyOffset(
      dayD.isha.toUtc().add(cityOffset),
      PrayerKey.isha,
      allowedManualOffsets,
    );

    final cycleFajr = _applyOffset(
      dayDPlus1.fajr.toUtc().add(effectiveNextOffset),
      PrayerKey.fajr,
      allowedManualOffsets,
    );
    final cycleSunrise = dayDPlus1.sunrise.toUtc().add(effectiveNextOffset);
    final cycleDhuhr = _applyOffset(
      dayDPlus1.dhuhr.toUtc().add(effectiveNextOffset),
      PrayerKey.dhuhr,
      allowedManualOffsets,
    );
    final cycleAsr = _applyOffset(
      dayDPlus1.asr.toUtc().add(effectiveNextOffset),
      PrayerKey.asr,
      allowedManualOffsets,
    );
    final cycleEndMaghrib = _applyOffset(
      dayDPlus1.maghrib.toUtc().add(effectiveNextOffset),
      PrayerKey.maghrib,
      allowedManualOffsets,
    );

    final nightMicroseconds =
        cycleFajr.difference(cycleStartMaghrib).inMicroseconds;
    final sharIMidnight = cycleStartMaghrib.add(
      Duration(microseconds: nightMicroseconds ~/ 2),
    );

    return SuwayaCycleAnchors(
      cycleStartMaghrib: cycleStartMaghrib,
      cycleIsha: cycleIsha,
      sharIMidnight: sharIMidnight,
      cycleFajr: cycleFajr,
      cycleSunrise: cycleSunrise,
      cycleDhuhr: cycleDhuhr,
      cycleAsr: cycleAsr,
      cycleEndMaghrib: cycleEndMaghrib,
    );
  }
}