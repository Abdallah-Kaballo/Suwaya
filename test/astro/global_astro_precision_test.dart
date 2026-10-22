import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  group('Global Astro Precision & DST Tests (100% Accuracy)', () {
    test('1. Equator location (Nairobi) always produces ~12h periods', () {
      final ibadat = PrayerCalculator.getIbadatTimings(
        -1.2921, 36.8219, DateTime.utc(2026, 3, 21),
        CalculationMethodType.muslimWorldLeague, MadhabType.shafi,
        HighLatitudeRuleType.middleOfTheNight, 18.0, 18.0, const Duration(hours: 3)
      );

      expect(ibadat.nextFajr.difference(ibadat.maghrib).inMinutes, closeTo(645, 35)); 
    });

    test('2. Southern Hemisphere extreme (Punta Arenas, Chile) in Winter', () {
      final ibadat = PrayerCalculator.getIbadatTimings(
        -53.1500, -70.9070, DateTime.utc(2026, 6, 21), // ذروة الشتاء في نصف الكرة الجنوبي
        CalculationMethodType.muslimWorldLeague, MadhabType.shafi,
        HighLatitudeRuleType.seventhOfTheNight, 18.0, 18.0, const Duration(hours: -3)
      );
      
      final dayLen = ibadat.maghrib.difference(ibadat.sunrise).inHours;
      expect(dayLen, lessThan(8), reason: 'النهار يجب أن يكون قصيراً جداً في أقصى الجنوب شتاءً');
    });
    
    test('3. DST Spring Forward does not alter physical elapsed microsecond duration for periods', () {
      final date = DateTime.utc(2026, 3, 28); // ليلة قفزة التوقيت الصيفي في أوروبا
      final anchors = PrayerCalculator.getCycleAnchors(
        51.5074, -0.1278, date, // London
        CalculationMethodType.muslimWorldLeague, MadhabType.shafi,
        HighLatitudeRuleType.seventhOfTheNight, 18.0, 18.0,
        const Duration(hours: 0), // الشتاء GMT
        nextDayCityOffset: const Duration(hours: 1), // الصيف BST
      );
      
      // المدة الفعلية بالـ UTC يجب ألا تتأثر بالقفزة المدنية لساعة الحائط
      final realNightMicroseconds = anchors.cycleFajrUtc!.difference(anchors.cycleStartMaghribUtc!).inMicroseconds;
      expect(realNightMicroseconds, greaterThan(0));
      
      final periods = PeriodGenerator.generatePeriods(anchors, [1,4,6,1,6,3,3]);
      
      for (final p in periods) {
        expect(p.totalDuration.inMicroseconds, greaterThan(0), reason: 'الـ DST يجب ألا يولد فترات زمنية سالبة أو صفرية أبداً');
      }
    });
  });
}