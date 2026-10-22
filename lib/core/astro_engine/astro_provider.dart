import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suwaya_time/suwaya_time.dart';

import '../../models/settings_model.dart';
import '../../features/settings/settings_provider.dart';

final virtualTimeNotifier = ValueNotifier<String>("00|00|00");
final virtualDateTimeNotifier = ValueNotifier<DateTime>(DateTime.now());
final Map<String, SuwayaDay> _dayCache = {};

// استبدل الكلاس AstroNotifier بالمقطع التالي:

class AstroNotifier extends Notifier<AstroState> {
  Timer? _stateTimer;
  Timer? _uiTimer;

  int _lastPeriodId = -1;
  int _lastSuwaya = -1;
  int _lastCivilDay = -1;

  Duration _getUtcOffsetForInstant(
    SavedLocation? loc,
    DateTime instantUtc,
  ) {
    return TimezoneResolver.resolveForInstant(
      instantUtc,
      timezoneId: loc?.timezone,
    ).utcOffset;
  }

  DateTime _getCityNowFromUtc(SavedLocation? loc, DateTime nowUtc) {
    final offset = _getUtcOffsetForInstant(loc, nowUtc);
    return nowUtc.add(offset);
  }

  String _formatVirtualTime(SuwayaClockTime ct) {
    final s = ct.phaseSlotNumber.toString().padLeft(2, '0');
    final m = ct.virtualMinute.toString().padLeft(2, '0');
    final sec = ct.virtualSecond.toString().padLeft(2, '0');
    return '$s|$m|$sec';
  }

  @override
  AstroState build() {
    final fingerprint = ref.watch(settingsProvider.select((s) {
      String f = '${s.activeLocation?.latitude}_${s.activeLocation?.longitude}_'
          '${s.activeLocation?.timezone ?? ''}_${s.calculationMethod}_'
          '${s.madhab}_${s.highLatitudeRule}_${s.customFajrAngle}_${s.customIshaAngle}_${s.hijriOffsetDays}';
      for (final c in s.periodConfigs) {
        f += '_${c.periodId}:${c.manualOffsetMinutes}';
      }
      return f;
    }));

    final settings = ref.read(settingsProvider);
    final SavedLocation? loc = settings.activeLocation;
    final DateTime nowUtc = DateTime.now().toUtc();

    try {
      ref.onDispose(() {
        _stateTimer?.cancel();
        _uiTimer?.cancel();
      });

      final Map<PrayerKey, int> manualOffsetsMap = {};
      for (final c in settings.periodConfigs) {
        if (c.periodId != null) {
          final pKey = _parsePrayerKey(c.periodId);
          if (pKey != null) manualOffsetsMap[pKey] = c.manualOffsetMinutes;
        }
      }

      final methodEnum = settings.calculationMethod.toCalculationMethod();
      final madhabEnum = settings.madhab.toMadhab();
      final highLatEnum = settings.highLatitudeRule.toHighLatRule();

      // تقييم السياق الزمني الموحد عبر TemporalContextEngine
      final temporalContext = TemporalContextEngine.evaluate(
        instantUtc: nowUtc,
        latitude: loc?.latitude ?? 21.4225,
        longitude: loc?.longitude ?? 39.8262,
        timezoneId: loc?.timezone,
        methodType: methodEnum,
        madhabType: madhabEnum,
        highLatRuleType: highLatEnum,
        customFajrAngle: settings.customFajrAngle,
        customIshaAngle: settings.customIshaAngle,
        manualOffsets: manualOffsetsMap,
        hijriAdjustmentDays: settings.hijriOffsetDays,
      );

      final generatedDay = temporalContext.suwayaDay;
      final initialState = temporalContext.astroState;

      final anchorStart = generatedDay.cycleAnchors.cycleStartMaghrib;
      final cacheKey =
          '${anchorStart.year}-${anchorStart.month}-${anchorStart.day}_$fingerprint';
      if (_dayCache.length > 3) _dayCache.clear();
      _dayCache[cacheKey] = generatedDay;

      _lastPeriodId = initialState.currentPeriod.id;
      _lastSuwaya = initialState.currentSuwayaTime.periodLocalSlotNumber;
      _lastCivilDay = temporalContext.civilDate.day;

      Future.microtask(() {
        virtualDateTimeNotifier.value = initialState.virtualTime;
        virtualTimeNotifier.value =
            _formatVirtualTime(initialState.currentSuwayaTime);
      });

      _scheduleSmartStateUpdate(
        generatedDay,
        loc,
        temporalContext.timezone.utcOffset,
      );
      _startUITicker(generatedDay, loc);

      return initialState;
    } catch (e) {
      debugPrint('AstroEngine Error: $e');
      return SuwayaTimeEngine.getFallbackState(_getCityNowFromUtc(loc, nowUtc));
    }
  }

  /// تحديث حي كل 250ms يعتمد على UTC الحقيقي لمنع أي انحراف أثناء التوقيت الصيفي
  void _startUITicker(SuwayaDay day, SavedLocation? loc) {
    _uiTimer?.cancel();
    int lastCivilSecond = -1;
    String lastFormattedVirtual = virtualTimeNotifier.value;

    _uiTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final nowUtc = DateTime.now().toUtc();
      final tickNow = _getCityNowFromUtc(loc, nowUtc);

      // عند عبور منتصف الليل المدني (00:00)، نعيد بناء المزود لتحديث civilDayIbadat لليوم الجديد
      if (_lastCivilDay != -1 && tickNow.day != _lastCivilDay) {
        _lastCivilDay = tickNow.day;
        Future.microtask(() => ref.invalidateSelf());
        return;
      }

      final newState = SuwayaTimeEngine.calculateCurrentState(
        day,
        tickNow,
        nowUtc: nowUtc,
      );
      final formatted = _formatVirtualTime(newState.currentSuwayaTime);

      if (formatted != lastFormattedVirtual) {
        lastFormattedVirtual = formatted;
        virtualTimeNotifier.value = formatted;
      }

      if (tickNow.second != lastCivilSecond) {
        lastCivilSecond = tickNow.second;
        virtualDateTimeNotifier.value = tickNow;
      }
    });
  }

  void _scheduleSmartStateUpdate(
    SuwayaDay day,
    SavedLocation? loc,
    Duration activeOffset,
  ) {
    _stateTimer?.cancel();
    if (day.periods.isEmpty) return;

    final nowUtc = DateTime.now().toUtc();
    final tickNow = _getCityNowFromUtc(loc, nowUtc);
    final nowOffset = _getUtcOffsetForInstant(loc, nowUtc);

    final cycleEndUtc = day.cycleAnchors.cycleEndMaghribUtc;
    final hasCycleEnded = cycleEndUtc != null
        ? !nowUtc.isBefore(cycleEndUtc)
        : !tickNow.isBefore(day.cycleAnchors.cycleEndMaghrib);

    if (nowOffset != activeOffset || hasCycleEnded) {
      Future.microtask(() => ref.invalidateSelf());
      return;
    }

    final currentState = SuwayaTimeEngine.calculateCurrentState(
      day,
      tickNow,
      nowUtc: nowUtc,
    );
    final p = currentState.currentPeriod;

    final durationUntilNextSuwaya = p.durationUntilNextSuwaya(
      currentLocalSlotNumber:
          currentState.currentSuwayaTime.periodLocalSlotNumber,
      now: tickNow,
      nowUtc: nowUtc,
    );

    final sleepDuration = durationUntilNextSuwaya.inMilliseconds > 250
        ? durationUntilNextSuwaya
        : const Duration(milliseconds: 250);

    _stateTimer = Timer(sleepDuration, () {
      final newNowUtc = DateTime.now().toUtc();
      final newTickNow = _getCityNowFromUtc(loc, newNowUtc);
      final newState = SuwayaTimeEngine.calculateCurrentState(
        day,
        newTickNow,
        nowUtc: newNowUtc,
      );

      if (_lastPeriodId != newState.currentPeriod.id ||
          _lastSuwaya != newState.currentSuwayaTime.periodLocalSlotNumber) {
        _lastPeriodId = newState.currentPeriod.id;
        _lastSuwaya = newState.currentSuwayaTime.periodLocalSlotNumber;
        state = newState;
      }

      _scheduleSmartStateUpdate(day, loc, nowOffset);
    });
  }

  PrayerKey? _parsePrayerKey(String? periodIdStr) {
    switch (periodIdStr) {
      case '1':
      case 'fajr':
        return PrayerKey.fajr;
      case 'sunrise':
        return PrayerKey.sunrise;
      case '3':
      case 'dhuhr':
        return PrayerKey.dhuhr;
      case '4':
      case 'asr':
        return PrayerKey.asr;
      case '5':
      case 'maghrib':
        return PrayerKey.maghrib;
      case '9':
      case 'isha':
        return PrayerKey.isha;
      default:
        return null;
    }
  }

  void resetToRealTime() => ref.invalidateSelf();
}

final astroProvider =
    NotifierProvider<AstroNotifier, AstroState>(AstroNotifier.new);