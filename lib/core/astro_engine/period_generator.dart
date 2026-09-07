import 'astro_models.dart';

class PeriodGenerator {
  static List<AstroPeriod> generatePeriods(
    IbadatTimings ibadat, List<int> distribution
  ) {
    final mid = ibadat.fajr.add(Duration(microseconds: ibadat.dhuhr.difference(ibadat.fajr).inMicroseconds ~/ 2));
    final night = ibadat.nextFajr.difference(ibadat.maghrib);
    final t = Duration(microseconds: night.inMicroseconds ~/ 3);
    final firstEnd = ibadat.maghrib.add(t);
    final secondEnd = firstEnd.add(t);

    return [
      AstroPeriod(id: 1, name: 'الفجر', nameKey: 'period_fajr', startTime: ibadat.fajr, endTime: mid, suwayasCount: distribution[0], colorValue: 0xFF64B5F6),
      AstroPeriod(id: 2, name: 'الضحى', nameKey: 'period_duha', startTime: mid, endTime: ibadat.dhuhr, suwayasCount: distribution[1], colorValue: 0xFFFFF176),
      AstroPeriod(id: 3, name: 'الظهر', nameKey: 'period_dhuhr', startTime: ibadat.dhuhr, endTime: ibadat.asr, suwayasCount: distribution[2], colorValue: 0xFFFFCA28),
      AstroPeriod(id: 4, name: 'العصر', nameKey: 'period_asr', startTime: ibadat.asr, endTime: ibadat.maghrib, suwayasCount: distribution[3], colorValue: 0xFFFF9800),
      AstroPeriod(id: 5, name: 'المغرب', nameKey: 'period_maghrib', startTime: ibadat.maghrib, endTime: firstEnd, suwayasCount: distribution[4], colorValue: 0xFFE53935),
      AstroPeriod(id: 6, name: 'الثلث الأوسط', nameKey: 'period_second_third', startTime: firstEnd, endTime: secondEnd, suwayasCount: distribution[5], colorValue: 0xFF1A237E),
      AstroPeriod(id: 7, name: 'الثلث الأخير', nameKey: 'period_last_third', startTime: secondEnd, endTime: ibadat.nextFajr, suwayasCount: distribution[6], colorValue: 0xFF311B92),
    ];
  }
}