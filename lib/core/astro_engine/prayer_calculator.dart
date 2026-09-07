import 'package:adhan/adhan.dart';
import 'astro_models.dart';
import 'night_division.dart';

class PrayerCalculator {
  static CalculationParameters _getParams(
    CalculationMethodType methodType, MadhabType madhabType, 
    HighLatitudeRuleType highLatRuleType, double customFajr, double customIsha,
  ) {
    CalculationParameters params;
    
    if (methodType == CalculationMethodType.custom) {
      params = CalculationMethod.other.getParameters();
      params.fajrAngle = customFajr;
      params.ishaAngle = customIsha;
    } else {
      switch (methodType) {
        case CalculationMethodType.egyptian: params = CalculationMethod.egyptian.getParameters(); break;
        case CalculationMethodType.umm_al_qura: params = CalculationMethod.umm_al_qura.getParameters(); break;
        case CalculationMethodType.muslim_world_league: params = CalculationMethod.muslim_world_league.getParameters(); break;
        case CalculationMethodType.karachi: params = CalculationMethod.karachi.getParameters(); break;
        case CalculationMethodType.north_america: params = CalculationMethod.north_america.getParameters(); break;
        case CalculationMethodType.dubai: params = CalculationMethod.dubai.getParameters(); break;
        case CalculationMethodType.qatar: params = CalculationMethod.qatar.getParameters(); break;
        case CalculationMethodType.kuwait: params = CalculationMethod.kuwait.getParameters(); break;
        case CalculationMethodType.turkey: params = CalculationMethod.turkey.getParameters(); break;
        case CalculationMethodType.tehran: params = CalculationMethod.tehran.getParameters(); break;
        case CalculationMethodType.singapore: params = CalculationMethod.singapore.getParameters(); break;
        default: params = CalculationMethod.muslim_world_league.getParameters(); break;
      }
    }

    params.madhab = (madhabType == MadhabType.hanafi) ? Madhab.hanafi : Madhab.shafi;
    
    switch (highLatRuleType) {
      case HighLatitudeRuleType.seventh_of_the_night: params.highLatitudeRule = HighLatitudeRule.seventh_of_the_night; break;
      case HighLatitudeRuleType.twilight_angle: params.highLatitudeRule = HighLatitudeRule.twilight_angle; break;
      case HighLatitudeRuleType.middle_of_the_night: params.highLatitudeRule = HighLatitudeRule.middle_of_the_night; break;
    }
    return params;
  }

  static IbadatTimings getIbadatTimings(
    double lat, double lng, DateTime date, 
    CalculationMethodType methodType, MadhabType madhabType, 
    HighLatitudeRuleType highLatRuleType, double customFajr, double customIsha, 
    Duration cityOffset, {Map<PrayerKey, int>? manualOffsets}
  ) {
    final coordinates = Coordinates(lat, lng);
    final params = _getParams(methodType, madhabType, highLatRuleType, customFajr, customIsha);
    
    final today = PrayerTimes(coordinates, DateComponents.from(date), params);
    final tomorrow = PrayerTimes(coordinates, DateComponents.from(date.add(const Duration(days: 1))), params);

    DateTime applyOffset(DateTime time, PrayerKey key) {
      if (manualOffsets != null && manualOffsets.containsKey(key)) {
        return time.add(Duration(minutes: manualOffsets[key]!));
      }
      return time;
    }

    final fajr = applyOffset(today.fajr.toUtc().add(cityOffset), PrayerKey.fajr);
    final sunrise = applyOffset(today.sunrise.toUtc().add(cityOffset), PrayerKey.sunrise);
    final dhuhr = applyOffset(today.dhuhr.toUtc().add(cityOffset), PrayerKey.dhuhr);
    final asr = applyOffset(today.asr.toUtc().add(cityOffset), PrayerKey.asr);
    final maghrib = applyOffset(today.maghrib.toUtc().add(cityOffset), PrayerKey.maghrib);
    final isha = applyOffset(today.isha.toUtc().add(cityOffset), PrayerKey.isha);
    final nextFajr = applyOffset(tomorrow.fajr.toUtc().add(cityOffset), PrayerKey.fajr);

    final nightParts = NightDivision.calculateNightParts(maghrib, nextFajr);

    return IbadatTimings(
      fajr: fajr, sunrise: sunrise, dhuhr: dhuhr, asr: asr, 
      maghrib: maghrib, isha: isha, nextFajr: nextFajr, nightParts: nightParts,
    );
  }
}