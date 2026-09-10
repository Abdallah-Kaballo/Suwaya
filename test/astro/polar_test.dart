import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  group('اختبارات خطوط العرض المتطرفة (High Latitude & Polar Tests)', () {
    
    test('1. اختبار ستوكهولم (السويد) في ذروة الصيف (شمس منتصف الليل تقريباً)', () {
      const lat = 59.3293;
      const lng = 18.0686;
      final date = DateTime.utc(2024, 6, 21); // الانقلاب الصيفي
      const cityOffset = Duration(hours: 2); // توقيت صيفي

      final ibadat = PrayerCalculator.getIbadatTimings(
        lat, lng, date, 
        CalculationMethodType.muslimWorldLeague, 
        MadhabType.shafi, 
        HighLatitudeRuleType.middleOfTheNight, 
        18.0, 18.0, 
        cityOffset
      );

      // في خطوط العرض العليا جداً صيفاً، الفجر قد يتطابق مع الشروق تماماً
      // لذلك نتأكد أن تسلسل النهار والليل الإجمالي منطقي دون افتراض وجود مسافة بين الفجر والشروق
      expect(ibadat.dhuhr.isAfter(ibadat.fajr), isTrue, reason: 'الظهر يجب أن يكون بعد الفجر');
      expect(ibadat.maghrib.isAfter(ibadat.dhuhr), isTrue, reason: 'المغرب يجب أن يكون بعد الظهر');
      expect(ibadat.nextFajr.isAfter(ibadat.maghrib), isTrue, reason: 'فجر اليوم التالي يجب أن يكون بعد المغرب');

      // التأكد من أن أجزاء الليل لم تنهار رغم قصر الليل الشديد
      expect(ibadat.nightParts.length, equals(11), reason: 'يجب أن يقسم الليل إلى 11 جزءاً دائماً');
      
      for (var part in ibadat.nightParts) {
        final duration = part.endTime.difference(part.startTime);
        // قد يكون الليل قصيراً لدرجة أن بعض الأجزاء تقترب من الصفر، لكن لا يجب أن تكون سالبة أبداً!
        expect(duration.inMicroseconds, greaterThanOrEqualTo(0), reason: 'لا يجب أن يكون هناك وقت سالب');
      }
    });

    test('2. اختبار أوسلو (النرويج) في ذروة الشتاء (نهار قصير جداً وليل طويل)', () {
      const lat = 59.9139;
      const lng = 10.7522;
      final date = DateTime.utc(2024, 12, 21); // الانقلاب الشتوي
      const cityOffset = Duration(hours: 1);

      final ibadat = PrayerCalculator.getIbadatTimings(
        lat, lng, date, 
        CalculationMethodType.muslimWorldLeague, 
        MadhabType.shafi, 
        HighLatitudeRuleType.seventhOfTheNight, 
        18.0, 18.0, 
        cityOffset
      );

      final daylightHours = ibadat.maghrib.difference(ibadat.fajr).inHours;
      final nightHours = ibadat.nextFajr.difference(ibadat.maghrib).inHours;

      expect(daylightHours, lessThan(9), reason: 'النهار في أوسلو شتاءً يجب أن يكون قصيراً جداً');
      // 🌟 تم الإصلاح: استخدام greaterThanOrEqualTo لتجنب مشكلة إهمال الكسور في دالة inHours
      expect(nightHours, greaterThanOrEqualTo(15), reason: 'الليل يجب أن يكون 15 ساعة أو أكثر');
    });
  });
}