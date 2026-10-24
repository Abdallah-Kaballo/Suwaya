import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  group('Daylight Saving Time (DST) & Calculation Methods Tests (V2 Model)',
      () {
    const double cairoLat = 30.0444;
    const double cairoLng = 31.2357;

    test(
        'Mid-cycle DST transition (Maghrib at +2h, next day Fajr at +3h) preserves valid sequence and 24 Suwayas',
        () {
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
        nextDayCityOffset:
            const Duration(hours: 3), // الصباح بالتوقيت الصيفي (+3)
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

    test(
        'All calculation methods produce distinct astronomical timings according to their angles',
        () {
      final date = DateTime.utc(2026, 5, 15);
      const offset = Duration(hours: 3);

      final mwl = PrayerCalculator.getIbadatTimings(
        cairoLat,
        cairoLng,
        date,
        CalculationMethodType.muslimWorldLeague,
        MadhabType.shafi,
        HighLatitudeRuleType.middleOfTheNight,
        18,
        17,
        offset,
      );
      final egypt = PrayerCalculator.getIbadatTimings(
        cairoLat,
        cairoLng,
        date,
        CalculationMethodType.egyptian,
        MadhabType.shafi,
        HighLatitudeRuleType.middleOfTheNight,
        18,
        17,
        offset,
      );
      final isna = PrayerCalculator.getIbadatTimings(
        cairoLat,
        cairoLng,
        date,
        CalculationMethodType.northAmerica,
        MadhabType.shafi,
        HighLatitudeRuleType.middleOfTheNight,
        18,
        17,
        offset,
      );
      final france = PrayerCalculator.getIbadatTimings(
        cairoLat,
        cairoLng,
        date,
        CalculationMethodType.franceUoif,
        MadhabType.shafi,
        HighLatitudeRuleType.middleOfTheNight,
        18,
        17,
        offset,
      );
      final russia = PrayerCalculator.getIbadatTimings(
        cairoLat,
        cairoLng,
        date,
        CalculationMethodType.russia,
        MadhabType.shafi,
        HighLatitudeRuleType.middleOfTheNight,
        18,
        17,
        offset,
      );

      // التحقق من أن الطرق لم تعد تسقط في نفس زاوية الفجر الخاصة برابطة العالم الإسلامي (18°)
      expect(egypt.fajr, isNot(equals(mwl.fajr))); // مصر 19.5°
      expect(isna.fajr, isNot(equals(mwl.fajr))); // أمريكا الشمالية 15°
      expect(france.fajr, isNot(equals(mwl.fajr))); // فرنسا 12°
      expect(russia.fajr, isNot(equals(mwl.fajr))); // روسيا 16°
      expect(france.fajr.isAfter(russia.fajr),
          isTrue); // زاوية 12° تدخل بعد زاوية 16°
    });

    test(
        'Real night duration across Spring-forward DST (+2h to +3h) equals exact UTC elapsed time (not wall-clock difference)',
        () {
      final transitionDate = DateTime.utc(2026, 4, 24);

      // يوم بدون تغيير توقيت صيفي (+2h طوال الليل)
      final normalDay = SuwayaTimeEngine.generateDay(
        cairoLat,
        cairoLng,
        transitionDate,
        CalculationMethodType.egyptian,
        MadhabType.shafi,
        HighLatitudeRuleType.middleOfTheNight,
        19.5,
        17.5,
        const Duration(hours: 2),
        nextDayCityOffset: const Duration(hours: 2),
      );

      // نفس اليوم مع تقديم الساعة في منتصف الليل (+2h مساءً -> +3h فجراً)
      final dstDay = SuwayaTimeEngine.generateDay(
        cairoLat,
        cairoLng,
        transitionDate,
        CalculationMethodType.egyptian,
        MadhabType.shafi,
        HighLatitudeRuleType.middleOfTheNight,
        19.5,
        17.5,
        const Duration(hours: 2),
        nextDayCityOffset: const Duration(hours: 3),
      );

      // مجموع المدد الفعلية (totalDuration) لفترات الليل (المغرب -> الفجر: الفترات 1، 2، 3)
      // يجب أن يتطابق بالثانية الفعلية رغم أن ساعة الحائط للفجر قفزت ساعة للأمام
      final normalNightRealSecs = normalDay.periods
          .take(3)
          .fold<int>(0, (sum, p) => sum + p.totalDuration.inSeconds);
      final dstNightRealSecs = dstDay.periods
          .take(3)
          .fold<int>(0, (sum, p) => sum + p.totalDuration.inSeconds);

      expect(dstNightRealSecs, equals(normalNightRealSecs));
    });

    test(
        'Hijri date advances at astronomical sunset, ignores manual Maghrib offset, and does not double-advance at civil midnight',
        () {
      // 21 أكتوبر 2026 في مكة (+3): الغروب حوالي 17:45 بالتوقيت المحلي (14:45 UTC)
      // 1. قبل الغروب (14:00 UTC = 17:00 محلي)
      final beforeSunset = TemporalContextEngine.evaluate(
        instantUtc: DateTime.utc(2026, 10, 21, 14, 0),
        latitude: 21.4225,
        longitude: 39.8262,
        fallbackOffset: const Duration(hours: 3),
        methodType: CalculationMethodType.ummAlQura,
      );

      // 2. بعد الغروب الفلكي بدقائق (15:00 UTC = 18:00 محلي)، حتى مع تأخير تنبيه المغرب يدوياً +30 دقيقة
      final afterSunsetBeforeMidnight = TemporalContextEngine.evaluate(
        instantUtc: DateTime.utc(2026, 10, 21, 15, 0),
        latitude: 21.4225,
        longitude: 39.8262,
        fallbackOffset: const Duration(hours: 3),
        methodType: CalculationMethodType.ummAlQura,
        manualOffsets: const {PrayerKey.maghrib: 30},
      );

      // 3. بعد منتصف الليل المدني (21:30 UTC = 00:30 محلي يوم 22 أكتوبر)
      final afterCivilMidnight = TemporalContextEngine.evaluate(
        instantUtc: DateTime.utc(2026, 10, 21, 21, 30),
        latitude: 21.4225,
        longitude: 39.8262,
        fallbackOffset: const Duration(hours: 3),
        methodType: CalculationMethodType.ummAlQura,
      );

      // التاريخ الهجري تقدم بعد الغروب مباشرة
      expect(
        afterSunsetBeforeMidnight.islamicLogicalGregorianDate,
        equals(beforeSunset.civilDate.addDays(1)),
      );

      // وبعد عبور منتصف الليل المدني (00:30)، تقدم التاريخ المدني بينما ثبت التاريخ الهجري دون زيادة مزدوجة
      expect(afterCivilMidnight.civilDate,
          equals(beforeSunset.civilDate.addDays(1)));
      expect(
        afterCivilMidnight.hijriDate.day,
        equals(afterSunsetBeforeMidnight.hijriDate.day),
      );
      expect(
        afterCivilMidnight.hijriDate.month,
        equals(afterSunsetBeforeMidnight.hijriDate.month),
      );
    });
  });
}
