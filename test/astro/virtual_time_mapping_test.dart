import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  group('اختبار محول الزمن الفلكي (Virtual Time Mapping)', () {
    
    late AstroState mockAstroState;
    late DateTime fajr;
    late DateTime dhuhr;

    setUp(() {
      final today = DateTime(2025, 1, 1);
      fajr = DateTime(today.year, today.month, today.day, 5, 0); // 5 صباحاً
      dhuhr = DateTime(today.year, today.month, today.day, 12, 0); // 12 ظهراً
      
      final mockPeriod = AstroPeriod(
        id: 1, 
        name: 'الفجر', 
        nameKey: 'period_fajr', 
        startTime: fajr, 
        endTime: dhuhr, 
        suwayasCount: 7, // 7 سويعات في هذه الفترة
        colorValue: 0xFF0000,
      );

      mockAstroState = AstroState(
        virtualTime: fajr,
        periods: [mockPeriod],
        currentPeriod: mockPeriod,
        currentSuwaya: 1,
        elapsedVirtualTime: Duration.zero,
        suwayaProgress: 0,
        timeSpeedMultiplier: 1.0,
        ibadatTimings: IbadatTimings(
          fajr: fajr, sunrise: fajr, dhuhr: dhuhr, asr: dhuhr, 
          maghrib: dhuhr, isha: dhuhr, nextFajr: dhuhr, nightParts: []
        ),
        currentFormattedVirtualTime: '00:00',
      );
    });

    test('1. بداية الفترة يجب أن تعطي سويعة 00:00 تماماً', () {
      final virtualTimeStr = mockAstroState.toVirtualTime(fajr);
      expect(virtualTimeStr, equals('00:00'));
    });

    test('2. منتصف الفترة يجب أن يعكس نصف عدد السويعات بدقة', () {
      // طول الفترة من 5 صباحاً إلى 12 ظهراً = 7 ساعات
      // منتصف الفترة = الساعة 8:30 صباحاً
      final midTime = fajr.add(const Duration(hours: 3, minutes: 30));
      
      final virtualTimeStr = mockAstroState.toVirtualTime(midTime);
      
      // 7 سويعات * 30 دقيقة = 210 دقيقة افتراضية. نصفها = 105 دقيقة (أي 1 ساعة و 45 دقيقة افتراضية)
      expect(virtualTimeStr, equals('01:45'));
    });

    test('3. نهاية الفترة يجب أن تعطي عدد السويعات الكلي المخصص لها', () {
      final virtualTimeStr = mockAstroState.toVirtualTime(dhuhr);
      
      // 7 سويعات * 30 دقيقة = 210 دقيقة. (3 ساعات و 30 دقيقة افتراضية)
      expect(virtualTimeStr, equals('03:30'));
    });
  });
}