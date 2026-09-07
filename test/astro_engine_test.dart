import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya/core/astro_engine/astro_engine.dart';
import 'package:suwaya/core/astro_engine/astro_models.dart';
import 'package:suwaya/core/astro_engine/suwaya_distribution.dart';

void main() {
  group('Astro Engine Time Rules (Core Invariants)', () {
    // بيانات افتراضية لاختبار مكة المكرمة
    const double lat = 21.4225;
    const double lng = 39.8262;
    final date = DateTime(2024, 1, 1);
    const cityOffset = Duration(hours: 3);

    test('1. الترتيب الزمني للصلوات: الفجر < الشروق < الظهر < العصر < المغرب < العشاء', () {
      final ibadat = AstroEngine.getIbadatTimings(
        lat, lng, date, 
        CalculationMethodType.umm_al_qura, MadhabType.shafi, 
        HighLatitudeRuleType.middle_of_the_night, 0, 0, cityOffset
      );

      expect(ibadat.fajr.isBefore(ibadat.sunrise), isTrue);
      expect(ibadat.sunrise.isBefore(ibadat.dhuhr), isTrue);
      expect(ibadat.dhuhr.isBefore(ibadat.asr), isTrue);
      expect(ibadat.asr.isBefore(ibadat.maghrib), isTrue);
      expect(ibadat.maghrib.isBefore(ibadat.isha), isTrue);
      expect(ibadat.isha.isBefore(ibadat.nextFajr), isTrue);
    });

    test('2. دقة حساب الليل: من المغرب حتى فجر اليوم التالي', () {
      final ibadat = AstroEngine.getIbadatTimings(
        lat, lng, date, 
        CalculationMethodType.umm_al_qura, MadhabType.shafi, 
        HighLatitudeRuleType.middle_of_the_night, 0, 0, cityOffset
      );

      final nightDuration = ibadat.nextFajr.difference(ibadat.maghrib);
      expect(nightDuration.inMicroseconds > 0, isTrue);

      // مجموع أثلاث الليل يجب أن يساوي طول الليل كاملاً
      final thirdsSum = ibadat.nightParts
          .where((p) => p.id.startsWith('third_'))
          .fold(Duration.zero, (prev, p) => prev + p.endTime.difference(p.startTime));
          
      // السماح بفارق ثانية واحدة بسبب التقريب الرياضي (Rounding)
      final diff = (nightDuration.inSeconds - thirdsSum.inSeconds).abs();
      expect(diff <= 1, isTrue); 
    });

    test('3. التوزيع الدقيق للسويعات: المجموع يجب أن يكون 48 سويعة دائماً', () {
      // فترات يومية عشوائية بالثواني
      final durations = [1000, 2000, 3000, 4000, 5000, 6000, 7000]; 
      final suwayas = SuwayaDistributor.distribute48Suwayas(durations);

      final sum = suwayas.fold(0, (a, b) => a + b);
      expect(sum, equals(48)); // التوزيع الكلي
      expect(suwayas.length, equals(7)); // عدد الفترات
      expect(suwayas.every((s) => s > 0), isTrue); // يجب ألا تكون هناك فترة بـ 0 سويعة
    });

    test('4. استجابة التعديل اليدوي (Manual Offsets) بدقة', () {
      final offsets = {
        PrayerKey.fajr: 10,       // إضافة 10 دقائق للفجر
        PrayerKey.maghrib: -5,    // إنقاص 5 دقائق من المغرب
      };

      final ibadatWithout = AstroEngine.getIbadatTimings(
        lat, lng, date, 
        CalculationMethodType.umm_al_qura, MadhabType.shafi, 
        HighLatitudeRuleType.middle_of_the_night, 0, 0, cityOffset
      );

      final ibadatWith = AstroEngine.getIbadatTimings(
        lat, lng, date, 
        CalculationMethodType.umm_al_qura, MadhabType.shafi, 
        HighLatitudeRuleType.middle_of_the_night, 0, 0, cityOffset,
        manualOffsets: offsets
      );

      expect(ibadatWith.fajr.difference(ibadatWithout.fajr).inMinutes, equals(10));
      expect(ibadatWith.maghrib.difference(ibadatWithout.maghrib).inMinutes, equals(-5));
      expect(ibadatWith.dhuhr.difference(ibadatWithout.dhuhr).inMinutes, equals(0)); // الظهر لم يتغير
    });

    test('5. تغطية الفترات لكامل الـ 24 ساعة (من الفجر إلى الفجر)', () {
      final distribution = [5, 5, 6, 6, 8, 9, 9]; // توزيع اعتباطي لـ 48 سويعة
      final periods = AstroEngine.generatePeriodsForDay(
        lat, lng, date, 
        CalculationMethodType.umm_al_qura, MadhabType.shafi, 
        HighLatitudeRuleType.middle_of_the_night, 0, 0, distribution, cityOffset
      );

      // التأكد من أن نهاية كل فترة هي بداية الفترة التي تليها (لا توجد فجوات)
      for (int i = 0; i < periods.length - 1; i++) {
        expect(periods[i].endTime.isAtSameMomentAs(periods[i+1].startTime), isTrue);
      }

      // إجمالي وقت الفترات يجب أن يساوي الزمن الفعلي بين الفجر وفجر اليوم التالي
      final ibadat = AstroEngine.getIbadatTimings(
        lat, lng, date, 
        CalculationMethodType.umm_al_qura, MadhabType.shafi, 
        HighLatitudeRuleType.middle_of_the_night, 0, 0, cityOffset
      );
      
      final totalPeriodsDuration = periods.last.endTime.difference(periods.first.startTime);
      final realDayDuration = ibadat.nextFajr.difference(ibadat.fajr);
      
      expect(totalPeriodsDuration.inSeconds, equals(realDayDuration.inSeconds));
    });
  });
}