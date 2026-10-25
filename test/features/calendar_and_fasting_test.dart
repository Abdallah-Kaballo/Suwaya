import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:suwaya/features/calendar/widgets/calendar_day_agenda.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  group('Hijri Calendar & Seasonal Fasting Recommendations Tests', () {
    test(
      '1. Identifies Day of Arafah (9 Dhu al-Hijjah) and Ashura/Tasua (9 & 10 Muharram)',
      () {
        final arafah = HijriCalendar()
          ..hYear = 1448
          ..hMonth = 12
          ..hDay = 9;
        final arafahInfo = getSeasonalFastingInfo(arafah, 'ar');
        expect(arafahInfo, isNotNull);
        expect(arafahInfo!.title, contains('عرفة'));

        final tasua = HijriCalendar()
          ..hYear = 1448
          ..hMonth = 1
          ..hDay = 9;
        final ashura = HijriCalendar()
          ..hYear = 1448
          ..hMonth = 1
          ..hDay = 10;

        expect(getSeasonalFastingInfo(tasua, 'ar')!.title, contains('تاسوعاء'));
        expect(getSeasonalFastingInfo(ashura, 'en')!.title, contains('Ashura'));
      },
    );

    test(
      '2. Identifies White Days (13, 14, 15) and strictly excludes 13 Dhu al-Hijjah (Tashreeq) and Ramadan',
      () {
        for (final day in [13, 14, 15]) {
          final shaabanWhiteDay = HijriCalendar()
            ..hYear = 1448
            ..hMonth = 8
            ..hDay = day;
          expect(
            getSeasonalFastingInfo(shaabanWhiteDay, 'ar'),
            isNotNull,
            reason: 'Day $day of Shaaban should be marked as White Day',
          );

          final ramadanDay = HijriCalendar()
            ..hYear = 1448
            ..hMonth = 9
            ..hDay = day;
          expect(
            getSeasonalFastingInfo(ramadanDay, 'ar'),
            isNull,
            reason: 'Ramadan days should not show voluntary White Days banner',
          );
        }

        // 13 ذو الحجة هو ثالث أيام التشريق ويحرم صيامه تطوعاً، بينما 14 و15 ذو الحجة من الأيام البيض
        final tashreeq13 = HijriCalendar()
          ..hYear = 1448
          ..hMonth = 12
          ..hDay = 13;
        final dhuAlHijjah14 = HijriCalendar()
          ..hYear = 1448
          ..hMonth = 12
          ..hDay = 14;

        expect(getSeasonalFastingInfo(tashreeq13, 'ar'), isNull);
        expect(getSeasonalFastingInfo(dhuAlHijjah14, 'ar'), isNotNull);
      },
    );

    test(
      '3. UmmAlQuraHijriProvider round-trip conversion with hijriAdjustmentDays (-2 to +2) is consistent',
      () {
        const provider = UmmAlQuraHijriProvider();
        const baseDate = CivilDate(2026, 10, 22);

        for (final adj in [-2, -1, 0, 1, 2]) {
          final hijri = provider.dateForGregorianDate(
            date: baseDate,
            adjustmentDays: adj,
          );
          final roundTripGreg = provider.gregorianForHijriDate(
            hYear: hijri.year,
            hMonth: hijri.month,
            hDay: hijri.day,
            adjustmentDays: adj,
          );

          expect(roundTripGreg, equals(baseDate));
        }
      },
    );
  });
}
