import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  group('Daylight Saving Time (DST) & Timezone Offset Tests (V2 Model)', () {
    const double cairoLat = 30.0444;
    const double cairoLng = 31.2357;

    test('Spring forward transition (+2h to +3h) shifts timings by 1 hour and preserves period continuity', () {
      final transitionDate = DateTime.utc(2026, 4, 24);

      final winterDay = SuwayaTimeEngine.generateDay(
        cairoLat,
        cairoLng,
        transitionDate,
        CalculationMethodType.egyptian,
        MadhabType.shafi,
        HighLatitudeRuleType.middleOfTheNight,
        19.5,
        17.5,
        const Duration(hours: 2), // EET (Winter)
      );

      final summerDay = SuwayaTimeEngine.generateDay(
        cairoLat,
        cairoLng,
        transitionDate,
        CalculationMethodType.egyptian,
        MadhabType.shafi,
        HighLatitudeRuleType.middleOfTheNight,
        19.5,
        17.5,
        const Duration(hours: 3), // EEST (Summer DST)
      );

      // التحقق من إزاحة المواقيت بمقدار ساعة واحدة بالضبط (+60 دقيقة)
      expect(
        summerDay.ibadatTimings.maghrib
            .difference(winterDay.ibadatTimings.maghrib)
            .inMinutes,
        60,
      );
      expect(
        summerDay.ibadatTimings.fajr
            .difference(winterDay.ibadatTimings.fajr)
            .inMinutes,
        60,
      );

      // التحقق من وجود 7 فترات متصلة بدون فجوات وبمجموع 24 سويعة
      expect(summerDay.periods.length, 7);
      final totalSuwayas =
          summerDay.periods.fold<int>(0, (sum, p) => sum + p.suwayasCount);
      expect(totalSuwayas, 24);

      for (int i = 0; i < summerDay.periods.length - 1; i++) {
        expect(
          summerDay.periods[i].endTime,
          equals(summerDay.periods[i + 1].startTime),
        );
        expect(
          summerDay.periods[i].totalDuration.inMicroseconds,
          greaterThan(0),
        );
      }
    });

    test('Fall back transition (+3h to +2h) preserves 12 Night and 12 Day Suwayas', () {
      final fallDate = DateTime.utc(2026, 10, 29);

      final day = SuwayaTimeEngine.generateDay(
        cairoLat,
        cairoLng,
        fallDate,
        CalculationMethodType.egyptian,
        MadhabType.shafi,
        HighLatitudeRuleType.middleOfTheNight,
        19.5,
        17.5,
        const Duration(hours: 2),
      );

      final nightSuwayas = day.periods
          .where((p) => p.id >= 1 && p.id <= 4)
          .fold<int>(0, (sum, p) => sum + p.suwayasCount);
      final daySuwayas = day.periods
          .where((p) => p.id >= 5 && p.id <= 7)
          .fold<int>(0, (sum, p) => sum + p.suwayasCount);

      expect(nightSuwayas, 12);
      expect(daySuwayas, 12);
      expect(day.periods[2].suwayasCount, 6); // الفترة 3 (النصف الثاني من الليل) = 6 سويعات
      expect(day.periods[3].suwayasCount, 1); // الفترة 4 (الفجر إلى الشروق) = 1 سويعة
    });
  });
}