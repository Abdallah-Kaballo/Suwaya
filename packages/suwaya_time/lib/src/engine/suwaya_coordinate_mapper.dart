import '../models/astro_models.dart';
import '../models/temporal_primitives.dart';

class SuwayaCoordinateMapper {
  // ===========================================================================
  // 1. التحويل بين الفهارس العالمية (0..23) والمحلية (Period + Local Suwaya)
  // ===========================================================================

  /// تحويل الفهرس العالمي للسويعة (0..23) إلى (الفترة الفلكية + رقم السويعة المحلي)
  static ({
    int periodId,
    PeriodKey periodKey,
    int localSuwaya,
    int suwayasCount,
  }) globalToLocal(
    int globalSlotIndex,
    List<AstroPeriod> periods,
  ) {
    if (periods.isEmpty) {
      return (
        periodId: 1,
        periodKey: PeriodKey.nightMaghribIsha,
        localSuwaya: 1,
        suwayasCount: 1,
      );
    }

    int remaining = globalSlotIndex.clamp(0, 23);
    for (final p in periods) {
      final count = p.suwayasCount > 0 ? p.suwayasCount : 1;
      if (remaining < count) {
        return (
          periodId: p.id,
          periodKey: p.periodKey,
          localSuwaya: remaining + 1,
          suwayasCount: count,
        );
      }
      remaining -= count;
    }

    final last = periods.last;
    final lastCount = last.suwayasCount > 0 ? last.suwayasCount : 1;
    return (
      periodId: last.id,
      periodKey: last.periodKey,
      localSuwaya: lastCount,
      suwayasCount: lastCount,
    );
  }

  /// تحويل (معرف الفترة + رقم السويعة المحلي) إلى الفهرس العالمي (0..23)
  static int localToGlobal(
    int? periodId,
    int? localSuwaya,
    List<AstroPeriod> periods,
  ) {
    if (periodId == null || periods.isEmpty) return 0;
    int global = 0;
    for (final p in periods) {
      final count = p.suwayasCount > 0 ? p.suwayasCount : 1;
      if (p.id == periodId) {
        final effectiveLocal = (localSuwaya == null || localSuwaya == -1)
            ? (count ~/ 2) + 1
            : localSuwaya.clamp(1, count);
        return (global + effectiveLocal - 1).clamp(0, 23);
      }
      global += count;
    }
    return 0;
  }

  /// تحويل اختيار عجلة الواجهة (سويعة 1..12 + ليل/نهار) إلى الفهرس العالمي (0..23)
  static int uiPhaseToGlobal(int uiHour, bool isNight) {
    final clampedHour = uiHour.clamp(1, 12);
    return isNight ? (clampedHour - 1) : (clampedHour + 11);
  }

  /// تحويل الفهرس العالمي (0..23) إلى (سويعة 1..12 + ليل/نهار)
  static ({int uiHour, bool isNight, SuwayaPhase phase}) globalToUiPhase(
    int globalSlotIndex,
  ) {
    final clamped = globalSlotIndex.clamp(0, 23);
    final isNight = clamped < 12;
    final uiHour = isNight ? (clamped + 1) : (clamped - 11);
    return (
      uiHour: uiHour,
      isNight: isNight,
      phase: isNight ? SuwayaPhase.night : SuwayaPhase.day,
    );
  }

  // ===========================================================================
  // 2. التحويل الثنائي الدقيق بين الزمن الفيزيائي والإحداثي السُويعي
  // ===========================================================================

  /// تحويل أي لحظة زمنية إلى إحداثي سُويعي كامل بدقة المايكروثانية
  static SuwayaCoordinate instantToCoordinate({
    required SuwayaDay day,
    required DateTime instant,
    DateTime? instantUtc,
  }) {
    if (day.periods.isEmpty) {
      return const SuwayaCoordinate(
        globalSlotIndex: 0,
        phase: SuwayaPhase.night,
        phaseSlotNumber: 1,
        periodId: 1,
        periodKey: PeriodKey.nightMaghribIsha,
        periodLocalSlotNumber: 1,
        virtualMinute: 0,
        virtualSecond: 0,
        slotProgress: 0.0,
      );
    }

    final bool useUtc = instantUtc != null &&
        day.periods.every((p) => p.startUtc != null && p.endUtc != null);

    AstroPeriod activePeriod = day.periods.last;
    int accumulatedGlobalSlots = 0;

    for (final p in day.periods) {
      final pStart = useUtc ? p.startUtc! : p.startTime;
      final pEnd = useUtc ? p.endUtc! : p.endTime;
      final target = useUtc ? instantUtc : instant;

      if (!target.isBefore(pStart) && target.isBefore(pEnd)) {
        activePeriod = p;
        break;
      }
      if (target.isBefore(pStart) && p.id == day.periods.first.id) {
        activePeriod = day.periods.first;
        accumulatedGlobalSlots = 0;
        break;
      }
      accumulatedGlobalSlots += p.suwayasCount;
    }

    // في حال كانت اللحظة عند أو بعد نهاية الفترة الأخيرة
    if (accumulatedGlobalSlots >= 24) {
      activePeriod = day.periods.last;
      accumulatedGlobalSlots = 24 - activePeriod.suwayasCount;
    }

    final int count =
        activePeriod.suwayasCount > 0 ? activePeriod.suwayasCount : 1;
    final int periodMicro = useUtc
        ? activePeriod.totalDuration.inMicroseconds
        : activePeriod.endTime
            .difference(activePeriod.startTime)
            .inMicroseconds;

    if (periodMicro <= 0) {
      final ui = globalToUiPhase(accumulatedGlobalSlots);
      return SuwayaCoordinate(
        globalSlotIndex: accumulatedGlobalSlots,
        phase: ui.phase,
        phaseSlotNumber: ui.uiHour,
        periodId: activePeriod.id,
        periodKey: activePeriod.periodKey,
        periodLocalSlotNumber: 1,
        virtualMinute: 0,
        virtualSecond: 0,
        slotProgress: 0.0,
      );
    }

    final int elapsedMicro = (useUtc
            ? instantUtc.difference(activePeriod.startUtc!).inMicroseconds
            : instant.difference(activePeriod.startTime).inMicroseconds)
        .clamp(0, periodMicro - 1);

    // حساب موقع السويعة والدقيقة والثانية الافتراضية باستخدام الحساب الصحيح المضاد لانجراف الفاصلة العائمة
    final int totalVirtualSecondsInPeriod = count * 3600;
    final int currentPeriodVirtualSec =
        ((elapsedMicro * totalVirtualSecondsInPeriod) ~/ periodMicro)
            .clamp(0, totalVirtualSecondsInPeriod - 1);

    final int localSlotIndex = currentPeriodVirtualSec ~/ 3600; // 0 .. count-1
    final int remSecInSlot = currentPeriodVirtualSec % 3600;
    final int virtualMin = remSecInSlot ~/ 60;
    final int virtualSec = remSecInSlot % 60;

    final double suwayaMicro = periodMicro / count;
    final double slotProgress =
        ((elapsedMicro - (localSlotIndex * suwayaMicro)) / suwayaMicro)
            .clamp(0.0, 0.999999);

    final int globalIndex =
        (accumulatedGlobalSlots + localSlotIndex).clamp(0, 23);
    final uiPhase = globalToUiPhase(globalIndex);

    return SuwayaCoordinate(
      globalSlotIndex: globalIndex,
      phase: uiPhase.phase,
      phaseSlotNumber: uiPhase.uiHour,
      periodId: activePeriod.id,
      periodKey: activePeriod.periodKey,
      periodLocalSlotNumber: localSlotIndex + 1,
      virtualMinute: virtualMin,
      virtualSecond: virtualSec,
      slotProgress: slotProgress,
    );
  }

  /// تحويل عكسي دقيق من (الفهرس العالمي 0..23 + الدقيقة الافتراضية 0..59) إلى اللحظة الفيزيائية
  /// يحقق معادلة التطابق العكسي: instantToCoordinate(coordinateToInstant(G, M)) == (G, M)
  static ({DateTime instantUtc, DateTime wallTime}) coordinateToInstant({
    required SuwayaDay day,
    required int globalSlotIndex,
    required int virtualMinute,
    int virtualSecond = 0,
    DateTime Function(DateTime utcInstant)? toWallClock,
  }) {
    final mapped = globalToLocal(globalSlotIndex, day.periods);
    final period = day.periods.firstWhere(
      (p) => p.id == mapped.periodId,
      orElse: () => day.periods.first,
    );

    return periodSlotToInstant(
      period: period,
      localSuwaya: mapped.localSuwaya,
      virtualMinute: virtualMinute,
      virtualSecond: virtualSecond,
      toWallClock: toWallClock,
    );
  }

  /// تحويل عكسي دقيق من (فترة + سويعة محلية + دقيقة افتراضية + ثانية افتراضية) إلى زمن فيزيائي
  static ({DateTime instantUtc, DateTime wallTime}) periodSlotToInstant({
    required AstroPeriod period,
    required int localSuwaya,
    required int virtualMinute,
    int virtualSecond = 0,
    DateTime Function(DateTime utcInstant)? toWallClock,
  }) {
    final count = period.suwayasCount > 0 ? period.suwayasCount : 1;
    final suwayaIndex = (localSuwaya - 1).clamp(0, count - 1);
    final minute = virtualMinute.clamp(0, 59);
    final second = virtualSecond.clamp(0, 59);

    final int totalVirtualSecondsInPeriod = count * 3600;
    final int requestedVirtualSeconds =
        (suwayaIndex * 3600) + (minute * 60) + second;

    final baseStartUtc = period.startUtc ?? period.startTime;
    final periodMicro = period.totalDuration.inMicroseconds;

    // معادلة السقف الصحيحة (Ceiling Integer Division) لضمان وقوع اللحظة داخل الثانية الافتراضية المطلوبة تماماً
    final int offsetUtcMicro = (periodMicro * requestedVirtualSeconds +
            totalVirtualSecondsInPeriod -
            1) ~/
        totalVirtualSecondsInPeriod;

    final resolvedUtc =
        baseStartUtc.add(Duration(microseconds: offsetUtcMicro));

    if (period.startUtc != null && toWallClock != null) {
      return (instantUtc: resolvedUtc, wallTime: toWallClock(resolvedUtc));
    }

    final wallSpanMicro =
        period.endTime.difference(period.startTime).inMicroseconds;
    final int offsetWallMicro = (wallSpanMicro * requestedVirtualSeconds +
            totalVirtualSecondsInPeriod -
            1) ~/
        totalVirtualSecondsInPeriod;

    final resolvedWall =
        period.startTime.add(Duration(microseconds: offsetWallMicro));

    return (instantUtc: resolvedUtc, wallTime: resolvedWall);
  }

  // ===========================================================================
  // 3. المراسي الثابتة للصلوات وأجزاء الليل والتنسيق النصي الموحد
  // ===========================================================================

  /// حساب الإحداثي السويعي لبداية أو نهاية أي فترة أو صلاة أو جزء من أجزاء الليل الخمسة
  static ({int globalIndex, int minute}) fixedBoundaryCoordinate(
    String identifier,
    List<AstroPeriod> periods, {
    bool isEnd = false,
  }) {
    int getCount(PeriodKey k) {
      for (final p in periods) {
        if (p.periodKey == k) return p.suwayasCount;
      }
      return 1;
    }

    int startG = 0;
    int length = 1;
    final sid = identifier.trim().toLowerCase();

    if (sid == '1' || sid.contains('maghrib')) {
      startG = 0;
      length = getCount(PeriodKey.nightMaghribIsha);
    } else if (sid == '2' || sid.contains('isha')) {
      startG = getCount(PeriodKey.nightMaghribIsha);
      length = getCount(PeriodKey.nightIshaMidnight);
    } else if (sid == '3' || sid.contains('qiyam') || sid.contains('half_2')) {
      startG = 5;
      length = 6;
    } else if (sid == '4' || sid.contains('fajr')) {
      startG = 11;
      length = 1;
    } else if (sid == '5' || sid.contains('duha') || sid.contains('sunrise')) {
      startG = 12;
      length = getCount(PeriodKey.daySunriseDhuhr);
    } else if (sid == '6' || sid.contains('dhuhr')) {
      startG = 12 + getCount(PeriodKey.daySunriseDhuhr);
      length = getCount(PeriodKey.dayDhuhrAsr);
    } else if (sid == '7' || sid.contains('asr')) {
      startG = 12 +
          getCount(PeriodKey.daySunriseDhuhr) +
          getCount(PeriodKey.dayDhuhrAsr);
      length = getCount(PeriodKey.dayAsrMaghrib);
    } else if (sid.contains('third_3')) {
      startG = 7;
      length = 4;
    } else if (sid.contains('sixth_4')) {
      startG = 5;
      length = 2;
    } else if (sid.contains('sixth_5')) {
      startG = 7;
      length = 2;
    } else if (sid.contains('sixth_6')) {
      startG = 9;
      length = 2;
    }

    if (isEnd) {
      final int endTotalMinutes = (startG * 60) + (length * 60) - 1;
      return (
        globalIndex: (endTotalMinutes ~/ 60) % 24,
        minute: endTotalMinutes % 60,
      );
    }
    return (globalIndex: startG % 24, minute: 0);
  }

  /// استخراج أجزاء النص السويعي (السويعة، الدقيقة، والأيقونة) بدون اعتماد على Flutter
  static ({String suwayaStr, String minStr, String icon}) formatParts(
    int globalSuwayaIndex,
    int minute, {
    required bool isRTL,
    String iconMode = 'emoji',
  }) {
    final ui = globalToUiPhase(globalSuwayaIndex);
    final slotStr = ui.uiHour.toString().padLeft(2, '0');
    final minStr = minute.clamp(0, 59).toString().padLeft(2, '0');
    final String icon;
    if (iconMode == 'text') {
      icon = ui.isNight ? (isRTL ? 'ل' : 'N') : (isRTL ? 'ن' : 'D');
    } else {
      icon = ui.isNight ? '🌑' : '☀️';
    }
    return (suwayaStr: slotStr, minStr: minStr, icon: icon);
  }

  /// تنسيق السلسلة النصية للوقت السويعي (مثل: "04|30 🌑" أو "🌑 04|30")
  static String formatString(
    int globalSuwayaIndex,
    int minute, {
    String separator = '|',
    bool isRTL = true,
    String iconMode = 'emoji',
  }) {
    final parts = formatParts(
      globalSuwayaIndex,
      minute,
      isRTL: isRTL,
      iconMode: iconMode,
    );
    final timeString = '${parts.suwayaStr}$separator${parts.minStr}';
    return isRTL ? '${parts.icon} $timeString' : '$timeString ${parts.icon}';
  }
}
