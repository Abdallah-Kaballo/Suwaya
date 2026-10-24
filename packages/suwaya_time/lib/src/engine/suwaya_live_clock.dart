import 'dart:async';
import '../models/astro_models.dart';
import 'suwaya_coordinate_mapper.dart';
import 'suwaya_recurrence_engine.dart';
import 'temporal_context_engine.dart';

/// 1. ساعة البث التفاعلي النقية (Pure Dart Reactive Virtual Clock)
/// تصدر تدفقاً (Stream) يتحدث تلقائياً عند بداية كل ثانية افتراضية متغيرة الطول
class SuwayaLiveClock {
  final double latitude;
  final double longitude;
  final String? timezoneId;
  final CalculationMethodType methodType;
  final MadhabType madhabType;
  final HighLatitudeRuleType highLatRuleType;
  final double customFajrAngle;
  final double customIshaAngle;
  final Map<PrayerKey, int>? manualOffsets;
  final DateTime Function() _nowUtcProvider;

  Timer? _adaptiveTimer;
  final StreamController<SuwayaTemporalContext> _tickController =
      StreamController<SuwayaTemporalContext>.broadcast();

  SuwayaLiveClock({
    required this.latitude,
    required this.longitude,
    this.timezoneId,
    this.methodType = CalculationMethodType.muslimWorldLeague,
    this.madhabType = MadhabType.shafi,
    this.highLatRuleType = HighLatitudeRuleType.middleOfTheNight,
    this.customFajrAngle = 18.0,
    this.customIshaAngle = 18.0,
    this.manualOffsets,
    DateTime Function()? nowUtcProvider,
  }) : _nowUtcProvider = nowUtcProvider ?? (() => DateTime.now().toUtc());

  /// تدفق حي يصدر السياق الزمني الكامل عند بداية كل ثانية افتراضية
  Stream<SuwayaTemporalContext> get stream => _tickController.stream;

  void start() {
    _scheduleNextVirtualSecond();
  }

  void stop() {
    _adaptiveTimer?.cancel();
    _adaptiveTimer = null;
  }

  Future<void> dispose() async {
    stop();
    await _tickController.close();
  }

  void _scheduleNextVirtualSecond() {
    _adaptiveTimer?.cancel();
    if (_tickController.isClosed) return;

    final nowUtc = _nowUtcProvider().toUtc();
    final ctx = TemporalContextEngine.evaluate(
      instantUtc: nowUtc,
      latitude: latitude,
      longitude: longitude,
      timezoneId: timezoneId,
      methodType: methodType,
      madhabType: madhabType,
      highLatRuleType: highLatRuleType,
      customFajrAngle: customFajrAngle,
      customIshaAngle: customIshaAngle,
      manualOffsets: manualOffsets,
    );

    if (!_tickController.isClosed) {
      _tickController.add(ctx);
    }

    final activePeriod = ctx.astroState.currentPeriod;
    final sCount =
        activePeriod.suwayasCount > 0 ? activePeriod.suwayasCount : 1;
    final periodMicro = activePeriod.totalDuration.inMicroseconds;

    Duration nextDelay;
    if (periodMicro > 0 && activePeriod.startUtc != null) {
      final totalVirtualSecs = sCount * 3600;
      final elapsedMicro =
          nowUtc.difference(activePeriod.startUtc!).inMicroseconds;
      final nextVirtualSecIdx =
          ((elapsedMicro * totalVirtualSecs) ~/ periodMicro) + 1;
      final nextBoundaryMicro =
          (nextVirtualSecIdx * periodMicro + totalVirtualSecs - 1) ~/
              totalVirtualSecs;
      final remMicro = nextBoundaryMicro - elapsedMicro;
      nextDelay = Duration(microseconds: remMicro.clamp(50000, 2000000));
    } else {
      nextDelay = Duration(milliseconds: 1000 - (nowUtc.millisecond % 1000));
    }

    _adaptiveTimer = Timer(nextDelay, _scheduleNextVirtualSecond);
  }
}

/// 2. مُصدّر تقويم iCalendar القياسي (RFC 5545 .ics Exporter)
/// يتيح تصدير الفترات السبع وأجزاء قيام الليل إلى Google Calendar و Apple Calendar و Outlook
class SuwayaIcsExporter {
  static String _formatIcsUtc(DateTime utc) {
    final u = utc.toUtc();
    final y = u.year.toString().padLeft(4, '0');
    final m = u.month.toString().padLeft(2, '0');
    final d = u.day.toString().padLeft(2, '0');
    final h = u.hour.toString().padLeft(2, '0');
    final min = u.minute.toString().padLeft(2, '0');
    final s = u.second.toString().padLeft(2, '0');
    return '$y$m${d}T$h$min${s}Z';
  }

  /// توليد محتوى ملف .ics قياسي من قائمة نوافذ الأيام الفلكية
  static String exportWindowsToIcs(
    List<SuwayaScheduledDayWindow> windows, {
    String calendarName = 'Suwaya Astronomical Calendar',
    bool includePeriods = true,
    bool includeQiyamParts = true,
  }) {
    final nowStamp = _formatIcsUtc(DateTime.now().toUtc());
    final sb = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//Suwaya//Suwaya Time Engine V2//EN')
      ..writeln('CALSCALE:GREGORIAN')
      ..writeln('METHOD:PUBLISH')
      ..writeln('X-WR-CALNAME:$calendarName');

    for (final w in windows) {
      if (includePeriods) {
        int globalOffset = 0;
        for (final p in w.periods) {
          final startUtc = p.startUtc ?? p.startTime.toUtc();
          final endUtc = p.endUtc ?? p.endTime.toUtc();
          final startCoord = SuwayaCoordinateMapper.formatString(
            globalOffset,
            0,
            isRTL: false,
          );
          final uid =
              'suwaya-period-${w.astroLogicalDate.year}${w.astroLogicalDate.month}${w.astroLogicalDate.day}-p${p.id}@suwaya.app';

          sb
            ..writeln('BEGIN:VEVENT')
            ..writeln('UID:$uid')
            ..writeln('DTSTAMP:$nowStamp')
            ..writeln('DTSTART:${_formatIcsUtc(startUtc)}')
            ..writeln('DTEND:${_formatIcsUtc(endUtc)}')
            ..writeln(
              'SUMMARY:Period ${p.id} (${p.periodKey.name}) - ${p.suwayasCount} Suwayas',
            )
            ..writeln(
              'DESCRIPTION:Starts at $startCoord | Suwayas: ${p.suwayasCount}',
            )
            ..writeln('END:VEVENT');

          globalOffset += p.suwayasCount;
        }
      }

      if (includeQiyamParts) {
        for (final np in w.ibadat.nightParts) {
          if (np.startUtc == null || np.endUtc == null) continue;
          final uid =
              'suwaya-qiyam-${w.astroLogicalDate.year}${w.astroLogicalDate.month}${w.astroLogicalDate.day}-${np.id}@suwaya.app';
          sb
            ..writeln('BEGIN:VEVENT')
            ..writeln('UID:$uid')
            ..writeln('DTSTAMP:$nowStamp')
            ..writeln('DTSTART:${_formatIcsUtc(np.startUtc!)}')
            ..writeln('DTEND:${_formatIcsUtc(np.endUtc!)}')
            ..writeln('SUMMARY:Qiyam - ${np.id}')
            ..writeln('END:VEVENT');
        }
      }
    }

    sb.writeln('END:VCALENDAR');
    return sb.toString();
  }
}