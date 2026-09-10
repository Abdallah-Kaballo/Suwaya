import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:suwaya_time/suwaya_time.dart';

import '../../models/settings_model.dart';
import '../../features/settings/settings_provider.dart';

final virtualTimeNotifier = ValueNotifier<String>("00:00:00");
final Map<String, SuwayaDay> _dayCache = {};

class AstroNotifier extends Notifier<AstroState> {
  Timer? _timer;
  int _lastPeriodId = -1;
  int _lastSuwaya = -1;

  Duration _getUtcOffsetForLocation(SavedLocation? loc) {
    if (loc == null || loc.isAutoLocation == true || loc.timezone == null) return DateTime.now().timeZoneOffset;
    try {
      return tz.TZDateTime.now(tz.getLocation(loc.timezone!)).timeZoneOffset;
    } catch (_) {
      return DateTime.now().timeZoneOffset;
    }
  }

  DateTime _getCityNow(SavedLocation? loc) {
    if (loc != null && loc.isAutoLocation == false && loc.timezone != null) {
      try {
        final nowInTarget = tz.TZDateTime.now(tz.getLocation(loc.timezone!));
        return DateTime.utc(nowInTarget.year, nowInTarget.month, nowInTarget.day, nowInTarget.hour, nowInTarget.minute, nowInTarget.second);
      } catch (_) {}
    }
    final now = DateTime.now();
    return DateTime.utc(now.year, now.month, now.day, now.hour, now.minute, now.second);
  }

  @override
  AstroState build() {
    final fingerprint = ref.watch(settingsProvider.select((s) {
      String f = '${s.activeLocation?.latitude}_${s.activeLocation?.longitude}_${s.calculationMethod}_${s.madhab}_${s.highLatitudeRule}_${s.customFajrAngle}_${s.customIshaAngle}';
      for (var c in s.periodConfigs) {
        f += '_${c.periodId}:${c.manualOffsetMinutes}';
      }
      return f;
    }));

    final settings = ref.read(settingsProvider);
    final SavedLocation? loc = settings.activeLocation; 
    final cityOffset = _getUtcOffsetForLocation(loc);
    
    try {
      ref.onDispose(() => _timer?.cancel());
      DateTime cityNow = _getCityNow(loc);
      DateTime dateToGenerate = cityNow;
      
      final Map<PrayerKey, int> manualOffsetsMap = {};
      for (var c in settings.periodConfigs) {
        if (c.periodId != null) {
          final pKey = _parsePrayerKey(c.periodId);
          if (pKey != null) manualOffsetsMap[pKey] = c.manualOffsetMinutes;
        }
      }

      final methodEnum = settings.calculationMethod.toCalculationMethod();
      final madhabEnum = settings.madhab.toMadhab();
      final highLatEnum = settings.highLatitudeRule.toHighLatRule();

      SuwayaDay generatedDay;
      
      SuwayaDay getOrGenerateDay(DateTime date) {
        final String cacheKey = '${date.year}-${date.month}-${date.day}_$fingerprint';
        if (_dayCache.containsKey(cacheKey)) {
          return _dayCache[cacheKey]!;
        } else {
          // 🌟 تمرير التوزيع الموحد مباشرة
          final newDay = SuwayaTimeEngine.generateDay(
            loc?.latitude ?? 21.4225, loc?.longitude ?? 39.8262, date, 
            methodEnum, madhabEnum, highLatEnum, settings.customFajrAngle, settings.customIshaAngle, 
            cityOffset, SuwayaDistributor.universalDistribution, manualOffsets: manualOffsetsMap 
          );
          if (_dayCache.length > 3) _dayCache.clear();
          _dayCache[cacheKey] = newDay;
          return newDay;
        }
      }

      generatedDay = getOrGenerateDay(dateToGenerate);

      if (cityNow.isBefore(generatedDay.ibadatTimings.fajr)) {
        dateToGenerate = dateToGenerate.subtract(const Duration(days: 1));
        generatedDay = getOrGenerateDay(dateToGenerate);
      } else if (cityNow.isAfter(generatedDay.ibadatTimings.nextFajr) || cityNow.isAtSameMomentAs(generatedDay.ibadatTimings.nextFajr)) {
        dateToGenerate = dateToGenerate.add(const Duration(days: 1));
        generatedDay = getOrGenerateDay(dateToGenerate);
      }

      final initialState = SuwayaTimeEngine.calculateCurrentState(generatedDay, cityNow);
      
      _lastPeriodId = initialState.currentPeriod.id;
      _lastSuwaya = initialState.currentSuwaya;
      
      Future.microtask(() => virtualTimeNotifier.value = initialState.currentFormattedVirtualTime);

      _startTicker(generatedDay, loc);
      return initialState;
      
    } catch (e) {
      debugPrint('AstroEngine Error: $e');
      return SuwayaTimeEngine.getFallbackState(_getCityNow(loc));
    }
  }

  void _startTicker(SuwayaDay day, SavedLocation? loc) {
    _timer?.cancel();
    if (day.periods.isEmpty) return;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final tickNow = _getCityNow(loc);
      if (tickNow.isAfter(day.ibadatTimings.nextFajr) || tickNow.isAtSameMomentAs(day.ibadatTimings.nextFajr)) {
        _timer?.cancel();
        Future.microtask(() => ref.invalidateSelf());
        return;
      }
      
      final newState = SuwayaTimeEngine.calculateCurrentState(day, tickNow);
      virtualTimeNotifier.value = newState.currentFormattedVirtualTime;

      if (_lastPeriodId != newState.currentPeriod.id || _lastSuwaya != newState.currentSuwaya) {
         _lastPeriodId = newState.currentPeriod.id;
         _lastSuwaya = newState.currentSuwaya;
         state = newState; 
      }
    });
  }

  PrayerKey? _parsePrayerKey(String? periodIdStr) {
    switch (periodIdStr) {
      case '1': return PrayerKey.fajr; case 'sunrise': return PrayerKey.sunrise;
      case '3': return PrayerKey.dhuhr; case '4': return PrayerKey.asr;
      case '5': return PrayerKey.maghrib; case 'isha': return PrayerKey.isha;
      default: return null;
    }
  }

  void resetToRealTime() => ref.invalidateSelf();
}

final astroProvider = NotifierProvider<AstroNotifier, AstroState>(AstroNotifier.new);