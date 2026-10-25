import 'dart:convert';
import '../models/astro_models.dart';
import 'suwaya_coordinate_mapper.dart';
import 'suwaya_recurrence_engine.dart';

class SuwayaIcsExporter {
  static const String _crlf = '\r\n';
  static const int _maxLineOctets = 75;

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
        .replaceAll('\r\n', r'\n')
        .replaceAll('\r', r'\n')
        .replaceAll('\n', r'\n')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,');
  }

  /// طي الأسطر التي تتجاوز 75 بايت (Octets) وفق القسم 3.1 من معيار RFC 5545
  /// مع ضمان عدم شطر أي حرف UTF-8 متعدد البايتات (مثل الحروف العربية)
  static void _writeFoldedLine(StringBuffer sb, String line) {
    final fullBytes = utf8.encode(line);
    if (fullBytes.length <= _maxLineOctets) {
      sb.write(line);
      sb.write(_crlf);
      return;
    }

    int currentOctetCount = 0;
    int maxCurrentLine = _maxLineOctets;
    final lineBuffer = StringBuffer();

    for (final rune in line.runes) {
      final charStr = String.fromCharCode(rune);
      final charOctets = utf8.encode(charStr).length;

      if (currentOctetCount + charOctets > maxCurrentLine) {
        sb.write(lineBuffer.toString());
        sb.write(_crlf);
        sb.write(' '); // مسافة البداية للسطر المطوي (تستهلك 1 بايت)
        lineBuffer.clear();
        currentOctetCount = 1;
        maxCurrentLine = _maxLineOctets;
      }

      lineBuffer.write(charStr);
      currentOctetCount += charOctets;
    }

    if (lineBuffer.isNotEmpty) {
      sb.write(lineBuffer.toString());
      sb.write(_crlf);
    }
  }

  /// توليد محتوى ملف تقويم قياسي (RFC 5545 iCalendar .ics) لنافذة أيام فلكية
  static String exportWindowsToIcs({
    required List<SuwayaScheduledDayWindow> windows,
    String calendarName = 'Suwaya Astronomical Calendar',
    bool includePeriods = true,
    bool includeQiyamParts = true,
    Map<PeriodKey, String>? localizedPeriodNames,
  }) {
    final sb = StringBuffer();
    _writeFoldedLine(sb, 'BEGIN:VCALENDAR');
    _writeFoldedLine(sb, 'VERSION:2.0');
    _writeFoldedLine(sb, 'PRODID:-//Suwaya//Suwaya Time Engine V2//EN');
    _writeFoldedLine(sb, 'CALSCALE:GREGORIAN');
    _writeFoldedLine(sb, 'METHOD:PUBLISH');
    _writeFoldedLine(sb, 'X-WR-CALNAME:${_escapeIcsText(calendarName)}');

    final dtStamp = _formatIcsUtc(DateTime.now().toUtc());

    for (final window in windows) {
      if (window.dayOffset < 0) continue;
      final dateKey =
          '${window.astroLogicalDate.year}${window.astroLogicalDate.month.toString().padLeft(2, '0')}${window.astroLogicalDate.day.toString().padLeft(2, '0')}';

      if (includePeriods) {
        int globalOffset = 0;
        for (final p in window.periods) {
          final startUtc = p.startUtc ?? p.startTime.toUtc();
          final endUtc = p.endUtc ?? p.endTime.toUtc();
          final title = localizedPeriodNames?[p.periodKey] ?? p.periodKey.name;
          final startCoord = SuwayaCoordinateMapper.formatString(
            globalOffset,
            0,
            isRTL: false,
          );
          final uid = 'suwaya-period-$dateKey-${p.id}@suwaya.app';

          _writeFoldedLine(sb, 'BEGIN:VEVENT');
          _writeFoldedLine(sb, 'UID:$uid');
          _writeFoldedLine(sb, 'DTSTAMP:$dtStamp');
          _writeFoldedLine(sb, 'DTSTART:${_formatIcsUtc(startUtc)}');
          _writeFoldedLine(sb, 'DTEND:${_formatIcsUtc(endUtc)}');
          _writeFoldedLine(
            sb,
            'SUMMARY:${_escapeIcsText('$title (${p.suwayasCount} Suwayas)')}',
          );
          _writeFoldedLine(
            sb,
            'DESCRIPTION:${_escapeIcsText('Starts at $startCoord | Suwayas: ${p.suwayasCount}')}',
          );
          _writeFoldedLine(sb, 'END:VEVENT');

          globalOffset += p.suwayasCount;
        }
      }

      if (includeQiyamParts) {
        for (final np in window.ibadat.nightParts) {
          if (np.startUtc == null || np.endUtc == null) continue;
          final uid = 'suwaya-qiyam-$dateKey-${np.id}@suwaya.app';
          _writeFoldedLine(sb, 'BEGIN:VEVENT');
          _writeFoldedLine(sb, 'UID:$uid');
          _writeFoldedLine(sb, 'DTSTAMP:$dtStamp');
          _writeFoldedLine(sb, 'DTSTART:${_formatIcsUtc(np.startUtc!)}');
          _writeFoldedLine(sb, 'DTEND:${_formatIcsUtc(np.endUtc!)}');
          _writeFoldedLine(sb, 'SUMMARY:${_escapeIcsText('Qiyam: ${np.id}')}');
          _writeFoldedLine(sb, 'END:VEVENT');
        }
      }
    }

    _writeFoldedLine(sb, 'END:VCALENDAR');
    return sb.toString();
  }
}
