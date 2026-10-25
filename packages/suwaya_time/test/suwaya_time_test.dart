import 'package:test/test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('SuwayaTimeEngine Pure Package Invariants', () {
    test(
      'Shafi [1,4,6,1,6,3,3] and Hanafi [1,4,6,1,6,4,2] sum to 24 Suwayas',
      () {
        final shafi = SuwayaDistributor.getDistributionForMadhab(
          MadhabType.shafi,
        );
        final hanafi = SuwayaDistributor.getDistributionForMadhab(
          MadhabType.hanafi,
        );

        expect(shafi, equals([1, 4, 6, 1, 6, 3, 3]));
        expect(hanafi, equals([1, 4, 6, 1, 6, 4, 2]));
        expect(shafi.reduce((a, b) => a + b), 24);
        expect(hanafi.reduce((a, b) => a + b), 24);
      },
    );

    test('calculateCurrentState with nowUtc prevents wall-clock DST drift', () {
      // محاكاة فترة ليلية يقفز فيها التوقيت الصيفي ساعة للأمام (+2 إلى +3)
      // الفترة الفعلية بـ UTC هي 4 ساعات، لكن الفرق الظاهري على ساعة الحائط 5 ساعات
      final startUtc = DateTime.utc(2026, 4, 23, 21, 0);
      final endUtc = DateTime.utc(2026, 4, 24, 1, 0); // 4 ساعات فعلية

      final startWall = DateTime.utc(2026, 4, 23, 23, 0); // +2h
      final endWall = DateTime.utc(2026, 4, 24, 4, 0); // +3h (قفزت الساعة)

      final period = AstroPeriod(
        id: 3,
        periodKey: PeriodKey.nightMidnightFajr,
        nameKey: 'periods.qiyam',
        startTime: startWall,
        endTime: endWall,
        startUtc: startUtc,
        endUtc: endUtc,
        suwayasCount: 4,
        colorValue: 0xFF311B92,
      );

      expect(period.totalDuration, const Duration(hours: 4));

      // بعد ساعتين فعليتين (منتصف الفترة تماماً): يجب أن نكون في بداية السويعة 3
      final midUtc = startUtc.add(const Duration(hours: 2));
      final midWall = midUtc.add(const Duration(hours: 3));

      final anchors = SuwayaCycleAnchors(
        cycleStartMaghrib: startWall,
        cycleIsha: startWall,
        sharIMidnight: startWall,
        cycleFajr: endWall,
        cycleSunrise: endWall,
        cycleDhuhr: endWall,
        cycleAsr: endWall,
        cycleEndMaghrib: endWall,
        cycleStartMaghribUtc: startUtc,
        cycleEndMaghribUtc: endUtc,
      );

      final dummyIbadat = IbadatTimings(
        fajr: endWall,
        sunrise: endWall,
        dhuhr: endWall,
        asr: endWall,
        maghrib: startWall,
        isha: startWall,
        nextFajr: endWall,
        nightParts: const [],
      );

      final day = SuwayaDay(
        ibadatTimings: dummyIbadat,
        cycleAnchors: anchors,
        periods: [period],
      );

      final state = SuwayaTimeEngine.calculateCurrentState(
        day,
        midWall,
        nowUtc: midUtc,
      );

      expect(state.currentSuwayaTime.periodLocalSlotNumber, 3);
      expect(state.currentSuwayaTime.virtualMinute, 0);
    });

    test(
      'TemporalContextEngine separates civilDayIbadat from yesterday cycle ibadatTimings before Maghrib',
      () {
        // ظهر يوم 22 أكتوبر 2026 (10:00 UTC = 13:00 بتوقيت مكة، أي قبل المغرب)
        final context = TemporalContextEngine.evaluate(
          instantUtc: DateTime.utc(2026, 10, 22, 10, 0),
          latitude: 21.4225,
          longitude: 39.8262,
          timezoneId: 'Asia/Riyadh',
          methodType: CalculationMethodType.ummAlQura,
        );

        // الدورة بدأت في مغرب الأمس (21 أكتوبر)
        expect(context.astroState.cycleAnchors.cycleStartMaghrib.day, 21);
        // لكن مواقيت اليوم المدني (civilDayIbadat) تخص اليوم الجاري (22 أكتوبر)
        expect(context.astroState.civilDayIbadat.dhuhr.day, 22);
        expect(context.astroState.civilDayIbadat.maghrib.day, 22);
      },
    );
  });
}
