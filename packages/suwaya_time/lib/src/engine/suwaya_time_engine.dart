import '../models/astro_models.dart';
import '../calculators/prayer_calculator.dart';
import '../generators/period_generator.dart';
import '../generators/suwaya_distributor.dart';

class SuwayaTimeEngine {
  
  static SuwayaDay generateDay(
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
    final ibadat = PrayerCalculator.getIbadatTimings(
      lat,
      lng,
      date,
      methodType,
      madhabType,
      highLatRuleType,
      customFajr,
      customIsha,
      cityOffset,
      nextDayCityOffset: nextDayCityOffset,
      manualOffsets: manualOffsets,
    );

    final anchors = PrayerCalculator.getCycleAnchors(
      lat,
      lng,
      date,
      methodType,
      madhabType,
      highLatRuleType,
      customFajr,
      customIsha,
      cityOffset,
      nextDayCityOffset: nextDayCityOffset,
      manualOffsets: manualOffsets,
    );

    final distribution = SuwayaDistributor.getDistributionForMadhab(madhabType);
    final periods = PeriodGenerator.generatePeriods(anchors, distribution);

    return SuwayaDay(
      ibadatTimings: ibadat,
      cycleAnchors: anchors,
      periods: periods,
    );
  }

  static AstroState calculateCurrentState(SuwayaDay day, DateTime now) {
    if (day.periods.isEmpty) return getFallbackState(now);
    
    AstroPeriod currentPeriod;
    try {
      // 🌟 الفترات تُعامل كنطاق [start, end)
      currentPeriod = day.periods.firstWhere((p) => 
          (now.isAfter(p.startTime) || now.isAtSameMomentAs(p.startTime)) && now.isBefore(p.endTime));
    } catch (_) {
      currentPeriod = now.isBefore(day.periods.first.startTime) ? day.periods.first : day.periods.last;
    }

    final totalMicroseconds = currentPeriod.totalDuration.inMicroseconds;
    if (totalMicroseconds <= 0) return getFallbackState(now);
    
    int sCount = currentPeriod.suwayasCount > 0 ? currentPeriod.suwayasCount : 1;
    final suwayaDurationMicroseconds = totalMicroseconds / sCount;
    
    int elapsedMicroseconds = now.difference(currentPeriod.startTime).inMicroseconds;
    if (elapsedMicroseconds < 0) elapsedMicroseconds = 0; 
    
    // 🌟 حساب رقم السويعة المحلي داخل الفترة الحالية
    int currentLocalSuwaya = (elapsedMicroseconds / suwayaDurationMicroseconds).floor() + 1;
    currentLocalSuwaya = currentLocalSuwaya.clamp(1, sCount); 
    
    // 🌟 حساب نسبة التقدم بدقة عالية جداً (0.0 إلى 0.9999) لتحريك المؤشر بسلاسة
    double progress = (elapsedMicroseconds % suwayaDurationMicroseconds) / suwayaDurationMicroseconds;
    progress = progress.clamp(0.0, 0.999999);
    
    // 🌟 حساب سرعة السويعة مقابل الزمن المدني
    final speedMultiplier = 3600 / (suwayaDurationMicroseconds / 1000000);

    // 🌟 تحديد هل نحن في نطاق الليل أم النهار وحساب رقم السويعة (1 إلى 12)
    SuwayaPhase phase;
    int phaseSlotNumber = 0;
    
    final nightKeys = [PeriodKey.nightMaghribIsha, PeriodKey.nightIshaMidnight, PeriodKey.nightMidnightFajr, PeriodKey.nightFajrSunrise];
    
    if (nightKeys.contains(currentPeriod.periodKey)) {
       phase = SuwayaPhase.night;
       for (var p in day.periods) {
           if (p.periodKey == currentPeriod.periodKey) break;
           phaseSlotNumber += p.suwayasCount;
       }
    } else {
       phase = SuwayaPhase.day;
       for (var p in day.periods) {
           if (!nightKeys.contains(p.periodKey)) {
               if (p.periodKey == currentPeriod.periodKey) break;
               phaseSlotNumber += p.suwayasCount;
           }
       }
    }
    phaseSlotNumber += currentLocalSuwaya;

    // 🌟 توليد كائن التوقيت الدقيق الجديد
    final clockTime = SuwayaClockTime(
       phase: phase,
       phaseSlotNumber: phaseSlotNumber,
       periodKey: currentPeriod.periodKey,
       periodLocalSlotNumber: currentLocalSuwaya,
       slotProgress: progress,
       cycleStartDate: day.cycleAnchors.cycleStartMaghrib,
       instant: now,
    );

    return AstroState(
      virtualTime: now, 
      periods: day.periods, 
      currentPeriod: currentPeriod, 
      currentSuwayaTime: clockTime, 
      timeSpeedMultiplier: speedMultiplier, 
      ibadatTimings: day.ibadatTimings, 
      cycleAnchors: day.cycleAnchors,
    );
  }

  static AstroState getFallbackState(DateTime now) {
    final fallbackIbadat = IbadatTimings(fajr: now, sunrise: now, dhuhr: now, asr: now, maghrib: now, isha: now, nextFajr: now.add(const Duration(days: 1)), nightParts: const []);
    final fallbackAnchors = SuwayaCycleAnchors(cycleStartMaghrib: now, cycleIsha: now, sharIMidnight: now, cycleFajr: now, cycleSunrise: now, cycleDhuhr: now, cycleAsr: now, cycleEndMaghrib: now.add(const Duration(days: 1)));
    final fallbackPeriod = AstroPeriod(id: 1, periodKey: PeriodKey.nightMaghribIsha, nameKey: 'period_maghrib', colorValue: 0xFFD4AF37, startTime: now, endTime: now.add(const Duration(hours: 1)), suwayasCount: 1);
    final fallbackTime = SuwayaClockTime(phase: SuwayaPhase.night, phaseSlotNumber: 1, periodKey: PeriodKey.nightMaghribIsha, periodLocalSlotNumber: 1, slotProgress: 0.0, cycleStartDate: now, instant: now);
    
    return AstroState(
      virtualTime: now, periods: [fallbackPeriod], currentPeriod: fallbackPeriod, 
      currentSuwayaTime: fallbackTime, timeSpeedMultiplier: 1.0, 
      ibadatTimings: fallbackIbadat, cycleAnchors: fallbackAnchors
    );
  }
}