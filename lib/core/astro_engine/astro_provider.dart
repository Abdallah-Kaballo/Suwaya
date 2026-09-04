import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz; // 🌟 مكتبة المناطق الزمنية

import '../../features/settings/settings_provider.dart';
import 'astro_engine.dart';
import 'astro_models.dart';

class AstroState {
  final DateTime virtualTime;
  final List<AstroPeriod> periods;
  final AstroPeriod currentPeriod;
  final int currentSuwaya;
  final Duration elapsedVirtualTime;
  final double suwayaProgress;
  final double timeSpeedMultiplier; 
  final IbadatTimings ibadatTimings;

  AstroState({
    required this.virtualTime,
    required this.periods,
    required this.currentPeriod,
    required this.currentSuwaya,
    required this.elapsedVirtualTime,
    required this.suwayaProgress,
    required this.timeSpeedMultiplier,
    required this.ibadatTimings,
  });
  
  String get currentFormattedVirtualTime {
    if (periods.isEmpty) return "00:00";
    
    int globalSuwayaIndex = 0;
    
    for (var p in periods) {
      if (p.id == currentPeriod.id) {
        globalSuwayaIndex += (currentSuwaya - 1);
        break;
      } else {
        globalSuwayaIndex += p.suwayasCount;
      }
    }
    
    int m = elapsedVirtualTime.inMinutes % 60; 
    
    return '${globalSuwayaIndex.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String toVirtualTime(DateTime targetTime) {
    if (periods.isEmpty) return "00:00";
    
    double totalVirtualMinutes = 0.0;

    for (var p in periods) {
      if (targetTime.isAfter(p.endTime) || targetTime.isAtSameMomentAs(p.endTime)) {
        totalVirtualMinutes += p.suwayasCount * 30.0;
      } 
      else if (targetTime.isAfter(p.startTime) && targetTime.isBefore(p.endTime)) {
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

class AstroNotifier extends Notifier<AstroState> {
  Timer? _timer;

  // ==========================================================
  // 🌟 محرك وقت المدينة الذكي (بدقة 100% مع التوقيت الصيفي)
  // ==========================================================
  
  Duration _getUtcOffsetForLocation(dynamic loc) {
    if (loc == null || loc.isAutoLocation == true || loc.timezone == null) {
      return DateTime.now().timeZoneOffset;
    }
    try {
      final location = tz.getLocation(loc.timezone!);
      final nowInTarget = tz.TZDateTime.now(location);
      return nowInTarget.timeZoneOffset;
    } catch (e) {
      return DateTime.now().timeZoneOffset;
    }
  }

  DateTime _getCityNow(dynamic loc) {
    if (loc != null && loc.isAutoLocation == false && loc.timezone != null) {
      try {
        final location = tz.getLocation(loc.timezone!);
        final nowInTarget = tz.TZDateTime.now(location);
        // تجميد الوقت ليصبح وقت حائط (Wall Clock) ثابت لا يتأثر بمكان الهاتف أبدًا
        return DateTime.utc(
          nowInTarget.year, nowInTarget.month, nowInTarget.day, 
          nowInTarget.hour, nowInTarget.minute, nowInTarget.second
        );
      } catch (e) {
      // تجاهل الخطأ في حالة عدم العثور على المنطقة الزمنية، والنزول للسطر التالي لاستخدام الوقت المحلي
      debugPrint('Timezone fallback triggered: $e');
      }
    }
    // 🌟 الحل الجذري: تجميد وقت الهاتف المحلي أيضاً كـ UTC لمنع تداخل لغة Dart
    final now = DateTime.now();
    return DateTime.utc(now.year, now.month, now.day, now.hour, now.minute, now.second);
  }

  @override
  AstroState build() {
    // 🌟 الحل الجذري: مراقبة "البصمة الفلكية" فقط!
    // هذا يمنع المحرك من إعادة الحساب (وإلغاء المنبهات) عند تغيير إعدادات بصرية مثل (فلكي/مدني)
    ref.watch(settingsProvider.select((s) {
      String fingerprint = '${s.activeLocation?.latitude}_${s.activeLocation?.longitude}_'
          '${s.calculationMethod}_${s.madhab}_${s.highLatitudeRule}_'
          '${s.customFajrAngle}_${s.customIshaAngle}';
      // نضيف التعديلات اليدوية للبصمة لكي يتحدث المحرك فقط إذا تم تعديل وقت صلاة
      for (var c in s.periodConfigs) {
        fingerprint += '_${c.periodId}:${c.manualOffsetMinutes}';
      }
      return fingerprint;
    }));

    // 🌟 الآن نقرأ الإعدادات بهدوء (Read-only) دون أن نربط مصير المحرك بكل تغيير فيها
    final settings = ref.read(settingsProvider);
    final loc = settings.activeLocation;
    
    // 🌟 1. استخراج فارق توقيت المدينة بدقة
    final cityOffset = _getUtcOffsetForLocation(loc);
    
    try {
      final lat = loc?.latitude ?? 21.4225; 
      final lng = loc?.longitude ?? 39.8262;
      
      ref.onDispose(() => _timer?.cancel());

      // 🌟 2. استخراج الوقت الفعلي للمدينة
      DateTime cityNow = _getCityNow(loc);
      DateTime dateToGenerate = cityNow;
      
      final manualOffsetsMap = {
        for (var c in settings.periodConfigs)
          if (c.periodId != null) c.periodId!: c.manualOffsetMinutes
      };

      // 🌟 3. الحسابات الفلكية
      IbadatTimings ibadat = AstroEngine.getIbadatTimings(
        lat, lng, dateToGenerate, settings.calculationMethod, settings.madhab, 
        settings.highLatitudeRule, settings.customFajrAngle, settings.customIshaAngle,
        cityOffset, 
        manualOffsets: manualOffsetsMap 
      );

      if (cityNow.isBefore(ibadat.fajr)) {
        dateToGenerate = dateToGenerate.subtract(const Duration(days: 1));
        ibadat = AstroEngine.getIbadatTimings(
          lat, lng, dateToGenerate, settings.calculationMethod, settings.madhab, 
          settings.highLatitudeRule, settings.customFajrAngle, settings.customIshaAngle,
          cityOffset, 
          manualOffsets: manualOffsetsMap 
        );
      } else if (cityNow.isAfter(ibadat.nextFajr) || cityNow.isAtSameMomentAs(ibadat.nextFajr)) {
        dateToGenerate = dateToGenerate.add(const Duration(days: 1));
        ibadat = AstroEngine.getIbadatTimings(
          lat, lng, dateToGenerate, settings.calculationMethod, settings.madhab, 
          settings.highLatitudeRule, settings.customFajrAngle, settings.customIshaAngle,
          cityOffset, 
          manualOffsets: manualOffsetsMap 
        );
      }

      // 🌟 التوزيع السنوي
      final List<int> distribution = AstroEngine.calculateAnnualSuwayaDistribution(
        lat, lng, settings.calculationMethod, settings.madhab, 
        settings.highLatitudeRule, settings.customFajrAngle, settings.customIshaAngle,
        cityOffset, manualOffsets: manualOffsetsMap 
      );

      final periods = AstroEngine.generatePeriodsForDay(
        lat, lng, dateToGenerate, settings.calculationMethod, settings.madhab, 
        settings.highLatitudeRule, settings.customFajrAngle, settings.customIshaAngle, 
        distribution, cityOffset, 
        manualOffsets: manualOffsetsMap, 
      );

      _startTicker(periods, ibadat, loc);
      return _calculateState(cityNow, periods, ibadat);
      
    } catch (e) {
      debugPrint('AstroEngine Error: $e');
      final fallbackIbadat = IbadatTimings(fajr: DateTime.now(), sunrise: DateTime.now(), dhuhr: DateTime.now(), asr: DateTime.now(), maghrib: DateTime.now(), isha: DateTime.now(), nextFajr: DateTime.now().add(const Duration(days: 1)), nightParts: []);
      return _getFallbackState(_getCityNow(loc), [], fallbackIbadat);
    }
  }

  void _startTicker(List<AstroPeriod> periods, IbadatTimings ibadat, dynamic loc) {
    _timer?.cancel();
    if (periods.isEmpty) return;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final tickNow = _getCityNow(loc); // 🌟 الـ Ticker يعمل بتوقيت المدينة المجمّد
      if (tickNow.isAfter(ibadat.nextFajr) || tickNow.isAtSameMomentAs(ibadat.nextFajr)) {
        _timer?.cancel();
        Future.microtask(() => ref.invalidateSelf());
        return;
      }
      state = _calculateState(tickNow, periods, ibadat);
    });
  }

  AstroState _calculateState(DateTime now, List<AstroPeriod> periods, IbadatTimings ibadat) {
    if (periods.isEmpty) return _getFallbackState(now, periods, ibadat);
    
    AstroPeriod currentPeriod;
    try {
      currentPeriod = periods.firstWhere((p) => (now.isAfter(p.startTime) || now.isAtSameMomentAs(p.startTime)) && now.isBefore(p.endTime));
    } catch (_) {
      currentPeriod = now.isBefore(periods.first.startTime) ? periods.first : periods.last;
    }

    final totalMicroseconds = currentPeriod.totalDuration.inMicroseconds;
    if (totalMicroseconds <= 0) return _getFallbackState(now, periods, ibadat);
    
    int sCount = currentPeriod.suwayasCount > 0 ? currentPeriod.suwayasCount : 7;
    final suwayaDurationMicroseconds = totalMicroseconds / sCount;
    
    int elapsedMicroseconds = now.difference(currentPeriod.startTime).inMicroseconds;
    if (elapsedMicroseconds < 0) elapsedMicroseconds = 0; 
    
    int currentSuwaya = (elapsedMicroseconds / suwayaDurationMicroseconds).floor() + 1;
    currentSuwaya = currentSuwaya.clamp(1, sCount); 
    
    final microsecondsInCurrent = elapsedMicroseconds % suwayaDurationMicroseconds;
    final progress = (microsecondsInCurrent / suwayaDurationMicroseconds).clamp(0.0, 1.0);
    
    const virtualSuwayaSeconds = 1800; 
    final virtualElapsedSeconds = (progress * virtualSuwayaSeconds).floor();

    final realSuwayaSeconds = suwayaDurationMicroseconds / 1000000;
    final speedMultiplier = virtualSuwayaSeconds / realSuwayaSeconds;

    return AstroState(
      virtualTime: now, 
      periods: periods, 
      currentPeriod: currentPeriod, 
      currentSuwaya: currentSuwaya, 
      elapsedVirtualTime: Duration(seconds: virtualElapsedSeconds), 
      suwayaProgress: progress, 
      timeSpeedMultiplier: speedMultiplier, 
      ibadatTimings: ibadat,
    );
  }

  AstroState _getFallbackState(DateTime now, List<AstroPeriod> periods, IbadatTimings ibadat) {
     return AstroState(virtualTime: now, periods: periods, currentPeriod: AstroPeriod(id: 1, name: 'جاري الحساب', nameKey: 'period_fajr', color: const Color(0xFFD4AF37), startTime: now, endTime: now.add(const Duration(hours: 1)), suwayasCount: 7), currentSuwaya: 1, elapsedVirtualTime: Duration.zero, suwayaProgress: 0, timeSpeedMultiplier: 1.0, ibadatTimings: ibadat);
  }

  void resetToRealTime() => ref.invalidateSelf();
}

final astroProvider = NotifierProvider<AstroNotifier, AstroState>(AstroNotifier.new);