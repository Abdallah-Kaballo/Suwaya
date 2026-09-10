import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  group('اختبارات قفزات التوقيت الصيفي (Daylight Saving Time)', () {
    
    test('قفزة التوقيت الصيفي (تقديم أو تأخير الساعة) لا تكسر اتصال الفترات', () {
      // محاكاة يوم حدثت فيه قفزة التوقيت الصيفي بين العشاء والفجر التالي
      final mockIbadat = IbadatTimings(
        fajr: DateTime(2024, 3, 10, 4, 30),
        sunrise: DateTime(2024, 3, 10, 6, 0),
        dhuhr: DateTime(2024, 3, 10, 12, 0),
        asr: DateTime(2024, 3, 10, 15, 30),
        maghrib: DateTime(2024, 3, 10, 18, 0),
        isha: DateTime(2024, 3, 10, 19, 30),
        // الساعة قفزت للامام هنا فجأة
        nextFajr: DateTime(2024, 3, 11, 5, 28), 
        nightParts: [],
      );

      final distribution = [6, 6, 8, 6, 4, 8, 10]; // مجموعها 48
      final periods = PeriodGenerator.generatePeriods(mockIbadat, distribution);

      // التحقق من أن السلسلة لم تنقطع أبداً
      for (int i = 0; i < periods.length - 1; i++) {
        expect(
          periods[i].endTime, 
          equals(periods[i + 1].startTime),
          reason: 'الساعة المدنية تغيرت، لكن الفترات يجب أن تبقى متصلة تماماً!',
        );
      }
      
      expect(periods.last.endTime, equals(mockIbadat.nextFajr));
    });
  });
}