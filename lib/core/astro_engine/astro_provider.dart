import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suwaya_time/suwaya_time.dart';

import '../../models/settings_model.dart';
import '../../features/settings/settings_provider.dart';

final virtualTimeNotifier = ValueNotifier<String>("00|00|00");
final virtualDateTimeNotifier = ValueNotifier<DateTime>(DateTime.now());

/// يتحدث كل 15 ثانية فقط لتحريك عقرب القرص الفلكي دون إعادة بناء القرص 60 مرة في الدقيقة
final dialQuantizedTimeNotifier = ValueNotifier<DateTime>(DateTime.now());

final Map<String, SuwayaDay> _dayCache = {};

class AstroNotifier extends Notifier<AstroState> {
  Timer? _stateTimer;
  Timer? _uiTimer;
  AppLifecycleListener? _lifecycleListener;

  int _lastPeriodId = -1;
  int _lastSuwaya = -1;
  int _lastCivilDay = -1;

  int _cachedOffsetMinuteEpoch = -1;
  Duration _cachedUtcOffset = Duration.zero;

  Duration _getUtcOffsetForInstant(SavedLocation? loc, DateTime instantUtc) {
    final currentMinuteEpoch = instantUtc.millisecondsSinceEpoch ~/ 60000;
    if (_cachedOffsetMinuteEpoch == currentMinuteEpoch) {
      return _cachedUtcOffset;
    }
    _cachedUtcOffset = TimezoneResolver.resolveForInstant(
      instantUtc,
      timezoneId: loc?.timezone,
    ).utcOffset;
    _cachedOffsetMinuteEpoch = currentMinuteEpoch;
    return _cachedUtcOffset;
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
    final fingerprint = ref.watch(
      settingsProvider.select((s) {
        String f =
            '${s.activeLocation?.latitude}_${s.activeLocation?.longitude}_'
            '${s.activeLocation?.timezone ?? ''}_${s.calculationMethod}_'
            '${s.madhab}_${s.highLatitudeRule}_${s.customFajrAngle}_${s.customIshaAngle}_${s.hijriOffsetDays}';
        for (final c in s.periodConfigs) {
          f += '_${c.periodId}:${c.manualOffsetMinutes}';
        }
        return f;
      }),
    );

    _cachedOffsetMinuteEpoch = -1;
    final settings = ref.read(settingsProvider);
    final SavedLocation? loc = settings.activeLocation;
    final DateTime nowUtc = DateTime.now().toUtc();

    try {
      ref.onDispose(() {
        _stateTimer?.cancel();
        _stateTimer = null;
        _uiTimer?.cancel();
        _uiTimer = null;
        _lifecycleListener?.dispose();
        _lifecycleListener = null;
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
        dialQuantizedTimeNotifier.value = initialState.virtualTime;
        virtualTimeNotifier.value = _formatVirtualTime(
          initialState.currentSuwayaTime,
        );
      });

      _scheduleSmartStateUpdate(
        generatedDay,
        loc,
        temporalContext.timezone.utcOffset,
      );
      _startUITicker(generatedDay, loc);

      _lifecycleListener?.dispose();
      _lifecycleListener = AppLifecycleListener(
        onPause: () {
          _uiTimer?.cancel();
          _stateTimer?.cancel();
        },
        onHide: () {
          _uiTimer?.cancel();
          _stateTimer?.cancel();
        },
        onResume: () {
          final resumeUtc = DateTime.now().toUtc();
          final resumeOffset = _getUtcOffsetForInstant(loc, resumeUtc);
          final resumeWall = resumeUtc.add(resumeOffset);
          final cycleEndUtc = generatedDay.cycleAnchors.cycleEndMaghribUtc;
          final hasCycleEnded = cycleEndUtc != null
              ? !resumeUtc.isBefore(cycleEndUtc)
              : !resumeWall.isBefore(generatedDay.cycleAnchors.cycleEndMaghrib);

          if (resumeWall.day != _lastCivilDay ||
              hasCycleEnded ||
              resumeOffset != temporalContext.timezone.utcOffset) {
            ref.invalidateSelf();
            return;
          }

          final resumedState = SuwayaTimeEngine.calculateCurrentState(
            generatedDay,
            resumeWall,
            nowUtc: resumeUtc,
          );
          virtualDateTimeNotifier.value = resumeWall;
          dialQuantizedTimeNotifier.value = resumeWall;
          virtualTimeNotifier.value = _formatVirtualTime(
            resumedState.currentSuwayaTime,
          );

          if (_lastPeriodId != resumedState.currentPeriod.id ||
              _lastSuwaya !=
                  resumedState.currentSuwayaTime.periodLocalSlotNumber) {
            _lastPeriodId = resumedState.currentPeriod.id;
            _lastSuwaya = resumedState.currentSuwayaTime.periodLocalSlotNumber;
            state = resumedState;
          }

          _scheduleSmartStateUpdate(generatedDay, loc, resumeOffset);
          _startUITicker(generatedDay, loc);
        },
      );

      return initialState;
    } catch (e) {
      debugPrint('AstroEngine Error: $e');
      return SuwayaTimeEngine.getFallbackState(_getCityNowFromUtc(loc, nowUtc));
    }
  }

  /// مؤقت تكيّفي ذكي يستيقظ بالضبط عند ولادة الثانية الافتراضية التالية في الفترة النشطة
  void _startUITicker(SuwayaDay day, SavedLocation? loc) {
    _uiTimer?.cancel();
    int lastCivilSecond = -1;
    int lastQuantized15SecSlot = -1;
    String lastFormattedVirtual = virtualTimeNotifier.value;

    void scheduleNextAdaptiveTick() {
      _uiTimer?.cancel();
      final nowUtc = DateTime.now().toUtc();
      final tickNow = _getCityNowFromUtc(loc, nowUtc);

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

      final current15SecSlot = tickNow.millisecondsSinceEpoch ~/ 15000;
      if (current15SecSlot != lastQuantized15SecSlot) {
        lastQuantized15SecSlot = current15SecSlot;
        dialQuantizedTimeNotifier.value = tickNow;
      }

      final activePeriod = newState.currentPeriod;
      final sCount = activePeriod.suwayasCount > 0
          ? activePeriod.suwayasCount
          : 1;
      final periodMicro = activePeriod.totalDuration.inMicroseconds;

      Duration nextWakeDelay;
      if (periodMicro > 0 && activePeriod.startUtc != null) {
        final totalVirtualSecondsInPeriod = sCount * 3600;
        final elapsedMicro = nowUtc
            .difference(activePeriod.startUtc!)
            .inMicroseconds;

        final currentVirtualSecIndex =
            (elapsedMicro * totalVirtualSecondsInPeriod) ~/ periodMicro;
        final nextVirtualSecIndex = currentVirtualSecIndex + 1;

        final nextBoundaryMicro =
            (nextVirtualSecIndex * periodMicro +
                totalVirtualSecondsInPeriod -
                1) ~/
            totalVirtualSecondsInPeriod;

        final remainingMicro = nextBoundaryMicro - elapsedMicro;
        nextWakeDelay = Duration(
          microseconds: remainingMicro.clamp(50000, 2000000),
        );
      } else {
        nextWakeDelay = Duration(
          milliseconds: 1000 - (nowUtc.millisecond % 1000),
        );
      }

      _uiTimer = Timer(nextWakeDelay, scheduleNextAdaptiveTick);
    }

    scheduleNextAdaptiveTick();
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

final astroProvider = NotifierProvider<AstroNotifier, AstroState>(
  AstroNotifier.new,
);
