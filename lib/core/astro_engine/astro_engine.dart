import 'dart:isolate';
import 'astro_models.dart';
import 'prayer_calculator.dart';
import 'suwaya_distribution.dart';
import 'period_generator.dart';

class AstroEngine {
  
  static IbadatTimings getIbadatTimings(
    double lat, double lng, DateTime date, 
    CalculationMethodType methodType, MadhabType madhabType, 
    HighLatitudeRuleType highLatRuleType, double customFajr, double customIsha, 
    Duration cityOffset, {Map<PrayerKey, int>? manualOffsets}
  ) {
    return PrayerCalculator.getIbadatTimings(
      lat, lng, date, methodType, madhabType, highLatRuleType, customFajr, customIsha, cityOffset, manualOffsets: manualOffsets
    );
  }

  static List<int> calculateAnnualSuwayaDistribution(
    double lat, double lng, 
    CalculationMethodType methodType, MadhabType madhabType, 
    HighLatitudeRuleType highLatRuleType, double customFajr, double customIsha, 
    Duration cityOffset, {Map<PrayerKey, int>? manualOffsets}
  ) {
    return SuwayaDistributor.calculateAnnualDistribution(
      lat, lng, methodType, madhabType, highLatRuleType, customFajr, customIsha, cityOffset, manualOffsets: manualOffsets
    );
  }

  static List<AstroPeriod> generatePeriodsForDay(
    double lat, double lng, DateTime date, 
    CalculationMethodType methodType, MadhabType madhabType, 
    HighLatitudeRuleType highLatRuleType, double customFajr, double customIsha, 
    List<int> distribution, Duration cityOffset, {Map<PrayerKey, int>? manualOffsets}
  ) {
    final ibadat = getIbadatTimings(
      lat, lng, date, methodType, madhabType, highLatRuleType, customFajr, customIsha, cityOffset, manualOffsets: manualOffsets
    );
    return PeriodGenerator.generatePeriods(ibadat, distribution);
  }

  static Future<List<int>> calculateAnnualSuwayaDistributionAsync(
    double lat, double lng, 
    CalculationMethodType methodType, MadhabType madhabType, 
    HighLatitudeRuleType highLatRuleType, double customFajr, double customIsha, 
    Duration cityOffset, {Map<PrayerKey, int>? manualOffsets}
  ) async {
    return Isolate.run(() {
      return calculateAnnualSuwayaDistribution(
        lat, lng, methodType, madhabType, highLatRuleType, 
        customFajr, customIsha, cityOffset, manualOffsets: manualOffsets
      );
    });
  }
}