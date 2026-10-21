import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  group('Daylight Saving Time (DST) & Calculation Methods Tests (V2 Model)', () {
    const double cairoLat = 30.0444;
    const double cairoLng = 31.2357;

    test('Mid-cycle DST transition (Maghrib at +2h, next day Fajr at +3h) preserves valid sequence and 24 Suwayas', () {
      final transitionDate = DateTime.utc(2026, 4, 24);

      final crossDstDay = SuwayaTimeEngine.generateDay(
        cairoLat,
        cairoLng,
        transitionDate,
        CalculationMethodType.egyptian,
        MadhabType.shafi,
        HighLatitudeRuleType.middleOfTheNight,
        19.5,
        17.5,
        const Duration(hours: 2), // المساء بالتوقيت الشتوي (+2)
        nextDayCityOffset: const Duration(hours: 3), // الصباح بالتوقيت الصيفي (+3)
      );

      expect(crossDstDay.cycleAnchors.isValidSequence, isTrue);
      expect(crossDstDay.periods.length, 7);

      final totalSuwayas =
          crossDstDay.periods.fold<int>(0, (sum, p) => sum + p.suwayasCount);
      expect(totalSuwayas, 24);

      for (int i = 0; i < crossDstDay.periods.length - 1; i++) {
        expect(
          crossDstDay.periods[i].endTime,
          equals(crossDstDay.periods[i + 1].startTime),
        );
        expect(
          crossDstDay.periods[i].totalDuration.inMicroseconds,
          greaterThan(0),
        );
      }
    });

    test('All calculation methods produce distinct astronomical timings according to their angles', () {
      final date = DateTime.utc(2026, 5, 15);
      const offset = Duration(hours: 3);

      final mwl = PrayerCalculator.getIbadatTimings(
        cairoLat, cairoLng, date,
        CalculationMethodType.muslimWorldLeague, MadhabType.shafi,
        HighLatitudeRuleType.middleOfTheNight, 18, 17, offset,
      );
      final egypt = PrayerCalculator.getIbadatTimings(
        cairoLat, cairoLng, date,
        CalculationMethodType.egyptian, MadhabType.shafi,
        HighLatitudeRuleType.middleOfTheNight, 18, 17, offset,
      );
      final isna = PrayerCalculator.getIbadatTimings(
        cairoLat, cairoLng, date,
        CalculationMethodType.northAmerica, MadhabType.shafi,
        HighLatitudeRuleType.middleOfTheNight, 18, 17, offset,
      );
      final france = PrayerCalculator.getIbadatTimings(
        cairoLat, cairoLng, date,
        CalculationMethodType.franceUoif, MadhabType.shafi,
        HighLatitudeRuleType.middleOfTheNight, 18, 17, offset,
      );
      final russia = PrayerCalculator.getIbadatTimings(
        cairoLat, cairoLng, date,
        CalculationMethodType.russia, MadhabType.shafi,
        HighLatitudeRuleType.middleOfTheNight, 18, 17, offset,
      );

      // التحقق من أن الطرق لم تعد تسقط في نفس زاوية الفجر الخاصة برابطة العالم الإسلامي (18°)
      expect(egypt.fajr, isNot(equals(mwl.fajr)));   // مصر 19.5°
      expect(isna.fajr, isNot(equals(mwl.fajr)));    // أمريكا الشمالية 15°
      expect(france.fajr, isNot(equals(mwl.fajr)));  // فرنسا 12°
      expect(russia.fajr, isNot(equals(mwl.fajr)));  // روسيا 16°
      expect(france.fajr.isAfter(russia.fajr), isTrue); // زاوية 12° تدخل بعد زاوية 16°
    });
  });
}