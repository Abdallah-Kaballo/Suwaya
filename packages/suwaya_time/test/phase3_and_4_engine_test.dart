import 'package:test/test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('Phase 3: Polar Cycle Synthesizer & Islamic Events Catalog', () {
    test(
      '1. PolarCycleSynthesizer guarantees valid 7 periods & 24 Suwayas in Tromsø (69.65°N) during Polar Summer & Winter',
      () {
        for (final date in [
          DateTime.utc(2026, 6, 21), // شمس منتصف الليل القطبية
          DateTime.utc(2026, 12, 21), // الليل القطبي
        ]) {
          final rawAnchors = PrayerCalculator.getCycleAnchors(
            69.6492,
            18.9553,
            date,
            CalculationMethodType.muslimWorldLeague,
            MadhabType.shafi,
            HighLatitudeRuleType.seventhOfTheNight,
            18.0,
            18.0,
            const Duration(hours: 2),
          );

          final safeAnchors = PolarCycleSynthesizer.ensureValidAnchors(
            candidateAnchors: rawAnchors,
            latitude: 69.6492,
            longitude: 18.9553,
            targetDate: date,
            methodType: CalculationMethodType.muslimWorldLeague,
            madhabType: MadhabType.shafi,
            highLatRuleType: HighLatitudeRuleType.seventhOfTheNight,
            customFajr: 18.0,
            customIsha: 18.0,
            cityOffset: const Duration(hours: 2),
          );

          expect(safeAnchors.isValidSequence, isTrue);

          final dist = SuwayaDistributor.getDistributionForMadhab(
            MadhabType.shafi,
          );
          final periods = PeriodGenerator.generatePeriods(safeAnchors, dist);

          expect(periods.length, equals(7));
          expect(
            periods.fold<int>(0, (s, p) => s + p.suwayasCount),
            equals(24),
          );
          for (final p in periods) {
            expect(p.totalDuration.inMicroseconds, greaterThan(0));
          }
        }
      },
    );

    test(
      '2. IslamicEventsCatalog identifies Arafah, Ashura, White Days, and strictly excludes 13 Dhu al-Hijjah & Ramadan',
      () {
        expect(
          IslamicEventsCatalog.evaluateFastingForHijri(
            hMonth: 12,
            hDay: 9,
          )?.type,
          equals(IslamicFastingType.arafah),
        );
        expect(
          IslamicEventsCatalog.evaluateFastingForHijri(
            hMonth: 1,
            hDay: 10,
          )?.type,
          equals(IslamicFastingType.ashura),
        );
        expect(
          IslamicEventsCatalog.evaluateFastingForHijri(
            hMonth: 8,
            hDay: 13,
          )?.type,
          equals(IslamicFastingType.whiteDays),
        );
        // 13 ذو الحجة (أيام التشريق) ورمضان يجب استثناؤهما من الأيام البيض
        expect(
          IslamicEventsCatalog.evaluateFastingForHijri(hMonth: 12, hDay: 13),
          isNull,
        );
        expect(
          IslamicEventsCatalog.evaluateFastingForHijri(hMonth: 9, hDay: 14),
          isNull,
        );
      },
    );
  });

  group('Phase 4: SuwayaFlowPlanner & SuwayaRecurrenceEngine', () {
    test(
      '3. SuwayaFlowPlanner selects 1.00x as recommended option for 90m window and evaluates live session accurately',
      () {
        final start = DateTime.utc(2026, 10, 22, 12, 0);
        final end = DateTime.utc(2026, 10, 22, 13, 30); // 90 دقيقة

        final options = SuwayaFlowPlanner.calculateFlowOptions(start, end);
        expect(options, isNotEmpty);
        expect(options.first.tag, equals('recommended'));
        expect(options.first.pomodoroCount, equals(3));
        expect(options.first.flowSpeed, closeTo(1.0, 0.001));

        // فحص لقطة حية بعد مرور 25 دقيقة فعلية (بداية فترة الراحة الأولى تماماً)
        final snapshotAtBreak = SuwayaFlowPlanner.evaluateLiveSession(
          anchoredStartUtc: start,
          endUtc: end,
          nowUtc: start.add(const Duration(minutes: 25)),
          totalPomodoros: 3,
          flowSpeed: 1.0,
        );
        expect(snapshotAtBreak.isBreak, isTrue);
        expect(snapshotAtBreak.currentCycle, equals(1));
        expect(
          snapshotAtBreak.remainingVirtualSeconds,
          closeTo(5 * 60.0, 0.01),
        );

        // فحص تفعيل تحذير ما قبل الصلاة بدقيقتين (عند الدقيقة 88:30)
        final snapshotNearPrayer = SuwayaFlowPlanner.evaluateLiveSession(
          anchoredStartUtc: start,
          endUtc: end,
          nowUtc: start.add(const Duration(minutes: 88, seconds: 30)),
          totalPomodoros: 3,
          flowSpeed: 1.0,
        );
        expect(snapshotNearPrayer.isPrePrayerWarningActive, isTrue);
      },
    );

    test(
      '4. SuwayaRecurrenceEngine generates 8-day windows and staggers colliding timestamps by +2s',
      () {
        final windows = SuwayaRecurrenceEngine.generateMultiDayWindows(
          latitude: 21.4225,
          longitude: 39.8262,
          referenceWallTime: DateTime.utc(2026, 10, 22, 12, 0),
          timezoneId: 'Asia/Riyadh',
          calcMethod: CalculationMethodType.ummAlQura,
        );

        expect(windows.length, equals(8));
        expect(windows.first.dayOffset, equals(-1));
        expect(windows.last.dayOffset, equals(6));

        final occupied = <int>{};
        final base = DateTime.utc(2026, 10, 22, 18, 0, 0);
        final t1 = SuwayaRecurrenceEngine.resolveCollisionSafeTime(
          base,
          occupied,
        );
        final t2 = SuwayaRecurrenceEngine.resolveCollisionSafeTime(
          base,
          occupied,
        );
        expect(t1, equals(base));
        expect(t2, equals(base.add(const Duration(seconds: 2))));
      },
    );
  });
}
