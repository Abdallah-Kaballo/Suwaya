import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:suwaya_time/suwaya_time.dart';

import '../../models/settings_model.dart';
import '../../features/settings/settings_provider.dart';

final virtualTimeNotifier = ValueNotifier<String>("00:00");
final virtualDateTimeNotifier = ValueNotifier<DateTime>(DateTime.now());
final Map<String, SuwayaDay> _dayCache = {};

class AstroNotifier extends Notifier<AstroState> {
  Timer? _stateTimer;
  Timer? _uiTimer;

  int _lastPeriodId = -1;
  int _lastSuwaya = -1;

  /// 🌟 حساب فرق التوقيت (UTC Offset) لموقع وتاريخ محددين مع مراعاة التوقيت الصيفي والشتوي (DST)
  Duration _getUtcOffsetForLocation(SavedLocation? loc, [DateTime? referenceDate]) {
    if (loc != null && loc.timezone != null && loc.timezone!.isNotEmpty) {
      try {
        final location = tz.getLocation(loc.timezone!);
        if (referenceDate != null) {
          // نأخذ منتصف النهار (12:00) للتاريخ المرجعي لضمان الحصول على الـ Offset المستقر لذلك اليوم بعد أي تحول فجري للـ DST
          final targetTzTime = tz.TZDateTime(
            location,
            referenceDate.year,
            referenceDate.month,
            referenceDate.day,
            12,
          );
          return targetTzTime.timeZoneOffset;
        }
        return tz.TZDateTime.now(location).timeZoneOffset;
      } catch (_) {}
    }

    if (referenceDate != null) {
      return DateTime(
        referenceDate.year,
        referenceDate.month,
        referenceDate.day,
        12,
      ).timeZoneOffset;
    }
    return DateTime.now().timeZoneOffset;
  }

  /// 🌟 جلب الوقت الحالي للمدينة بصيغة Wall-Clock UTC الموحدة
  DateTime _getCityNow(SavedLocation? loc) {
    if (loc != null && loc.timezone != null && loc.timezone!.isNotEmpty) {
      try {
        final nowInTarget = tz.TZDateTime.now(tz.getLocation(loc.timezone!));
        return DateTime.utc(
          nowInTarget.year,
          nowInTarget.month,
          nowInTarget.day,
          nowInTarget.hour,
          nowInTarget.minute,
          nowInTarget.second,
        );
      } catch (_) {}
    }
    final now = DateTime.now();
    return DateTime.utc(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
    );
  }

  // 🌟 إرجاع الوقت بالصيغة الذهبية | مع الإيموجي أو الحرف المناسب
  String _formatVirtualTime(SuwayaClockTime ct) {
    return '${ct.phaseSlotNumber.toString().padLeft(2, '0')}|${ct.virtualMinute.toString().padLeft(2, '0')} ${ct.phase.isDay ? '☀️' : '🌑'}';
  }

  @override
  AstroState build() {
    final fingerprint = ref.watch(settingsProvider.select((s) {
      String f = '${s.activeLocation?.latitude}_${s.activeLocation?.longitude}_'
          '${s.activeLocation?.timezone ?? ''}_${s.calculationMethod}_'
          '${s.madhab}_${s.highLatitudeRule}_${s.customFajrAngle}_${s.customIshaAngle}';
      for (var c in s.periodConfigs) {
        f += '_${c.periodId}:${c.manualOffsetMinutes}';
      }
      return f;
    }));

    final settings = ref.read(settingsProvider);
    final SavedLocation? loc = settings.activeLocation;

    try {
      ref.onDispose(() {
        _stateTimer?.cancel();
        _uiTimer?.cancel();
      });

      final DateTime cityNow = _getCityNow(loc);
      final Duration currentOffset = _getUtcOffsetForLocation(loc, cityNow);

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

      // 🌟 استخراج توقيت المغرب لليوم الحالي فقط لمعرفة أي دورة نختار
      final tempIbadat = PrayerCalculator.getIbadatTimings(
        loc?.latitude ?? 21.4225,
        loc?.longitude ?? 39.8262,
        cityNow,
        methodEnum,
        madhabEnum,
        highLatEnum,
        settings.customFajrAngle,
        settings.customIshaAngle,
        currentOffset,
        manualOffsets: manualOffsetsMap,
      );

      final DateTime dateToGenerate = cityNow.isBefore(tempIbadat.maghrib)
          ? cityNow.subtract(const Duration(days: 1))
          : cityNow;

      final Duration cycleOffset = _getUtcOffsetForLocation(loc, dateToGenerate);

      SuwayaDay getOrGenerateDay(DateTime date) {
        // 🌟 تضمين فرق التوقيت بالدقائق في الكاش لضمان إعادة الحساب إذا حدث تحول صيفي/شتوي
        final String cacheKey =
            '${date.year}-${date.month}-${date.day}_${cycleOffset.inMinutes}_${currentOffset.inMinutes}_$fingerprint';
        if (_dayCache.containsKey(cacheKey)) {
          return _dayCache[cacheKey]!;
        } else {
          final newDay = SuwayaTimeEngine.generateDay(
            loc?.latitude ?? 21.4225,
            loc?.longitude ?? 39.8262,
            date,
            methodEnum,
            madhabEnum,
            highLatEnum,
            settings.customFajrAngle,
            settings.customIshaAngle,
            cycleOffset,
            manualOffsets: manualOffsetsMap,
          );
          if (_dayCache.length > 3) _dayCache.clear();
          _dayCache[cacheKey] = newDay;
          return newDay;
        }
      }

      final generatedDay = getOrGenerateDay(dateToGenerate);
      final initialState =
          SuwayaTimeEngine.calculateCurrentState(generatedDay, cityNow);

      _lastPeriodId = initialState.currentPeriod.id;
      _lastSuwaya = initialState.currentSuwayaTime.periodLocalSlotNumber;

      Future.microtask(() {
        virtualDateTimeNotifier.value = initialState.virtualTime;
        virtualTimeNotifier.value =
            _formatVirtualTime(initialState.currentSuwayaTime);
      });

      _scheduleSmartStateUpdate(generatedDay, loc, currentOffset);
      _startUITicker(generatedDay, loc);

      return initialState;
    } catch (e) {
      debugPrint('AstroEngine Error: $e');
      return SuwayaTimeEngine.getFallbackState(_getCityNow(loc));
    }
  }

  void _startUITicker(SuwayaDay day, SavedLocation? loc) {
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final tickNow = _getCityNow(loc);
      final newState = SuwayaTimeEngine.calculateCurrentState(day, tickNow);
      virtualDateTimeNotifier.value = tickNow;
      virtualTimeNotifier.value =
          _formatVirtualTime(newState.currentSuwayaTime);
    });
  }

  void _scheduleSmartStateUpdate(
    SuwayaDay day,
    SavedLocation? loc,
    Duration activeOffset,
  ) {
    _stateTimer?.cancel();
    if (day.periods.isEmpty) return;

    final tickNow = _getCityNow(loc);
    final nowOffset = _getUtcOffsetForLocation(loc, tickNow);

    // 🌟 إعادة البناء عند نهاية الدورة (المغرب القادم) أو إذا تغير فرق التوقيت الصيفي/الشتوي فجأة
    if (nowOffset != activeOffset ||
        tickNow.isAfter(day.cycleAnchors.cycleEndMaghrib) ||
        tickNow.isAtSameMomentAs(day.cycleAnchors.cycleEndMaghrib)) {
      Future.microtask(() => ref.invalidateSelf());
      return;
    }

    final currentState = SuwayaTimeEngine.calculateCurrentState(day, tickNow);
    final p = currentState.currentPeriod;
    final suwayaCount = p.suwayasCount > 0 ? p.suwayasCount : 1;
    final suwayaDurationMicroseconds =
        p.endTime.difference(p.startTime).inMicroseconds ~/ suwayaCount;

    final nextSuwayaTime = p.startTime.add(
      Duration(
        microseconds: suwayaDurationMicroseconds *
            currentState.currentSuwayaTime.periodLocalSlotNumber,
      ),
    );
    final durationUntilNextSuwaya = nextSuwayaTime.difference(tickNow);

    final sleepDuration = durationUntilNextSuwaya.inSeconds > 0
        ? durationUntilNextSuwaya
        : const Duration(seconds: 1);

    _stateTimer = Timer(sleepDuration, () {
      final newTickNow = _getCityNow(loc);
      final newState = SuwayaTimeEngine.calculateCurrentState(day, newTickNow);

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
        return PrayerKey.fajr;
      case 'sunrise':
        return PrayerKey.sunrise;
      case '3':
        return PrayerKey.dhuhr;
      case '4':
        return PrayerKey.asr;
      case '5':
        return PrayerKey.maghrib;
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