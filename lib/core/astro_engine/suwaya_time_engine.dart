// 🌟 Pure Dart Engine
import 'dart:isolate';
import 'astro_models.dart';
import 'astro_calculators.dart';

class SuwayaTimeEngine {
  
  static SuwayaDay generateDay(
    double lat, double lng, DateTime date, 
    CalculationMethodType methodType, MadhabType madhabType, 
    HighLatitudeRuleType highLatRuleType, double customFajr, double customIsha, 
    Duration cityOffset, List<int> cachedDistribution, {Map<PrayerKey, int>? manualOffsets} // 🌟 نمرر التوزيع الجاهز بدلاً من حسابه هنا
  ) {
    final ibadat = PrayerCalculator.getIbadatTimings(
      lat, lng, date, methodType, madhabType, highLatRuleType, 
      customFajr, customIsha, cityOffset, manualOffsets: manualOffsets
    );
    
    final periods = PeriodGenerator.generatePeriods(ibadat, cachedDistribution);
    return SuwayaDay(ibadatTimings: ibadat, periods: periods);
  }

  static Future<List<int>> calculateAnnualSuwayaDistributionAsync(
    double lat, double lng, CalculationMethodType methodType, MadhabType madhabType, 
    HighLatitudeRuleType highLatRuleType, double customFajr, double customIsha, 
    Duration cityOffset, {Map<PrayerKey, int>? manualOffsets}
  ) async {
    return Isolate.run(() {
      return SuwayaDistributor.calculateAnnualDistribution(
        lat, lng, methodType, madhabType, highLatRuleType, 
        customFajr, customIsha, cityOffset, manualOffsets: manualOffsets
      );
    });
  }

  static AstroState calculateCurrentState(SuwayaDay day, DateTime now) {
    if (day.periods.isEmpty) return getFallbackState(now);
    
    AstroPeriod currentPeriod;
    try {
      currentPeriod = day.periods.firstWhere((p) => (now.isAfter(p.startTime) || now.isAtSameMomentAs(p.startTime)) && now.isBefore(p.endTime));
    } catch (_) {
      currentPeriod = now.isBefore(day.periods.first.startTime) ? day.periods.first : day.periods.last;
    }

    final totalMicroseconds = currentPeriod.totalDuration.inMicroseconds;
    if (totalMicroseconds <= 0) return getFallbackState(now);
    
    int sCount = currentPeriod.suwayasCount > 0 ? currentPeriod.suwayasCount : 7;
    final suwayaDurationMicroseconds = totalMicroseconds / sCount;
    
    int elapsedMicroseconds = now.difference(currentPeriod.startTime).inMicroseconds;
    if (elapsedMicroseconds < 0) elapsedMicroseconds = 0; 
    
    int currentSuwaya = (elapsedMicroseconds / suwayaDurationMicroseconds).floor() + 1;
    currentSuwaya = currentSuwaya.clamp(1, sCount); 
    
    final progress = ((elapsedMicroseconds % suwayaDurationMicroseconds) / suwayaDurationMicroseconds).clamp(0.0, 1.0);
    final virtualElapsedSeconds = (progress * 1800).floor();
    final speedMultiplier = 1800 / (suwayaDurationMicroseconds / 1000000);

    int globalSuwayaIndex = 0;
    for (var p in day.periods) {
      if (p.id == currentPeriod.id) {
        globalSuwayaIndex += (currentSuwaya - 1);
        break;
      } else {
        globalSuwayaIndex += p.suwayasCount;
      }
    }
    String formattedVirtualTime = '${globalSuwayaIndex.toString().padLeft(2, '0')}:${((virtualElapsedSeconds ~/ 60) % 60).toString().padLeft(2, '0')}';

    return AstroState(
      virtualTime: now, periods: day.periods, currentPeriod: currentPeriod, 
      currentSuwaya: currentSuwaya, elapsedVirtualTime: Duration(seconds: virtualElapsedSeconds), 
      suwayaProgress: progress, timeSpeedMultiplier: speedMultiplier, 
      ibadatTimings: day.ibadatTimings, currentFormattedVirtualTime: formattedVirtualTime,
    );
  }

  static AstroState getFallbackState(DateTime now) {
    final fallbackIbadat = IbadatTimings(fajr: now, sunrise: now, dhuhr: now, asr: now, maghrib: now, isha: now, nextFajr: now.add(const Duration(days: 1)), nightParts: []);
    final fallbackPeriod = AstroPeriod(id: 1, name: 'جاري الحساب', nameKey: 'period_fajr', colorValue: 0xFFD4AF37, startTime: now, endTime: now.add(const Duration(hours: 1)), suwayasCount: 7);
    return AstroState(
      virtualTime: now, periods: [fallbackPeriod], currentPeriod: fallbackPeriod, 
      currentSuwaya: 1, elapsedVirtualTime: Duration.zero, suwayaProgress: 0, 
      timeSpeedMultiplier: 1.0, ibadatTimings: fallbackIbadat, currentFormattedVirtualTime: "00:00"
    );
  }
}