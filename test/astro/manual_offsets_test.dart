import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  group('اختبارات التعديل اليدوي للأوقات (Manual Offsets)', () {
    test('إضافة 15 دقيقة للمغرب يجب أن تؤخر وقت المغرب وتزيح منتصف الليل الشرعي بمقدار النصف', () {
      const lat = 21.4225; // مكة المكرمة
      const lng = 39.8262;
      final date = DateTime.utc(2024, 4, 1);
      const cityOffset = Duration(hours: 3);

      final normalIbadat = PrayerCalculator.getIbadatTimings(
        lat,
        lng,
        date,
        CalculationMethodType.ummAlQura,
        MadhabType.shafi,
        HighLatitudeRuleType.middleOfTheNight,
        18.0,
        18.0,
        cityOffset,
      );

      final offsetIbadat = PrayerCalculator.getIbadatTimings(
        lat,
        lng,
        date,
        CalculationMethodType.ummAlQura,
        MadhabType.shafi,
        HighLatitudeRuleType.middleOfTheNight,
        18.0,
        18.0,
        cityOffset,
        manualOffsets: {PrayerKey.maghrib: 15},
      );

      final diffInMinutes =
          offsetIbadat.maghrib.difference(normalIbadat.maghrib).inMinutes;

      expect(diffInMinutes, equals(15),
          reason: 'وقت المغرب يجب أن يتأخر 15 دقيقة بالضبط');
      expect(offsetIbadat.asr, equals(normalIbadat.asr),
          reason: 'وقت العصر يجب ألا يتأثر');

      // النصف الثاني من الليل يبدأ من منتصف (المغرب -> الفجر)، فتأخير المغرب 15 دقيقة يؤخر منتصف الليل 7.5 دقيقة (450 ثانية)
      final half2Normal =
          normalIbadat.nightParts.firstWhere((p) => p.id == 'half_2');
      final half2Offset =
          offsetIbadat.nightParts.firstWhere((p) => p.id == 'half_2');

      expect(
        half2Offset.startTime.difference(half2Normal.startTime).inSeconds,
        closeTo(450, 1),
      );
      expect(half2Offset.endTime, equals(normalIbadat.nextFajr));
    });
  });
}