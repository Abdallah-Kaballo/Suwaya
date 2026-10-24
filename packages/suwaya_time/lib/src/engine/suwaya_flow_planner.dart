import 'dart:math' as math;
import 'package:suwaya_time/suwaya_time.dart';

/// خيار سرعة التدفق للبومودورو السُويعي
class SuwayaFlowOption {
  final int pomodoroCount;
  final double flowSpeed;
  final String tag; // 'recommended' | 'slower' | 'faster'

  const SuwayaFlowOption({
    required this.pomodoroCount,
    required this.flowSpeed,
    required this.tag,
  });

  Map<String, dynamic> toJson() => {
        'pomodoroCount': pomodoroCount,
        'flowSpeed': flowSpeed,
        'tag': tag,
      };
}

/// لقطة حية لحالة جلسة البومودورو السُويعي عند أي لحظة زمنية
class SuwayaFlowLiveSnapshot {
  final bool isFinished;
  final bool isBreak;
  final int currentCycle;
  final int totalCycles;
  final double remainingVirtualSeconds;
  final double phaseProgress;
  final double cycleProgress;
  final double focusRatio;
  final bool isPrePrayerWarningActive;

  const SuwayaFlowLiveSnapshot({
    required this.isFinished,
    required this.isBreak,
    required this.currentCycle,
    required this.totalCycles,
    required this.remainingVirtualSeconds,
    required this.phaseProgress,
    required this.cycleProgress,
    required this.focusRatio,
    required this.isPrePrayerWarningActive,
  });
}

enum SuwayaFlowValidationError {
  none,
  endBeforeStart,
  tooShort,
  exceedsMaxHours,
}

class SuwayaFlowPlanner {
  static ({
    bool isValid,
    SuwayaFlowValidationError error,
    int actualMinutes,
  }) validateSessionWindow({
    required DateTime anchoredStart,
    required DateTime candidateEnd,
    int minDurationMinutes = 15,
    int maxDurationMinutes = 720,
  }) {
    if (!candidateEnd.isAfter(anchoredStart)) {
      return (
        isValid: false,
        error: SuwayaFlowValidationError.endBeforeStart,
        actualMinutes: 0,
      );
    }
    final actualMins = candidateEnd.difference(anchoredStart).inMinutes;
    if (actualMins < minDurationMinutes) {
      return (
        isValid: false,
        error: SuwayaFlowValidationError.tooShort,
        actualMinutes: actualMins,
      );
    }
    if (actualMins > maxDurationMinutes) {
      return (
        isValid: false,
        error: SuwayaFlowValidationError.exceedsMaxHours,
        actualMinutes: actualMins,
      );
    }
    return (
      isValid: true,
      error: SuwayaFlowValidationError.none,
      actualMinutes: actualMins,
    );
  }

  /// تحويل أي وقت إلى إحداثيات سويعية (فهرس عالمي 0..23 + دقيقة افتراضية 0..59)
  static ({int globalIndex, int minute}) dateTimeToAstroParts(
    DateTime time,
    AstroState astroState,
  ) {
    if (astroState.periods.isEmpty) return (globalIndex: 0, minute: 0);
    final anchors = astroState.cycleAnchors;
    final cycleDuration =
        anchors.cycleEndMaghrib.difference(anchors.cycleStartMaghrib);

    if (time.isAtSameMomentAs(anchors.cycleEndMaghrib)) {
      return (globalIndex: 0, minute: 0);
    }

    DateTime evalTime = time;
    if (evalTime.isAfter(anchors.cycleEndMaghrib) &&
        cycleDuration.inMinutes > 0) {
      evalTime = evalTime.subtract(cycleDuration);
    }

    final coord = SuwayaCoordinateMapper.instantToCoordinate(
      day: SuwayaDay(
        ibadatTimings: astroState.ibadatTimings,
        cycleAnchors: astroState.cycleAnchors,
        periods: astroState.periods,
      ),
      instant: evalTime,
    );
    return (
      globalIndex: coord.globalSlotIndex.clamp(0, 23),
      minute: coord.virtualMinute.clamp(0, 59),
    );
  }

  /// تحويل الإحداثي السويعي المختار إلى وقت مستقبلي بعد نقطة البداية المثبتة
  static DateTime astroPartsToDateTime({
    required int globalIndex,
    required int virtualMinute,
    required DateTime anchoredStartTime,
    required AstroState astroState,
  }) {
    final mapped = SuwayaCoordinateMapper.globalToLocal(
      globalIndex.clamp(0, 23),
      astroState.periods,
    );
    final targetPeriod = astroState.periods.firstWhere(
      (p) => p.id == mapped.periodId,
      orElse: () => astroState.periods.last,
    );

    DateTime resolved = targetPeriod.resolveSlotWallTime(
      mapped.localSuwaya,
      virtualMinute.clamp(0, 59),
    );

    if (!resolved.isAfter(anchoredStartTime)) {
      final cycleDuration = astroState.cycleAnchors.cycleEndMaghrib
          .difference(astroState.cycleAnchors.cycleStartMaghrib);
      resolved = resolved.add(
        cycleDuration.inMinutes > 0 ? cycleDuration : const Duration(days: 1),
      );
    }
    return resolved;
  }

  /// حساب خيارات البومودورو السويعي المتاحة بين وقت البداية ووقت النهاية (الأقرب لـ 1.00x أولاً)
  static List<SuwayaFlowOption> calculateFlowOptions(
    DateTime startTime,
    DateTime endTime, {
    int minDurationMinutes = 15,
    int maxPomodoros = 48,
    double minSpeed = 0.5,
    double maxSpeed = 2.0,
    int virtualCycleSeconds = 1800,
  }) {
    final totalActualSeconds = endTime.difference(startTime).inSeconds;
    if (totalActualSeconds < minDurationMinutes * 60) return const [];

    final List<({int n, double v})> valid = [];
    for (int n = 1; n <= maxPomodoros; n++) {
      final double v = (n * virtualCycleSeconds) / totalActualSeconds;
      if (v >= minSpeed && v <= maxSpeed) {
        valid.add((n: n, v: v));
      }
    }

    if (valid.isEmpty) return const [];

    int bestIdx = 0;
    double minDiff = (valid[0].v - 1.0).abs();
    for (int i = 1; i < valid.length; i++) {
      final diff = (valid[i].v - 1.0).abs();
      if (diff < minDiff) {
        minDiff = diff;
        bestIdx = i;
      }
    }

    final List<SuwayaFlowOption> result = [
      SuwayaFlowOption(
        pomodoroCount: valid[bestIdx].n,
        flowSpeed: valid[bestIdx].v,
        tag: 'recommended',
      ),
    ];

    if (bestIdx - 1 >= 0) {
      result.add(
        SuwayaFlowOption(
          pomodoroCount: valid[bestIdx - 1].n,
          flowSpeed: valid[bestIdx - 1].v,
          tag: 'slower',
        ),
      );
    }

    if (bestIdx + 1 < valid.length) {
      result.add(
        SuwayaFlowOption(
          pomodoroCount: valid[bestIdx + 1].n,
          flowSpeed: valid[bestIdx + 1].v,
          tag: 'faster',
        ),
      );
    }

    return result;
  }

  /// تحديد الصلاة المفروضة القادمة في الدورة الفلكية الحالية لاستخدامها كمرساة توقف افتراضية
  static ({PrayerKey prayerKey, DateTime time}) resolveNextCyclePrayer({
    required SuwayaCycleAnchors anchors,
    required DateTime referenceTime,
  }) {
    final ordered = <({PrayerKey prayerKey, DateTime time})>[
      (prayerKey: PrayerKey.isha, time: anchors.cycleIsha),
      (prayerKey: PrayerKey.fajr, time: anchors.cycleFajr),
      (prayerKey: PrayerKey.dhuhr, time: anchors.cycleDhuhr),
      (prayerKey: PrayerKey.asr, time: anchors.cycleAsr),
      (prayerKey: PrayerKey.maghrib, time: anchors.cycleEndMaghrib),
    ];

    for (final item in ordered) {
      if (item.time.isAfter(referenceTime)) {
        return item;
      }
    }

    final cycleSpan =
        anchors.cycleEndMaghrib.difference(anchors.cycleStartMaghrib);
    return (
      prayerKey: PrayerKey.isha,
      time: anchors.cycleIsha.add(
        cycleSpan.inMinutes > 0 ? cycleSpan : const Duration(days: 1),
      ),
    );
  }

  /// تقييم الحالة الحية لجلسة البومودورو السويعي بدقة الثانية العالمية
  static SuwayaFlowLiveSnapshot evaluateLiveSession({
    required DateTime anchoredStartUtc,
    required DateTime endUtc,
    required DateTime nowUtc,
    required int totalPomodoros,
    required double flowSpeed,
    int workVirtualMinutes = 25,
    int breakVirtualMinutes = 5,
    int prePrayerWarningSeconds = 120,
  }) {
    final double focusVirtualSecs = workVirtualMinutes * 60.0;
    final double breakVirtualSecs = breakVirtualMinutes * 60.0;
    final double cycleTotalVirtualSecs = focusVirtualSecs + breakVirtualSecs;
    final double ratio = cycleTotalVirtualSecs > 0
        ? (focusVirtualSecs / cycleTotalVirtualSecs)
        : (25.0 / 30.0);

    if (!nowUtc.isBefore(endUtc)) {
      return SuwayaFlowLiveSnapshot(
        isFinished: true,
        isBreak: false,
        currentCycle: totalPomodoros,
        totalCycles: totalPomodoros,
        remainingVirtualSeconds: 0,
        phaseProgress: 1.0,
        cycleProgress: 1.0,
        focusRatio: ratio,
        isPrePrayerWarningActive: false,
      );
    }

    final int realSecondsToEnd = endUtc.difference(nowUtc).inSeconds;
    final bool isNearPrayer =
        realSecondsToEnd <= prePrayerWarningSeconds && realSecondsToEnd > 0;

    final int actualElapsedSecs =
        math.max(0, nowUtc.difference(anchoredStartUtc).inSeconds);
    final double totalVirtualElapsed = actualElapsedSecs * flowSpeed;
    final double sessionMaxVirtualSecs = totalPomodoros * cycleTotalVirtualSecs;

    if (totalVirtualElapsed >= sessionMaxVirtualSecs) {
      return SuwayaFlowLiveSnapshot(
        isFinished: true,
        isBreak: false,
        currentCycle: totalPomodoros,
        totalCycles: totalPomodoros,
        remainingVirtualSeconds: 0,
        phaseProgress: 1.0,
        cycleProgress: 1.0,
        focusRatio: ratio,
        isPrePrayerWarningActive: false,
      );
    }

    final int currentPomoIndex =
        (totalVirtualElapsed ~/ cycleTotalVirtualSecs).clamp(
      0,
      totalPomodoros - 1,
    );
    final int currentCycleNumber = currentPomoIndex + 1;
    final double elapsedInCurrentPomo =
        totalVirtualElapsed % cycleTotalVirtualSecs;

    final bool inBreak = elapsedInCurrentPomo >= focusVirtualSecs;
    double remainingVirtual;
    double progress;

    if (!inBreak) {
      remainingVirtual = focusVirtualSecs - elapsedInCurrentPomo;
      progress = focusVirtualSecs > 0
          ? (elapsedInCurrentPomo / focusVirtualSecs).clamp(0.0, 1.0)
          : 0.0;
    } else {
      final double breakElapsed = elapsedInCurrentPomo - focusVirtualSecs;
      remainingVirtual = breakVirtualSecs - breakElapsed;
      progress = breakVirtualSecs > 0
          ? (breakElapsed / breakVirtualSecs).clamp(0.0, 1.0)
          : 0.0;
    }

    if (remainingVirtual < 0) remainingVirtual = 0;

    final double cycProgress =
        (elapsedInCurrentPomo / cycleTotalVirtualSecs).clamp(0.0, 1.0);

    return SuwayaFlowLiveSnapshot(
      isFinished: false,
      isBreak: inBreak,
      currentCycle: currentCycleNumber,
      totalCycles: totalPomodoros,
      remainingVirtualSeconds: remainingVirtual,
      phaseProgress: progress,
      cycleProgress: cycProgress,
      focusRatio: ratio,
      isPrePrayerWarningActive: isNearPrayer,
    );
  }
}
