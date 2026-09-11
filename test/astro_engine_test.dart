import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  group('SuwayaTimeEngine Core Tests', () {
    final testDate = DateTime(2026, 9, 10);
    const lat = 21.4225; // مكة المكرمة
    const lng = 39.8262;
    const offset = Duration(hours: 3);

    test('PrayerCalculator يجب أن يحسب المواقيت وأثلاث الليل بشكل صحيح', () {
      final ibadat = PrayerCalculator.getIbadatTimings(
        lat, lng, testDate,
        CalculationMethodType.ummAlQura, MadhabType.shafi,
        HighLatitudeRuleType.middleOfTheNight, 0, 0, offset,
      );
      
      expect(ibadat.fajr.isBefore(ibadat.sunrise), isTrue);
      expect(ibadat.nightParts.length, equals(11));
    });

    test('SuwayaTimeEngine يجب أن يولد اليوم والفترات بناءً على التوزيع الموحد', () {
      final distribution = SuwayaDistributor.getUniversalDistribution();
      final day = SuwayaTimeEngine.generateDay(
        lat, lng, testDate,
        CalculationMethodType.ummAlQura, MadhabType.shafi,
        HighLatitudeRuleType.middleOfTheNight, 0, 0,
        offset, distribution,
      );
      
      expect(day.periods.length, equals(7));
      expect(day.periods.first.suwayasCount, equals(7)); // الفجر 7 سويعات
      expect(day.periods[3].suwayasCount, equals(6));    // العصر 6 سويعات
    });
  });
}