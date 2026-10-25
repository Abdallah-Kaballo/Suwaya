import 'dart:math' as math;
import 'package:intl/intl.dart';

import '../models/astro_models.dart';
import '../models/temporal_primitives.dart';
import 'suwaya_coordinate_mapper.dart';
import 'suwaya_time_engine.dart';
import 'temporal_context_engine.dart';

/// توصيف هندسي نقي لقوس الروتين على القرص الفلكي (بدون ألوان Flutter)
class SuwayaDialArcGeometry {
  final double startAngle;
  final double sweepAngle;
  final DateTime startTime;
  final DateTime endTime;

  const SuwayaDialArcGeometry({
    required this.startAngle,
    required this.sweepAngle,
    required this.startTime,
    required this.endTime,
  });
}

/// نتيجة العد التنازلي للصلاة القادمة (سويعياً ومدنياً)
class NextPrayerCountdownSnapshot {
  final PrayerKey prayerKey;
  final String prayerId;
  final DateTime prayerTime;
  final int
  primaryUnits; // سويعات (في الوضع السويعي) أو ساعات (في الوضع المدني)
  final int secondaryUnits; // دقائق افتراضية أو دقائق مدنية
  final int totalRemainingSeconds;

  const NextPrayerCountdownSnapshot({
    required this.prayerKey,
    required this.prayerId,
    required this.prayerTime,
    required this.primaryUnits,
    required this.secondaryUnits,
    required this.totalRemainingSeconds,
  });
}

class SuwayaScheduleEngine {
  // ===========================================================================
  // 1. حسابات التواريخ المنطقية والمهام (Tasks & Logical Dates)
  // ===========================================================================

  /// حساب التاريخ المنطقي ككائن قيمة صريح (CivilDate)
  /// - السويعي: يتبع تاريخ نهاية دورة المغرب النشطة (ينقلب عند الغروب)
  /// - المدني: يتبع تاريخ الحائط المدني (ينقلب عند 00:00 منتصف الليل)
  static CivilDate resolveLogicalCivilDate({
    required bool isAstroTime,
    required AstroState astroState,
    DateTime? civilReference,
  }) {
    final civil = civilReference ?? astroState.virtualTime;
    if (isAstroTime && astroState.periods.isNotEmpty) {
      final endMaghrib = astroState.cycleAnchors.cycleEndMaghrib;
      return CivilDate(endMaghrib.year, endMaghrib.month, endMaghrib.day);
    }
    return CivilDate(civil.year, civil.month, civil.day);
  }

  /// تحويل وقت المهمة (سواء كانت سويعية أو مدنية) إلى (معرف الفترة + رقم السويعة المحلي) للترتيب والفلترة
  static ({int periodId, int localSuwaya})? resolveTaskDynamicAstroSlot({
    required bool isAstroTime,
    int? targetPeriodId,
    List<int> targetSuwayas = const [],
    CivilWallClock? targetCivilClock,
    required AstroState astroState,
  }) {
    if (isAstroTime && targetPeriodId != null) {
      return (
        periodId: targetPeriodId,
        localSuwaya: targetSuwayas.isNotEmpty ? targetSuwayas.first : 0,
      );
    }

    if (!isAstroTime &&
        targetCivilClock != null &&
        astroState.periods.isNotEmpty) {
      final pStart = astroState.periods.first.startTime;
      final pStartNoSecs = DateTime.utc(
        pStart.year,
        pStart.month,
        pStart.day,
        pStart.hour,
        pStart.minute,
      );
      DateTime dt = DateTime.utc(
        pStart.year,
        pStart.month,
        pStart.day,
        targetCivilClock.hour,
        targetCivilClock.minute,
      );

      if (dt.isBefore(pStartNoSecs)) dt = dt.add(const Duration(days: 1));
      if (dt.isAfter(astroState.periods.last.endTime)) {
        dt = dt.subtract(const Duration(days: 1));
      }
      if (dt.isBefore(pStartNoSecs)) dt = dt.add(const Duration(days: 1));

      for (final p in astroState.periods) {
        if (!dt.isBefore(p.startTime) && !dt.isAfter(p.endTime)) {
          final count = p.suwayasCount > 0 ? p.suwayasCount : 1;
          final suwayaDuration =
              p.endTime.difference(p.startTime).inMicroseconds / count;
          final elapsed = dt.difference(p.startTime).inMicroseconds;
          final sIndex = (elapsed / suwayaDuration).floor().clamp(0, count - 1);
          return (periodId: p.id, localSuwaya: sIndex + 1);
        }
      }
    }
    return null;
  }

  /// التحقق مما إذا كان وقت المهمة العابرة المرشح يقع في الماضي بالنسبة لليوم المنطقي الحالي
  static bool isCandidateTaskTimeInPast({
    required bool isAstroMode,
    required CivilDate targetDate,
    required int candidateGlobalSuwaya,
    required int candidateVirtualMinute,
    required CivilWallClock candidateCivilClock,
    required AstroState astroState,
    required DateTime cityNow,
  }) {
    final logicalToday = resolveLogicalCivilDate(
      isAstroTime: isAstroMode,
      astroState: astroState,
      civilReference: cityNow,
    );

    final targetDt = targetDate.toDateTimeUtc();
    final todayDt = logicalToday.toDateTimeUtc();

    if (targetDt.isAfter(todayDt)) return false;
    if (targetDt.isBefore(todayDt)) return true;

    if (!isAstroMode) {
      final nowClock = CivilWallClock.fromDateTime(cityNow);
      return candidateCivilClock.minutesSinceMidnight <=
          nowClock.minutesSinceMidnight;
    }

    if (astroState.periods.isEmpty) return false;
    final ct = astroState.currentSuwayaTime;
    final currentGlobalSuwaya = ct.phase.isNight
        ? (ct.phaseSlotNumber - 1)
        : (12 + ct.phaseSlotNumber - 1);
    final currentTotalVirtualMins =
        (currentGlobalSuwaya * 60) + ct.virtualMinute;
    final selectedTotalVirtualMins =
        (candidateGlobalSuwaya * 60) + candidateVirtualMinute;
    return selectedTotalVirtualMins <= currentTotalVirtualMins;
  }

  /// فحص وقوع المهمة أو الروتين في طور الليل (من المغرب إلى الشروق)
  static bool isScheduleItemInNightPhase({
    required bool isAstroTime,
    int? periodId,
    CivilWallClock? civilClock,
    required AstroState astroState,
  }) {
    if (isAstroTime && periodId != null) {
      return periodId >= 1 && periodId <= 4;
    }
    if (!isAstroTime && civilClock != null) {
      final mins = civilClock.minutesSinceMidnight;
      final sunriseMins = astroState.periods.isNotEmpty
          ? (astroState.ibadatTimings.sunrise.hour * 60 +
                astroState.ibadatTimings.sunrise.minute)
          : 360;
      final maghribMins = astroState.periods.isNotEmpty
          ? (astroState.ibadatTimings.maghrib.hour * 60 +
                astroState.ibadatTimings.maghrib.minute)
          : 1080;
      return mins >= maghribMins || mins < sunriseMins;
    }
    return false;
  }

  // ===========================================================================
  // 2. حسابات الهندسة القطبية للقرص والروتينات (Dial & Routine Geometry)
  // ===========================================================================

  /// تحويل أي وقت إلى زاوية بالراديان على القرص الفلكي (-pi/2 في الأعلى)
  static double timeToDialAngle(
    DateTime time,
    DateTime dayStart,
    DateTime dayEnd,
  ) {
    final total = dayEnd.difference(dayStart).inMicroseconds;
    if (total <= 0) return -math.pi / 2;
    return -math.pi / 2 +
        (time.difference(dayStart).inMicroseconds / total) * 2 * math.pi;
  }

  /// تحويل زاوية إفلات المهمة على القرص إلى (معرف الفترة + السويعة المحلية + الدقيقة الافتراضية)
  static ({int periodId, int localSuwaya, int virtualMinute})?
  resolveDialDropTarget({
    required double dragAngle,
    required List<AstroPeriod> periods,
  }) {
    if (periods.isEmpty) return null;
    final dayStart = periods.first.startTime;
    final dayEnd = periods.last.endTime;

    for (final period in periods) {
      double startA =
          timeToDialAngle(period.startTime, dayStart, dayEnd) % (2 * math.pi);
      double endA =
          timeToDialAngle(period.endTime, dayStart, dayEnd) % (2 * math.pi);
      if (startA < 0) startA += 2 * math.pi;
      if (endA < 0) endA += 2 * math.pi;

      final bool inside = startA < endA
          ? (dragAngle >= startA && dragAngle <= endA)
          : (dragAngle >= startA || dragAngle <= endA);

      if (inside) {
        double sweep = endA - startA;
        if (sweep < 0) sweep += 2 * math.pi;
        double relativeAngle = dragAngle - startA;
        if (relativeAngle < 0) relativeAngle += 2 * math.pi;

        final double progress = relativeAngle / sweep;
        int sIndex = (progress * period.suwayasCount).round();
        if (sIndex >= period.suwayasCount) {
          sIndex = period.suwayasCount - 1;
        }
        return (periodId: period.id, localSuwaya: sIndex + 1, virtualMinute: 0);
      }
    }
    return null;
  }

  /// حساب قوس الروتين (سواء كان سويعياً أو مدنياً) على القرص الفلكي
  static SuwayaDialArcGeometry? computeRoutineDialArc({
    required bool isAstroTime,
    int? startPeriodId,
    int? startSuwaya,
    int? startVirtualMinute,
    int? endPeriodId,
    int? endSuwaya,
    int? endVirtualMinute,
    CivilWallClock? startCivilClock,
    CivilWallClock? endCivilClock,
    required List<AstroPeriod> periods,
  }) {
    if (periods.isEmpty) return null;
    final dayStart = periods.first.startTime;
    final dayEnd = periods.last.endTime;
    final totalDayMicro = dayEnd.difference(dayStart).inMicroseconds;
    if (totalDayMicro <= 0) return null;
    final actualCycleSpan = Duration(microseconds: totalDayMicro);

    final totalSuwayas = periods.fold<int>(0, (sum, p) => sum + p.suwayasCount);
    final effectiveTotalSuwayas = totalSuwayas > 0 ? totalSuwayas : 24;

    double getAstroAngle(int globalSuwaya, int virtualMinute) {
      final normGlobal = globalSuwaya % effectiveTotalSuwayas;
      final safeMinute = virtualMinute.clamp(0, 59);

      int accumulatedSuwayas = 0;
      for (final p in periods) {
        if (normGlobal < accumulatedSuwayas + p.suwayasCount) {
          final int localSuwaya = normGlobal - accumulatedSuwayas;
          final double pStartAngle = timeToDialAngle(
            p.startTime,
            dayStart,
            dayEnd,
          );
          final double pEndAngle = timeToDialAngle(p.endTime, dayStart, dayEnd);
          double sweep = pEndAngle - pStartAngle;
          if (sweep <= 0) sweep += 2 * math.pi;

          final double anglePerSuwaya = sweep / p.suwayasCount;
          final double exactLocal = localSuwaya + (safeMinute / 60.0);
          return pStartAngle + (exactLocal * anglePerSuwaya);
        }
        accumulatedSuwayas += p.suwayasCount;
      }
      return timeToDialAngle(dayEnd, dayStart, dayEnd);
    }

    if (isAstroTime) {
      final sPId = startPeriodId ?? periods.first.id;
      final sLocal = startSuwaya ?? 1;
      final sm = (startVirtualMinute ?? 0).clamp(0, 59);

      final ePId = endPeriodId ?? periods.last.id;
      final eLocal = endSuwaya ?? 1;
      final em = (endVirtualMinute ?? 0).clamp(0, 59);

      final startGlobal = SuwayaCoordinateMapper.localToGlobal(
        sPId,
        sLocal,
        periods,
      );
      final endGlobal = SuwayaCoordinateMapper.localToGlobal(
        ePId,
        eLocal,
        periods,
      );

      final sPeriod = periods.firstWhere(
        (c) => c.id == sPId,
        orElse: () => periods.first,
      );
      final ePeriod = periods.firstWhere(
        (c) => c.id == ePId,
        orElse: () => periods.last,
      );

      final startTime = sPeriod.resolveSlotWallTime(sLocal, sm);
      var endTime = ePeriod.resolveSlotWallTime(eLocal, em);
      if (!endTime.isAfter(startTime)) {
        endTime = endTime.add(actualCycleSpan);
      }

      final startAngle = getAstroAngle(startGlobal, sm);
      final endAngle = getAstroAngle(endGlobal, em);
      var sweepAngle = endAngle - startAngle;
      if (sweepAngle <= 0) sweepAngle += 2 * math.pi;

      return SuwayaDialArcGeometry(
        startAngle: startAngle,
        sweepAngle: sweepAngle,
        startTime: startTime,
        endTime: endTime,
      );
    } else {
      if (startCivilClock == null || endCivilClock == null) return null;

      DateTime mapCivilClockToCycle(CivilWallClock clock) {
        DateTime dt = DateTime.utc(
          dayStart.year,
          dayStart.month,
          dayStart.day,
          clock.hour,
          clock.minute,
        );
        if (dt.isBefore(dayStart)) dt = dt.add(const Duration(days: 1));
        if (dt.isAfter(dayEnd)) dt = dt.subtract(const Duration(days: 1));
        if (dt.isBefore(dayStart)) dt = dt.add(const Duration(days: 1));
        return dt;
      }

      final startTime = mapCivilClockToCycle(startCivilClock);
      var endTime = mapCivilClockToCycle(endCivilClock);
      if (!endTime.isAfter(startTime)) {
        endTime = endTime.add(actualCycleSpan);
      }

      final startAngle = timeToDialAngle(startTime, dayStart, dayEnd);
      final endAngle = timeToDialAngle(endTime, dayStart, dayEnd);
      var sweepAngle = endAngle - startAngle;
      if (sweepAngle <= 0) sweepAngle += 2 * math.pi;

      return SuwayaDialArcGeometry(
        startAngle: startAngle,
        sweepAngle: sweepAngle,
        startTime: startTime,
        endTime: endTime,
      );
    }
  }

  // ===========================================================================
  // 3. حساب العد التنازلي للصلاة القادمة (Ibadat Next Prayer Countdown)
  // ===========================================================================

  static NextPrayerCountdownSnapshot computeNextPrayerCountdown({
    required AstroState astroState,
    required DateTime liveNow,
    required bool useAstroTime,
    DateTime? nowUtc,
  }) {
    final ibadat = astroState.civilDayIbadat;
    final anchors = astroState.cycleAnchors;

    final candidates = <({PrayerKey key, String id, DateTime time})>[
      (key: PrayerKey.fajr, id: 'fajr', time: ibadat.fajr),
      (key: PrayerKey.dhuhr, id: 'dhuhr', time: ibadat.dhuhr),
      (key: PrayerKey.asr, id: 'asr', time: ibadat.asr),
      (key: PrayerKey.maghrib, id: 'maghrib', time: ibadat.maghrib),
      (key: PrayerKey.isha, id: 'isha', time: ibadat.isha),
      (key: PrayerKey.fajr, id: 'fajr', time: ibadat.nextFajr),
      (key: PrayerKey.isha, id: 'isha', time: anchors.cycleIsha),
      (key: PrayerKey.fajr, id: 'fajr', time: anchors.cycleFajr),
      (key: PrayerKey.dhuhr, id: 'dhuhr', time: anchors.cycleDhuhr),
      (key: PrayerKey.asr, id: 'asr', time: anchors.cycleAsr),
      (key: PrayerKey.maghrib, id: 'maghrib', time: anchors.cycleEndMaghrib),
    ];

    var next = candidates.first;
    int minDiffSecs = 86400 * 2;
    for (final c in candidates) {
      final diffSecs = c.time.difference(liveNow).inSeconds;
      if (diffSecs > 0 && diffSecs < minDiffSecs) {
        minDiffSecs = diffSecs;
        next = c;
      }
    }

    if (useAstroTime && astroState.periods.isNotEmpty) {
      final liveAstroState = SuwayaTimeEngine.calculateCurrentState(
        SuwayaDay(
          ibadatTimings: astroState.ibadatTimings,
          civilDayIbadat: astroState.civilDayIbadat,
          cycleAnchors: astroState.cycleAnchors,
          periods: astroState.periods,
        ),
        liveNow,
        nowUtc: nowUtc,
      );
      final ct = liveAstroState.currentSuwayaTime;
      final currentGlobalIndex = ct.phase.isNight
          ? (ct.phaseSlotNumber - 1)
          : (12 + ct.phaseSlotNumber - 1);
      final currentVirtualTotalMins =
          (currentGlobalIndex * 60) + ct.virtualMinute;

      final targetAstro = SuwayaCoordinateMapper.fixedBoundaryCoordinate(
        next.id,
        astroState.periods,
        isEnd: false,
      );
      final targetVirtualTotalMins =
          (targetAstro.globalIndex * 60) + targetAstro.minute;

      int virtualRemainingMins =
          targetVirtualTotalMins - currentVirtualTotalMins;
      if (virtualRemainingMins <= 0) {
        virtualRemainingMins += 1440;
      }

      return NextPrayerCountdownSnapshot(
        prayerKey: next.key,
        prayerId: next.id,
        prayerTime: next.time,
        primaryUnits: virtualRemainingMins ~/ 60,
        secondaryUnits: virtualRemainingMins % 60,
        totalRemainingSeconds: minDiffSecs,
      );
    }

    final remainingCivilMins = (minDiffSecs / 60).ceil();
    return NextPrayerCountdownSnapshot(
      prayerKey: next.key,
      prayerId: next.id,
      prayerTime: next.time,
      primaryUnits: remainingCivilMins ~/ 60,
      secondaryUnits: remainingCivilMins % 60,
      totalRemainingSeconds: minDiffSecs,
    );
  }
}

/// منسق الأوقات القياسي داخل النواة (Pure Dart Time Formatter)
class SuwayaTimeFormatter {
  static const String civilTimeFormatSystem = 'system';
  static const String civilTimeFormat12Hour = '12-hour';
  static const String civilTimeFormat24Hour = '24-hour';

  static String _safeLocale(String locale) {
    if (locale.isEmpty || locale == 'ff' || locale == 'ug') return 'en';
    return DateFormat.localeExists(locale) ? locale : 'en';
  }

  /// تنسيق كائن القيمة الصريح CivilWallClock وفق إعدادات 12/24 ساعة واتجاه اللغة
  static String formatCivilWallClock(
    CivilWallClock clock, {
    required bool use24Hour,
    required String locale,
    required bool isRTL,
  }) {
    final safeLoc = _safeLocale(locale);
    final refDt = DateTime.utc(2000, 1, 1, clock.hour, clock.minute);

    if (use24Hour) {
      final time24 = DateFormat('HH:mm', safeLoc).format(refDt);
      return '\u202A\u200E$time24\u200E\u202C';
    }

    final timeDigits = DateFormat('h:mm', safeLoc).format(refDt);
    final periodMarker = DateFormat('a', safeLoc).format(refDt);

    if (isRTL) {
      return '\u202A\u200E$periodMarker\u200E \u200E$timeDigits\u200E\u202C';
    }
    return '\u202A\u200E$timeDigits\u200E \u200E$periodMarker\u200E\u202C';
  }

  /// تنسيق وقت الروتين المدني بنظام 24 ساعة القياسي
  static String formatCivilRoutineClock(CivilWallClock clock, String locale) {
    final safeLoc = _safeLocale(locale);
    final refDt = DateTime.utc(2000, 1, 1, clock.hour, clock.minute);
    return DateFormat('HH:mm', safeLoc).format(refDt);
  }

  /// تنسيق أيام تكرار الروتين أو العادة
  static String? formatRecurrenceDays(List<int>? days, String locale) {
    if (days == null || days.isEmpty) return null;
    final safeLoc = _safeLocale(locale);
    final monday = DateTime.utc(2024, 1, 1);
    final orderedDays =
        days.toSet().where((day) => day >= 1 && day <= 7).toList()..sort();
    return orderedDays
        .map(
          (day) => DateFormat(
            'EEE',
            safeLoc,
          ).format(monday.add(Duration(days: day - 1))),
        )
        .join(', ');
  }
}
