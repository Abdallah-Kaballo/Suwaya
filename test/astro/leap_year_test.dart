import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  group('اختبارات السنة الكبيسة (Leap Year)', () {
    test('المحرك يجب أن يتعامل مع يوم 29 فبراير بشكل طبيعي', () {
      final date = DateTime.utc(2024, 2, 29); // 2024 سنة كبيسة
      
      final ibadat = PrayerCalculator.getIbadatTimings(
        21.4225, 39.8262, date, 
        CalculationMethodType.ummAlQura, MadhabType.shafi, 
        HighLatitudeRuleType.middleOfTheNight, 18.0, 18.0, 
        const Duration(hours: 3)
      );

      // يجب أن يحسب فجر اليوم التالي (1 مارس) دون أخطاء
      expect(ibadat.nextFajr.day, equals(1));
      expect(ibadat.nextFajr.month, equals(3));
      expect(ibadat.nextFajr.isAfter(ibadat.isha), isTrue);
    });
  });
}