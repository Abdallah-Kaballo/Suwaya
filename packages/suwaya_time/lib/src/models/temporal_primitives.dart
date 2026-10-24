import 'astro_models.dart';
import '../engine/temporal_context_engine.dart';
import '../engine/suwaya_coordinate_mapper.dart';

/// 1. اللحظة الكونية المطلقة (InstantUtc)
class InstantUtc implements Comparable<InstantUtc> {
  final int epochMicroseconds;

  const InstantUtc.fromMicroseconds(this.epochMicroseconds);

  factory InstantUtc.fromDateTime(DateTime dateTime) {
    return InstantUtc.fromMicroseconds(
      dateTime.toUtc().microsecondsSinceEpoch,
    );
  }

  factory InstantUtc.now() => InstantUtc.fromDateTime(DateTime.now().toUtc());

  DateTime toDateTimeUtc() =>
      DateTime.fromMicrosecondsSinceEpoch(epochMicroseconds, isUtc: true);

  InstantUtc add(Duration duration) =>
      InstantUtc.fromMicroseconds(epochMicroseconds + duration.inMicroseconds);

  InstantUtc subtract(Duration duration) =>
      InstantUtc.fromMicroseconds(epochMicroseconds - duration.inMicroseconds);

  Duration difference(InstantUtc other) =>
      Duration(microseconds: epochMicroseconds - other.epochMicroseconds);

  bool isBefore(InstantUtc other) =>
      epochMicroseconds < other.epochMicroseconds;

  bool isAfter(InstantUtc other) => epochMicroseconds > other.epochMicroseconds;

  bool isAtSameMomentAs(InstantUtc other) =>
      epochMicroseconds == other.epochMicroseconds;

  String toIso8601String() => toDateTimeUtc().toIso8601String();

  Map<String, dynamic> toJson() => {
        'epochMicroseconds': epochMicroseconds,
        'iso8601Utc': toIso8601String(),
      };

  factory InstantUtc.fromJson(Map<String, dynamic> json) {
    if (json['epochMicroseconds'] is int) {
      return InstantUtc.fromMicroseconds(json['epochMicroseconds'] as int);
    }
    return InstantUtc.fromDateTime(
      DateTime.parse(json['iso8601Utc'] as String),
    );
  }

  @override
  int compareTo(InstantUtc other) =>
      epochMicroseconds.compareTo(other.epochMicroseconds);

  @override
  bool operator ==(Object other) =>
      other is InstantUtc && epochMicroseconds == other.epochMicroseconds;

  @override
  int get hashCode => epochMicroseconds.hashCode;

  @override
  String toString() => toIso8601String();
}

/// كائن قيمة غير قابل للتغيير (Immutable Value Object) يمثل وقت الحائط المدني المجرد (ساعة، دقيقة، ثانية)
/// يقضي نهائياً على استخدام DateTime(2000, 1, 1, h, m) أو الدقائق الخام في الواجهة
class CivilWallClock implements Comparable<CivilWallClock> {
  final int hour; // 0..23
  final int minute; // 0..59
  final int second; // 0..59

  const CivilWallClock({
    required int hour,
    required int minute,
    int second = 0,
  })  : hour = hour < 0 ? 0 : (hour > 23 ? 23 : hour),
        minute = minute < 0 ? 0 : (minute > 59 ? 59 : minute),
        second = second < 0 ? 0 : (second > 59 ? 59 : second);

  factory CivilWallClock.fromMinutesSinceMidnight(int totalMinutes) {
    final normalized = ((totalMinutes % 1440) + 1440) % 1440;
    return CivilWallClock(
      hour: normalized ~/ 60,
      minute: normalized % 60,
    );
  }

  factory CivilWallClock.fromZonedWallTime(ZonedWallTime zwt) {
    return CivilWallClock(
      hour: zwt.hour,
      minute: zwt.minute,
      second: zwt.second,
    );
  }

  /// جسر توافق لتحويل DateTime إلى CivilWallClock عند الحاجة
  factory CivilWallClock.fromDateTime(DateTime dt) {
    return CivilWallClock(
      hour: dt.hour,
      minute: dt.minute,
      second: dt.second,
    );
  }

  int get minutesSinceMidnight => (hour * 60) + minute;
  int get secondsSinceMidnight => (hour * 3600) + (minute * 60) + second;

  ({int hour12, int minute, bool isPm}) get to12HourParts {
    final isPm = hour >= 12;
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return (hour12: h12, minute: minute, isPm: isPm);
  }

  String format24Hour({bool includeSeconds = false}) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    if (!includeSeconds) return '$h:$m';
    final s = second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String format12Hour({
    required String amMarker,
    required String pmMarker,
    required bool isRTL,
  }) {
    final parts = to12HourParts;
    final digits = '${parts.hour12}:${parts.minute.toString().padLeft(2, '0')}';
    final marker = parts.isPm ? pmMarker : amMarker;
    if (isRTL) {
      return '\u202A\u200E$marker\u200E \u200E$digits\u200E\u202C';
    }
    return '\u202A\u200E$digits\u200E \u200E$marker\u200E\u202C';
  }

  @override
  int compareTo(CivilWallClock other) =>
      secondsSinceMidnight.compareTo(other.secondsSinceMidnight);

  bool isBefore(CivilWallClock other) => compareTo(other) < 0;
  bool isAfter(CivilWallClock other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) =>
      other is CivilWallClock &&
      hour == other.hour &&
      minute == other.minute &&
      second == other.second;

  @override
  int get hashCode => Object.hash(hour, minute, second);

  @override
  String toString() => format24Hour(includeSeconds: second != 0);
}

/// 2. وقت الحائط المقترن بمنطقته الزمنية ولحظته الكونية (ZonedWallTime)
class ZonedWallTime implements Comparable<ZonedWallTime> {
  final InstantUtc instant;
  final Duration utcOffset;
  final String? timezoneId;
  final bool isDaylightSavingTime;

  const ZonedWallTime({
    required this.instant,
    required this.utcOffset,
    this.timezoneId,
    this.isDaylightSavingTime = false,
  });

  factory ZonedWallTime.fromInstant(
    InstantUtc instant, {
    String? timezoneId,
    Duration? fallbackOffset,
  }) {
    final tzCtx = TimezoneResolver.resolveForInstant(
      instant.toDateTimeUtc(),
      timezoneId: timezoneId,
      fallbackOffset: fallbackOffset,
    );
    return ZonedWallTime(
      instant: instant,
      utcOffset: tzCtx.utcOffset,
      timezoneId: tzCtx.timezoneId,
      isDaylightSavingTime: tzCtx.isDaylightSavingTime,
    );
  }

  /// إنشاء ZonedWallTime من تاريخ مدني ووقت حائط محلي في منطقة زمنية محددة
  factory ZonedWallTime.fromCivilDateAndClock({
    required CivilDate date,
    required CivilWallClock clock,
    String? timezoneId,
    Duration? fallbackOffset,
  }) {
    final approxUtc = DateTime.utc(
      date.year,
      date.month,
      date.day,
      clock.hour,
      clock.minute,
      clock.second,
    );
    final initialOffset = TimezoneResolver.resolveForInstant(
      approxUtc,
      timezoneId: timezoneId,
      fallbackOffset: fallbackOffset,
    ).utcOffset;
    final refinedUtc = approxUtc.subtract(initialOffset);
    return ZonedWallTime.fromInstant(
      InstantUtc.fromDateTime(refinedUtc),
      timezoneId: timezoneId,
      fallbackOffset: fallbackOffset,
    );
  }

  DateTime get _wallProjection => instant.toDateTimeUtc().add(utcOffset);

  /// يبقى للتوافق العكسي مع الاختبارات القديمة فقط
  DateTime get wallClockProjection => _wallProjection;

  int get year => _wallProjection.year;
  int get month => _wallProjection.month;
  int get day => _wallProjection.day;
  int get hour => _wallProjection.hour;
  int get minute => _wallProjection.minute;
  int get second => _wallProjection.second;
  int get weekday => _wallProjection.weekday;

  CivilDate get civilDate => CivilDate(year, month, day);
  CivilWallClock get wallClock =>
      CivilWallClock(hour: hour, minute: minute, second: second);

  /// يضمن تثبيت بداية الدقيقة (تصفير الثواني والمايكروثواني) ككائن غير قابل للتغيير
  ZonedWallTime truncateToMinute() {
    final excessMicro = (second * Duration.microsecondsPerSecond) +
        (instant.epochMicroseconds % Duration.microsecondsPerSecond);
    return ZonedWallTime(
      instant: InstantUtc.fromMicroseconds(
        instant.epochMicroseconds - excessMicro,
      ),
      utcOffset: utcOffset,
      timezoneId: timezoneId,
      isDaylightSavingTime: isDaylightSavingTime,
    );
  }

  ZonedWallTime addRealDuration(Duration duration) {
    return ZonedWallTime.fromInstant(
      instant.add(duration),
      timezoneId: timezoneId,
      fallbackOffset: utcOffset,
    );
  }

  Duration realDifference(ZonedWallTime other) =>
      instant.difference(other.instant);

  bool isBefore(ZonedWallTime other) => instant.isBefore(other.instant);
  bool isAfter(ZonedWallTime other) => instant.isAfter(other.instant);
  bool isAtSameMomentAs(ZonedWallTime other) =>
      instant.isAtSameMomentAs(other.instant);

  Map<String, dynamic> toJson() => {
        'instantUtc': instant.toIso8601String(),
        'epochMicroseconds': instant.epochMicroseconds,
        'utcOffsetSeconds': utcOffset.inSeconds,
        'timezoneId': timezoneId,
        'isDst': isDaylightSavingTime,
        'wallClock':
            '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}T'
                '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}',
      };

  @override
  int compareTo(ZonedWallTime other) => instant.compareTo(other.instant);

  @override
  bool operator ==(Object other) =>
      other is ZonedWallTime &&
      instant == other.instant &&
      utcOffset == other.utcOffset &&
      timezoneId == other.timezoneId;

  @override
  int get hashCode => Object.hash(instant, utcOffset, timezoneId);
}

/// 3. الإحداثي الزمني السُويعي الموحد (SuwayaCoordinate)
class SuwayaCoordinate implements Comparable<SuwayaCoordinate> {
  final int globalSlotIndex;
  final SuwayaPhase phase;
  final int phaseSlotNumber;
  final int periodId;
  final PeriodKey periodKey;
  final int periodLocalSlotNumber;
  final int virtualMinute;
  final int virtualSecond;
  final double slotProgress;

  const SuwayaCoordinate({
    required this.globalSlotIndex,
    required this.phase,
    required this.phaseSlotNumber,
    required this.periodId,
    required this.periodKey,
    required this.periodLocalSlotNumber,
    required this.virtualMinute,
    this.virtualSecond = 0,
    required this.slotProgress,
  });

  int get totalVirtualMinutes => (globalSlotIndex * 60) + virtualMinute;

  int get totalVirtualSeconds =>
      (globalSlotIndex * 3600) + (virtualMinute * 60) + virtualSecond;

  /// صيغة قياسية مقترحة للـ APIs (مثال: SWY-N04:15 أو SWY-D09:42:10)
  String toIsoSuwayaString({bool includeSeconds = false}) {
    final phaseChar = phase.isNight ? 'N' : 'D';
    final s = phaseSlotNumber.toString().padLeft(2, '0');
    final m = virtualMinute.toString().padLeft(2, '0');
    if (!includeSeconds) return 'SWY-$phaseChar$s:$m';
    final sec = virtualSecond.toString().padLeft(2, '0');
    return 'SWY-$phaseChar$s:$m:$sec';
  }

  /// تحليل صيغة ISO-Suwaya القياسية (مثل "SWY-N04:15" أو "SWY-D09:42:10")
  static SuwayaCoordinate? tryParseIsoSuwaya(
    String input,
    List<AstroPeriod> periods,
  ) {
    final reg = RegExp(
      r'^SWY-([ND])(\d{2}):(\d{2})(?::(\d{2}))?$',
      caseSensitive: false,
    );
    final match = reg.firstMatch(input.trim());
    if (match == null) return null;

    final isNight = match.group(1)!.toUpperCase() == 'N';
    final slotNum = int.tryParse(match.group(2)!) ?? 1;
    final vMin = int.tryParse(match.group(3)!) ?? 0;
    final vSec =
        match.group(4) != null ? (int.tryParse(match.group(4)!) ?? 0) : 0;

    if (slotNum < 1 ||
        slotNum > 12 ||
        vMin < 0 ||
        vMin > 59 ||
        vSec < 0 ||
        vSec > 59) {
      return null;
    }

    final globalIdx = SuwayaCoordinateMapper.uiPhaseToGlobal(slotNum, isNight);
    final local = SuwayaCoordinateMapper.globalToLocal(globalIdx, periods);
    final progress = ((vMin * 60) + vSec) / 3600.0;

    return SuwayaCoordinate(
      globalSlotIndex: globalIdx,
      phase: isNight ? SuwayaPhase.night : SuwayaPhase.day,
      phaseSlotNumber: slotNum,
      periodId: local.periodId,
      periodKey: local.periodKey,
      periodLocalSlotNumber: local.localSuwaya,
      virtualMinute: vMin,
      virtualSecond: vSec,
      slotProgress: progress,
    );
  }

  /// ضغط الإحداثي السويعي مع التاريخ في عدد صحيح واحد (64-bit Integer) للفهرسة الفائقة في قواعد البيانات
  /// التوزيع البتي: [Year: 14 bits][Month: 4 bits][Day: 5 bits][GlobalSlot: 5 bits][PeriodId: 4 bits][LocalSlot: 4 bits][VMin: 6 bits][VSec: 6 bits]
  int toPackedInt64({
    int cycleYear = 1448,
    int cycleMonth = 1,
    int cycleDay = 1,
  }) {
    final y = cycleYear.clamp(0, 16383);
    final m = cycleMonth.clamp(1, 12);
    final d = cycleDay.clamp(1, 31);
    final g = globalSlotIndex.clamp(0, 23);
    final p = periodId.clamp(1, 7);
    final l = periodLocalSlotNumber.clamp(1, 12);
    final vm = virtualMinute.clamp(0, 59);
    final vs = virtualSecond.clamp(0, 59);

    return (y << 34) |
        (m << 30) |
        (d << 25) |
        (g << 20) |
        (p << 16) |
        (l << 12) |
        (vm << 6) |
        vs;
  }

  /// فك ضغط العدد الصحيح (64-bit Integer) إلى مكونات الإحداثي السويعي
  static ({
    int cycleYear,
    int cycleMonth,
    int cycleDay,
    int globalSlotIndex,
    int periodId,
    int periodLocalSlotNumber,
    int virtualMinute,
    int virtualSecond,
  }) unpackInt64(int packed) {
    final vs = packed & 0x3F;
    final vm = (packed >> 6) & 0x3F;
    final l = (packed >> 12) & 0x0F;
    final p = (packed >> 16) & 0x0F;
    final g = (packed >> 20) & 0x1F;
    final d = (packed >> 25) & 0x1F;
    final m = (packed >> 30) & 0x0F;
    final y = (packed >> 34) & 0x3FFF;

    return (
      cycleYear: y,
      cycleMonth: m,
      cycleDay: d,
      globalSlotIndex: g,
      periodId: p,
      periodLocalSlotNumber: l,
      virtualMinute: vm,
      virtualSecond: vs,
    );
  }

  Map<String, dynamic> toJson() => {
        'globalSlotIndex': globalSlotIndex,
        'phase': phase.name,
        'phaseSlotNumber': phaseSlotNumber,
        'periodId': periodId,
        'periodKey': periodKey.name,
        'periodLocalSlotNumber': periodLocalSlotNumber,
        'virtualMinute': virtualMinute,
        'virtualSecond': virtualSecond,
        'slotProgress': slotProgress,
        'totalVirtualMinutes': totalVirtualMinutes,
        'isoSuwaya': toIsoSuwayaString(includeSeconds: true),
        'packedInt64': toPackedInt64(),
      };

  @override
  int compareTo(SuwayaCoordinate other) =>
      totalVirtualSeconds.compareTo(other.totalVirtualSeconds);

  bool isBefore(SuwayaCoordinate other) => compareTo(other) < 0;
  bool isAfter(SuwayaCoordinate other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) =>
      other is SuwayaCoordinate &&
      globalSlotIndex == other.globalSlotIndex &&
      periodId == other.periodId &&
      periodLocalSlotNumber == other.periodLocalSlotNumber &&
      virtualMinute == other.virtualMinute &&
      virtualSecond == other.virtualSecond;

  @override
  int get hashCode => Object.hash(
        globalSlotIndex,
        periodId,
        periodLocalSlotNumber,
        virtualMinute,
        virtualSecond,
      );
}
