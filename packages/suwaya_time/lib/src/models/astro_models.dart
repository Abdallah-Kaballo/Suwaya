/// يحدد النطاق العام للسويعة (ليل أم نهار)
enum SuwayaPhase {
  night, day;
  bool get isNight => this == SuwayaPhase.night;
  bool get isDay => this == SuwayaPhase.day;
}

enum PeriodKey {
  nightMaghribIsha, nightIshaMidnight, nightMidnightFajr, nightFajrSunrise,
  daySunriseDhuhr, dayDhuhrAsr, dayAsrMaghrib;
}

class SuwayaCycleAnchors {
  final DateTime cycleStartMaghrib,
      cycleIsha,
      sharIMidnight,
      cycleFajr,
      cycleSunrise,
      cycleDhuhr,
      cycleAsr,
      cycleEndMaghrib;

  // 🌟 اللحظات العالمية الحقيقية (UTC Instants) لضمان دقة المدد عبر التوقيت الصيفي
  final DateTime? cycleStartMaghribUtc,
      cycleIshaUtc,
      sharIMidnightUtc,
      cycleFajrUtc,
      cycleSunriseUtc,
      cycleDhuhrUtc,
      cycleAsrUtc,
      cycleEndMaghribUtc;

  // 🌟 الغروب الفلكي الصافي (غير متأثر بالتعديل اليدوي لدقائق الأذان) لتحديد بداية التاريخ الهجري
  final DateTime? calculatedStartSunset, calculatedEndSunset;
  final DateTime? calculatedStartSunsetUtc, calculatedEndSunsetUtc;

  const SuwayaCycleAnchors({
    required this.cycleStartMaghrib,
    required this.cycleIsha,
    required this.sharIMidnight,
    required this.cycleFajr,
    required this.cycleSunrise,
    required this.cycleDhuhr,
    required this.cycleAsr,
    required this.cycleEndMaghrib,
    this.cycleStartMaghribUtc,
    this.cycleIshaUtc,
    this.sharIMidnightUtc,
    this.cycleFajrUtc,
    this.cycleSunriseUtc,
    this.cycleDhuhrUtc,
    this.cycleAsrUtc,
    this.cycleEndMaghribUtc,
    this.calculatedStartSunset,
    this.calculatedEndSunset,
    this.calculatedStartSunsetUtc,
    this.calculatedEndSunsetUtc,
  });

  bool get isValidSequence {
    if (cycleStartMaghribUtc != null &&
        cycleIshaUtc != null &&
        sharIMidnightUtc != null &&
        cycleFajrUtc != null &&
        cycleSunriseUtc != null &&
        cycleDhuhrUtc != null &&
        cycleAsrUtc != null &&
        cycleEndMaghribUtc != null) {
      return cycleStartMaghribUtc!.isBefore(cycleIshaUtc!) &&
          cycleIshaUtc!.isBefore(sharIMidnightUtc!) &&
          sharIMidnightUtc!.isBefore(cycleFajrUtc!) &&
          cycleFajrUtc!.isBefore(cycleSunriseUtc!) &&
          cycleSunriseUtc!.isBefore(cycleDhuhrUtc!) &&
          cycleDhuhrUtc!.isBefore(cycleAsrUtc!) &&
          cycleAsrUtc!.isBefore(cycleEndMaghribUtc!);
    }
    return cycleStartMaghrib.isBefore(cycleIsha) &&
        cycleIsha.isBefore(sharIMidnight) &&
        sharIMidnight.isBefore(cycleFajr) &&
        cycleFajr.isBefore(cycleSunrise) &&
        cycleSunrise.isBefore(cycleDhuhr) &&
        cycleDhuhr.isBefore(cycleAsr) &&
        cycleAsr.isBefore(cycleEndMaghrib);
  }
}

class SuwayaClockTime {
  final SuwayaPhase phase;
  final int phaseSlotNumber;
  final PeriodKey periodKey;
  final int periodLocalSlotNumber;
  final double slotProgress;
  final DateTime cycleStartDate;
  final DateTime instant;

  const SuwayaClockTime({
    required this.phase, required this.phaseSlotNumber, required this.periodKey,
    required this.periodLocalSlotNumber, required this.slotProgress,
    required this.cycleStartDate, required this.instant,
  });

  int get virtualMinute => ((slotProgress * 3600) ~/ 60).clamp(0, 59);
  int get virtualSecond => ((slotProgress * 3600).floor() % 60).clamp(0, 59);
}

class AstroPeriod {
  final int id;
  final PeriodKey periodKey;
  final String nameKey;
  final DateTime startTime, endTime;
  final DateTime? startUtc, endUtc; // 🌟 اللحظات الفعلية لحساب المدة الحقيقية
  final int suwayasCount, colorValue;

  const AstroPeriod({
    required this.id,
    required this.periodKey,
    required this.nameKey,
    required this.startTime,
    required this.endTime,
    this.startUtc,
    this.endUtc,
    required this.suwayasCount,
    required this.colorValue,
  });

  /// 🌟 المدة الحقيقية المنقضية بالثواني العالمية (لا تتشوه بتقديم أو تأخير التوقيت الصيفي)
  Duration get totalDuration {
    if (startUtc != null && endUtc != null) {
      return endUtc!.difference(startUtc!);
    }
    return endTime.difference(startTime);
  }
}

class NightPart {
  final String id, nameKey;
  final DateTime startTime, endTime;
  final DateTime? startUtc, endUtc;

  const NightPart({
    required this.id,
    required this.nameKey,
    required this.startTime,
    required this.endTime,
    this.startUtc,
    this.endUtc,
  });

  Duration get realDuration =>
      (startUtc != null && endUtc != null)
          ? endUtc!.difference(startUtc!)
          : endTime.difference(startTime);
}

class IbadatTimings {
  final DateTime fajr, sunrise, dhuhr, asr, maghrib, isha, nextFajr;
  final DateTime? calculatedSunset; // 🌟 الغروب الفلكي الصافي لبداية الليلة الهجرية
  final List<NightPart> nightParts;

  const IbadatTimings({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.nextFajr,
    this.calculatedSunset,
    required this.nightParts,
  });
}

class SuwayaDay {
  final IbadatTimings ibadatTimings;
  final SuwayaCycleAnchors cycleAnchors; 
  final List<AstroPeriod> periods;

  const SuwayaDay({required this.ibadatTimings, required this.cycleAnchors, required this.periods});
}

class AstroState {
  final DateTime virtualTime;
  final DateTime? instantUtc; // 🌟 اللحظة العالمية الحقيقية
  final List<AstroPeriod> periods;
  final AstroPeriod currentPeriod;
  final SuwayaClockTime currentSuwayaTime;
  final double timeSpeedMultiplier;
  final IbadatTimings ibadatTimings;
  final SuwayaCycleAnchors cycleAnchors;

  const AstroState({
    required this.virtualTime,
    this.instantUtc,
    required this.periods,
    required this.currentPeriod,
    required this.currentSuwayaTime,
    required this.timeSpeedMultiplier,
    required this.ibadatTimings,
    required this.cycleAnchors,
  });
}

enum CalculationMethodType {
  muslimWorldLeague,
  egyptian,
  karachi,
  ummAlQura,
  dubai,
  northAmerica,
  kuwait,
  qatar,
  singapore,
  tehran,
  turkey,
  franceUoif, // 🌟 إضافة طريقة اتحاد المنظمات الإسلامية في فرنسا (UOIF)
  russia,     // 🌟 إضافة طريقة الإدارة الدينية لمسلمي روسيا
  custom,
}

enum MadhabType { hanafi, shafi }

enum HighLatitudeRuleType {
  middleOfTheNight,
  seventhOfTheNight,
  twilightAngle,
}

enum PrayerKey { fajr, sunrise, dhuhr, asr, maghrib, isha }

extension AstroStringParsers on String {
  String get _normalized => replaceAll('_', '').toLowerCase();

  CalculationMethodType toCalculationMethod() =>
      CalculationMethodType.values.firstWhere(
        (e) => e.name.toLowerCase() == _normalized,
        orElse: () => CalculationMethodType.muslimWorldLeague,
      );

  MadhabType toMadhab() => MadhabType.values.firstWhere(
        (e) => e.name.toLowerCase() == _normalized,
        orElse: () => MadhabType.shafi,
      );

  HighLatitudeRuleType toHighLatRule() =>
      HighLatitudeRuleType.values.firstWhere(
        (e) => e.name.toLowerCase() == _normalized,
        orElse: () => HighLatitudeRuleType.middleOfTheNight,
      );
}

extension AstroMapParsers on Map<String, int> {
  Map<PrayerKey, int> toPrayerKeyMap() {
    final map = <PrayerKey, int>{};
    forEach((key, value) {
      switch (key.toLowerCase()) {
        case '1':
        case 'fajr':
          map[PrayerKey.fajr] = value;
          break;
        case 'sunrise':
          map[PrayerKey.sunrise] = value;
          break;
        case '3':
        case 'dhuhr':
          map[PrayerKey.dhuhr] = value;
          break;
        case '4':
        case 'asr':
          map[PrayerKey.asr] = value;
          break;
        case '5':
        case 'maghrib':
          map[PrayerKey.maghrib] = value;
          break;
        case '9':
        case 'isha':
          map[PrayerKey.isha] = value;
          break;
      }
    });
    return map;
  }
}