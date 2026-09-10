import '../models/astro_models.dart';
import '../calculators/prayer_calculator.dart';

class SuwayaDistributor {
  static List<int> distribute48Suwayas(List<int> durationsInSeconds) {
    final int totalDaySeconds = durationsInSeconds.fold(0, (a, b) => a + b);
    if (totalDaySeconds == 0) return List.generate(7, (i) => i == 3 ? 6 : 7);
    const int targetSuwayas = 48;
    List<int> baseAllocations = List.filled(7, 0);
    List<double> remainders = List.filled(7, 0.0);
    int allocatedCount = 0;

    for (int i = 0; i < 7; i++) {
      double exactShare = (durationsInSeconds[i] / totalDaySeconds) * targetSuwayas;
      if (exactShare < 1.0) {
        baseAllocations[i] = 1; remainders[i] = 0.0; 
      } else {
        baseAllocations[i] = exactShare.floor(); remainders[i] = exactShare - baseAllocations[i];
      }
      allocatedCount += baseAllocations[i];
    }

    int remainingToDistribute = targetSuwayas - allocatedCount;
    if (remainingToDistribute > 0) {
      List<int> indices = List.generate(7, (i) => i)..sort((a, b) => remainders[b].compareTo(remainders[a]));
      for (int i = 0; i < remainingToDistribute; i++) { baseAllocations[indices[i]] += 1; }
    } else if (remainingToDistribute < 0) {
      int excess = -remainingToDistribute;
      while (excess > 0) {
        int maxIdx = -1, maxVal = -1;
        for (int i = 0; i < 7; i++) {
          if (baseAllocations[i] > 1 && baseAllocations[i] > maxVal) { maxVal = baseAllocations[i]; maxIdx = i; }
        }
        if (maxIdx != -1) { baseAllocations[maxIdx]--; excess--; } else { break; }
      }
    }
    return baseAllocations;
  }

  static List<int> calculateAnnualDistribution(double lat, double lng, CalculationMethodType methodType, MadhabType madhabType, HighLatitudeRuleType highLatRuleType, double customFajr, double customIsha, Duration cityOffset, {Map<PrayerKey, int>? manualOffsets}) {
    List<int> totalDurations = List.filled(7, 0);
    final int year = DateTime.now().year;
    final List<int> sampleDays = [1, 6, 11, 16, 21, 26]; 
    
    for (int month = 1; month <= 12; month++) {
      for (int day in sampleDays) {
        final date = DateTime(year, month, day);
        final ibadat = PrayerCalculator.getIbadatTimings(lat, lng, date, methodType, madhabType, highLatRuleType, customFajr, customIsha, cityOffset, manualOffsets: manualOffsets);
        
        final midFajr = ibadat.fajr.add(Duration(microseconds: ibadat.dhuhr.difference(ibadat.fajr).inMicroseconds ~/ 2));
        final nightMicro = ibadat.nextFajr.difference(ibadat.maghrib).inMicroseconds;
        final nightThird = Duration(microseconds: nightMicro ~/ 3);
        final firstThirdEnd = ibadat.maghrib.add(nightThird);
        final secondThirdEnd = firstThirdEnd.add(nightThird);

        totalDurations[0] += midFajr.difference(ibadat.fajr).inSeconds;
        totalDurations[1] += ibadat.dhuhr.difference(midFajr).inSeconds;
        totalDurations[2] += ibadat.asr.difference(ibadat.dhuhr).inSeconds;
        totalDurations[3] += ibadat.maghrib.difference(ibadat.asr).inSeconds;
        totalDurations[4] += firstThirdEnd.difference(ibadat.maghrib).inSeconds;
        totalDurations[5] += secondThirdEnd.difference(firstThirdEnd).inSeconds;
        totalDurations[6] += ibadat.nextFajr.difference(secondThirdEnd).inSeconds;
      }
    }
    return distribute48Suwayas(totalDurations.map((d) => d ~/ 72).toList());
  }
}