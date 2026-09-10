import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  group('اختبارات التعديل اليدوي للأوقات (Manual Offsets)', () {
    test('إضافة 15 دقيقة للمغرب يجب أن تؤخر فترة المغرب وتقلص فترة العصر', () {
      const lat = 21.4225; // مكة المكرمة
      const lng = 39.8262;
      final date = DateTime.utc(2024, 4, 1);
      const cityOffset = Duration(hours: 3);

      // الحساب بدون تعديل
      final normalIbadat = PrayerCalculator.getIbadatTimings(
        lat, lng, date, CalculationMethodType.ummAlQura, MadhabType.shafi, 
        HighLatitudeRuleType.middleOfTheNight, 18.0, 18.0, cityOffset
      );

      // الحساب مع تأخير المغرب 15 دقيقة
      final offsetIbadat = PrayerCalculator.getIbadatTimings(
        lat, lng, date, CalculationMethodType.ummAlQura, MadhabType.shafi, 
        HighLatitudeRuleType.middleOfTheNight, 18.0, 18.0, cityOffset,
        manualOffsets: {PrayerKey.maghrib: 15}
      );

      final diffInMinutes = offsetIbadat.maghrib.difference(normalIbadat.maghrib).inMinutes;

      expect(diffInMinutes, equals(15), reason: 'وقت المغرب يجب أن يتأخر 15 دقيقة بالضبط');
      expect(offsetIbadat.asr, equals(normalIbadat.asr), reason: 'وقت العصر يجب ألا يتأثر');
      
      // التأكد من أن أجزاء الليل (التي تبدأ من المغرب) قد تم إزاحتها أيضاً
      expect(
        offsetIbadat.nightParts.first.startTime.difference(normalIbadat.nightParts.first.startTime).inMinutes,
        equals(15),
        reason: 'أجزاء الليل يجب أن تتأخر لأنها تبدأ من المغرب'
      );
    });
  });
}