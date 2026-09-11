class AstroPeriod {
  final int id;
  final String name;
  final String nameKey;
  final DateTime startTime;
  final DateTime endTime;
  final int suwayasCount;
  final int colorValue; 

  AstroPeriod({
    required this.id, required this.name, required this.nameKey,
    required this.startTime, required this.endTime,
    required this.suwayasCount, required this.colorValue,
  });

  Duration get totalDuration => endTime.difference(startTime);
}

class NightPart {
  final String id;
  final String nameKey;
  final DateTime startTime;
  final DateTime endTime;

  NightPart({required this.id, required this.nameKey, required this.startTime, required this.endTime});
}

class IbadatTimings {
  final DateTime fajr, sunrise, dhuhr, asr, maghrib, isha, nextFajr;
  final List<NightPart> nightParts;

  IbadatTimings({
    required this.fajr, required this.sunrise, required this.dhuhr, 
    required this.asr, required this.maghrib, required this.isha, 
    required this.nextFajr, required this.nightParts,
  });
}

class SuwayaDay {
  final IbadatTimings ibadatTimings;
  final List<AstroPeriod> periods;

  SuwayaDay({required this.ibadatTimings, required this.periods});
}

class AstroState {
  final DateTime virtualTime;
  final List<AstroPeriod> periods;
  final AstroPeriod currentPeriod;
  final int currentSuwaya;
  final Duration elapsedVirtualTime;
  final double suwayaProgress;
  final double timeSpeedMultiplier; 
  final IbadatTimings ibadatTimings;
  final String currentFormattedVirtualTime; 

  AstroState({
    required this.virtualTime, required this.periods, required this.currentPeriod,
    required this.currentSuwaya, required this.elapsedVirtualTime,
    required this.suwayaProgress, required this.timeSpeedMultiplier,
    required this.ibadatTimings, required this.currentFormattedVirtualTime,
  });

  String toVirtualTime(DateTime targetTime) {
    if (periods.isEmpty) return "00:00";
    double totalVirtualMinutes = 0.0;

    for (var p in periods) {
      if (targetTime.isAfter(p.endTime) || targetTime.isAtSameMomentAs(p.endTime)) {
        totalVirtualMinutes += p.suwayasCount * 30.0;
      } else if ((targetTime.isAfter(p.startTime) || targetTime.isAtSameMomentAs(p.startTime)) && targetTime.isBefore(p.endTime)) {
        final totalMicro = p.endTime.difference(p.startTime).inMicroseconds;
        final elapsedMicro = targetTime.difference(p.startTime).inMicroseconds;
        final progress = totalMicro > 0 ? (elapsedMicro / totalMicro) : 0.0;
        totalVirtualMinutes += progress * (p.suwayasCount * 30.0);
        break;
      }
    }
    int totalMins = totalVirtualMinutes.round();
    int h = totalMins ~/ 60;
    int m = totalMins % 60;
    if (h == 24 && m == 0) h = 0;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

enum CalculationMethodType { muslimWorldLeague, egyptian, karachi, ummAlQura, dubai, northAmerica, kuwait, qatar, singapore, tehran, turkey, custom }
enum MadhabType { hanafi, shafi }
enum HighLatitudeRuleType { middleOfTheNight, seventhOfTheNight, twilightAngle }
enum PrayerKey { fajr, sunrise, dhuhr, asr, maghrib, isha }

extension AstroStringParsers on String {
  String get _normalized => replaceAll('_', '').toLowerCase();

  CalculationMethodType toCalculationMethod() => CalculationMethodType.values.firstWhere(
    (e) => e.name.toLowerCase() == _normalized, 
    orElse: () => CalculationMethodType.muslimWorldLeague
  );
  
  MadhabType toMadhab() => MadhabType.values.firstWhere(
    (e) => e.name.toLowerCase() == _normalized, 
    orElse: () => MadhabType.shafi
  );
  
  HighLatitudeRuleType toHighLatRule() => HighLatitudeRuleType.values.firstWhere(
    (e) => e.name.toLowerCase() == _normalized, 
    orElse: () => HighLatitudeRuleType.middleOfTheNight
  );
}

// 🌟 تعديل النصوص الصلبة إلى لغة محايدة (الإنجليزية)
extension AstroPeriodNaming on AstroPeriod {
  String get longName {
    switch (id) {
      case 1: return 'Fajr'; case 2: return 'Duha'; case 3: return 'Dhuhr';
      case 4: return 'Asr'; case 5: return 'Maghrib';
      case 6: return 'Middle Third'; case 7: return 'Last Third';
      default: return 'Period $id';
    }
  }
  String get shortName => longName; 
}

extension AstroMapParsers on Map<String, int> {
  Map<PrayerKey, int> toPrayerKeyMap() {
    final map = <PrayerKey, int>{};
    forEach((key, value) {
      switch (key.toLowerCase()) {
        case '1': 
        case 'fajr': map[PrayerKey.fajr] = value; break;
        case 'sunrise': map[PrayerKey.sunrise] = value; break;
        case '3': 
        case 'dhuhr': map[PrayerKey.dhuhr] = value; break;
        case '4': 
        case 'asr': map[PrayerKey.asr] = value; break;
        case '5': 
        case 'maghrib': map[PrayerKey.maghrib] = value; break;
        case 'isha': map[PrayerKey.isha] = value; break;
      }
    });
    return map;
  }
}