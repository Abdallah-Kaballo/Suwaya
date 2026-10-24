import '../models/astro_models.dart';
import 'suwaya_recurrence_engine.dart';

class SuwayaIcsExporter {
  static String _formatIcsUtc(DateTime dtUtc) {
    final u = dtUtc.toUtc();
    final y = u.year.toString().padLeft(4, '0');
    final m = u.month.toString().padLeft(2, '0');
    final d = u.day.toString().padLeft(2, '0');
    final h = u.hour.toString().padLeft(2, '0');
    final min = u.minute.toString().padLeft(2, '0');
    final s = u.second.toString().padLeft(2, '0');
    return '$y$m${d}T$h$min${s}Z';
  }

  static String _escapeIcsText(String input) {
    return input
        .replaceAll(r'\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll('\n', r'\n');
  }

  /// توليد محتوى ملف تقويم قياسي (RFC 5545 iCalendar .ics) لنافذة أيام فلكية
  static String exportWindowsToIcs({
    required List<SuwayaScheduledDayWindow> windows,
    String calendarName = 'Suwaya Astronomical Calendar',
    bool includePeriods = true,
    bool includeQiyamParts = true,
    Map<PeriodKey, String>? localizedPeriodNames,
  }) {
    final sb = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//Suwaya//Suwaya Time Engine V2//EN')
      ..writeln('CALSCALE:GREGORIAN')
      ..writeln('METHOD:PUBLISH')
      ..writeln('X-WR-CALNAME:${_escapeIcsText(calendarName)}');

    final dtStamp = _formatIcsUtc(DateTime.now().toUtc());

    for (final window in windows) {
      if (window.dayOffset < 0) continue;
      final dateKey =
          '${window.astroLogicalDate.year}${window.astroLogicalDate.month.toString().padLeft(2, '0')}${window.astroLogicalDate.day.toString().padLeft(2, '0')}';

      if (includePeriods) {
        for (final p in window.periods) {
          final startUtc = p.startUtc ?? p.startTime.toUtc();
          final endUtc = p.endUtc ?? p.endTime.toUtc();
          final title = localizedPeriodNames?[p.periodKey] ?? p.periodKey.name;
          final uid = 'suwaya-period-$dateKey-${p.id}@suwaya.app';

          sb
            ..writeln('BEGIN:VEVENT')
            ..writeln('UID:$uid')
            ..writeln('DTSTAMP:$dtStamp')
            ..writeln('DTSTART:${_formatIcsUtc(startUtc)}')
            ..writeln('DTEND:${_formatIcsUtc(endUtc)}')
            ..writeln(
                'SUMMARY:${_escapeIcsText('$title (${p.suwayasCount} Suwayas)')}')
            ..writeln('END:VEVENT');
        }
      }

      if (includeQiyamParts) {
        for (final np in window.ibadat.nightParts) {
          if (np.startUtc == null || np.endUtc == null) continue;
          final uid = 'suwaya-qiyam-$dateKey-${np.id}@suwaya.app';
          sb
            ..writeln('BEGIN:VEVENT')
            ..writeln('UID:$uid')
            ..writeln('DTSTAMP:$dtStamp')
            ..writeln('DTSTART:${_formatIcsUtc(np.startUtc!)}')
            ..writeln('DTEND:${_formatIcsUtc(np.endUtc!)}')
            ..writeln('SUMMARY:${_escapeIcsText('Qiyam: ${np.id}')}')
            ..writeln('END:VEVENT');
        }
      }
    }

    sb.writeln('END:VCALENDAR');
    return sb.toString();
  }
}