// 🌟 Pure Dart Calculators
import 'package:adhan/adhan.dart';
import 'astro_models.dart';

class NightDivision {
  static List<NightPart> calculateNightParts(DateTime maghrib, DateTime nextFajr) {
    final nightMicro = nextFajr.difference(maghrib).inMicroseconds;
    final half = Duration(microseconds: nightMicro ~/ 2);
    final third = Duration(microseconds: nightMicro ~/ 3);
    final sixth = Duration(microseconds: nightMicro ~/ 6);

    final h1End = maghrib.add(half);
    final t1End = maghrib.add(third);
    final t2End = t1End.add(third);
    final s1End = maghrib.add(sixth);
    final s2End = s1End.add(sixth);
    final s3End = s2End.add(sixth);
    final s4End = s3End.add(sixth);
    final s5End = s4End.add(sixth);

    return [
      NightPart(id: 'half_1', nameKey: 'np_half_1', startTime: maghrib, endTime: h1End),
      NightPart(id: 'half_2', nameKey: 'np_half_2', startTime: h1End, endTime: nextFajr),
      NightPart(id: 'third_1', nameKey: 'np_third_1', startTime: maghrib, endTime: t1End),
      NightPart(id: 'third_2', nameKey: 'np_third_2', startTime: t1End, endTime: t2End),
      NightPart(id: 'third_3', nameKey: 'np_third_3', startTime: t2End, endTime: nextFajr),
      NightPart(id: 'sixth_1', nameKey: 'np_sixth_1', startTime: maghrib, endTime: s1End),
      NightPart(id: 'sixth_2', nameKey: 'np_sixth_2', startTime: s1End, endTime: s2End),
      NightPart(id: 'sixth_3', nameKey: 'np_sixth_3', startTime: s2End, endTime: s3End),
      NightPart(id: 'sixth_4', nameKey: 'np_sixth_4', startTime: s3End, endTime: s4End),
      NightPart(id: 'sixth_5', nameKey: 'np_sixth_5', startTime: s4End, endTime: s5End),
      NightPart(id: 'sixth_6', nameKey: 'np_sixth_6', startTime: s5End, endTime: nextFajr),
    ];
  }
}

class PeriodGenerator {
  static List<AstroPeriod> generatePeriods(IbadatTimings ibadat, List<int> distribution) {
    final mid = ibadat.fajr.add(Duration(microseconds: ibadat.dhuhr.difference(ibadat.fajr).inMicroseconds ~/ 2));
    final night = ibadat.nextFajr.difference(ibadat.maghrib);
    final t = Duration(microseconds: night.inMicroseconds ~/ 3);
    final firstEnd = ibadat.maghrib.add(t);
    final secondEnd = firstEnd.add(t);

    return [
      AstroPeriod(id: 1, name: 'الفجر', nameKey: 'period_fajr', startTime: ibadat.fajr, endTime: mid, suwayasCount: distribution[0], colorValue: 0xFF64B5F6),
      AstroPeriod(id: 2, name: 'الضحى', nameKey: 'period_duha', startTime: mid, endTime: ibadat.dhuhr, suwayasCount: distribution[1], colorValue: 0xFFFFF176),
      AstroPeriod(id: 3, name: 'الظهر', nameKey: 'period_dhuhr', startTime: ibadat.dhuhr, endTime: ibadat.asr, suwayasCount: distribution[2], colorValue: 0xFFFFCA28),
      AstroPeriod(id: 4, name: 'العصر', nameKey: 'period_asr', startTime: ibadat.asr, endTime: ibadat.maghrib, suwayasCount: distribution[3], colorValue: 0xFFFF9800),
      AstroPeriod(id: 5, name: 'المغرب', nameKey: 'period_maghrib', startTime: ibadat.maghrib, endTime: firstEnd, suwayasCount: distribution[4], colorValue: 0xFFE53935),
      AstroPeriod(id: 6, name: 'الثلث الأوسط', nameKey: 'period_second_third', startTime: firstEnd, endTime: secondEnd, suwayasCount: distribution[5], colorValue: 0xFF1A237E),
      AstroPeriod(id: 7, name: 'الثلث الأخير', nameKey: 'period_last_third', startTime: secondEnd, endTime: ibadat.nextFajr, suwayasCount: distribution[6], colorValue: 0xFF311B92),
    ];
  }
}

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
      for (int i = 0; i < remainingToDistribute; i++) {
        baseAllocations[indices[i]] += 1;
      }
    } else if (remainingToDistribute < 0) {
      int excess = -remainingToDistribute;
      while (excess > 0) {
        int maxIdx = -1, maxVal = -1;
        for (int i = 0; i < 7; i++) {
          if (baseAllocations[i] > 1 && baseAllocations[i] > maxVal) { maxVal = baseAllocations[i]; maxIdx = i; }
        }
        if (maxIdx != -1) { baseAllocations[maxIdx]--; excess--; } else {
          break;
        }
      }
    }
    return baseAllocations;
  }

  static List<int> calculateAnnualDistribution(double lat, double lng, CalculationMethodType methodType, MadhabType madhabType, HighLatitudeRuleType highLatRuleType, double customFajr, double customIsha, Duration cityOffset, {Map<PrayerKey, int>? manualOffsets}) {
    List<int> totalDurations = List.filled(7, 0);
    final int year = DateTime.now().year;
    final List<int> sampleDays = [1, 11, 21];
    
    for (int month = 1; month <= 12; month++) {
      for (int day in sampleDays) {
        final date = DateTime(year, month, day);
        final ibadat = PrayerCalculator.getIbadatTimings(lat, lng, date, methodType, madhabType, highLatRuleType, customFajr, customIsha, cityOffset, manualOffsets: manualOffsets);
        
        final midFajr = ibadat.fajr.add(Duration(microseconds: ibadat.dhuhr.difference(ibadat.fajr).inMicroseconds ~/ 2));
        final nightThird = Duration(microseconds: ibadat.nextFajr.difference(ibadat.maghrib).inMicroseconds ~/ 3);
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
    return distribute48Suwayas(totalDurations.map((d) => d ~/ 36).toList());
  }
}