import 'package:adhan/adhan.dart';
import '../models/astro_models.dart';
import 'night_division.dart';

class PrayerCalculator {
  static CalculationParameters _getParams(CalculationMethodType methodType, MadhabType madhabType, HighLatitudeRuleType highLatRuleType, double customFajr, double customIsha) {
    CalculationParameters params;
    if (methodType == CalculationMethodType.custom) {
      params = CalculationMethod.other.getParameters();
      params.fajrAngle = customFajr;
      params.ishaAngle = customIsha;
    } else {
      switch (methodType) {
        case CalculationMethodType.egyptian: params = CalculationMethod.egyptian.getParameters(); break;
        case CalculationMethodType.ummAlQura: params = CalculationMethod.umm_al_qura.getParameters(); break;
        case CalculationMethodType.karachi: params = CalculationMethod.karachi.getParameters(); break;
        default: params = CalculationMethod.muslim_world_league.getParameters(); break;
      }
    }
    
    params.madhab = (madhabType == MadhabType.hanafi) ? Madhab.hanafi : Madhab.shafi;
    
    switch (highLatRuleType) {
      case HighLatitudeRuleType.seventhOfTheNight: params.highLatitudeRule = HighLatitudeRule.seventh_of_the_night; break;
      case HighLatitudeRuleType.twilightAngle: params.highLatitudeRule = HighLatitudeRule.twilight_angle; break;
      case HighLatitudeRuleType.middleOfTheNight: params.highLatitudeRule = HighLatitudeRule.middle_of_the_night; break;
    }
    return params;
  }

  static IbadatTimings getIbadatTimings(double lat, double lng, DateTime date, CalculationMethodType methodType, MadhabType madhabType, HighLatitudeRuleType highLatRuleType, double customFajr, double customIsha, Duration cityOffset, {Map<PrayerKey, int>? manualOffsets}) {
    final coordinates = Coordinates(lat, lng);
    final params = _getParams(methodType, madhabType, highLatRuleType, customFajr, customIsha);
    final today = PrayerTimes(coordinates, DateComponents.from(date), params);
    final tomorrow = PrayerTimes(coordinates, DateComponents.from(date.add(const Duration(days: 1))), params);

    DateTime applyOffset(DateTime time, PrayerKey key) {
      if (manualOffsets != null && manualOffsets.containsKey(key)) return time.add(Duration(minutes: manualOffsets[key]!));
      return time;
    }

    final fajr = applyOffset(today.fajr.toUtc().add(cityOffset), PrayerKey.fajr);
    final sunrise = applyOffset(today.sunrise.toUtc().add(cityOffset), PrayerKey.sunrise);
    final dhuhr = applyOffset(today.dhuhr.toUtc().add(cityOffset), PrayerKey.dhuhr);
    final asr = applyOffset(today.asr.toUtc().add(cityOffset), PrayerKey.asr);
    final maghrib = applyOffset(today.maghrib.toUtc().add(cityOffset), PrayerKey.maghrib);
    final isha = applyOffset(today.isha.toUtc().add(cityOffset), PrayerKey.isha);
    final nextFajr = applyOffset(tomorrow.fajr.toUtc().add(cityOffset), PrayerKey.fajr);

    return IbadatTimings(
      fajr: fajr, sunrise: sunrise, dhuhr: dhuhr, asr: asr, 
      maghrib: maghrib, isha: isha, nextFajr: nextFajr, 
      nightParts: NightDivision.calculateNightParts(maghrib, nextFajr),
    );
  }
}