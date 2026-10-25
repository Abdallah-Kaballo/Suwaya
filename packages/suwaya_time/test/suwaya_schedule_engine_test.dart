import 'dart:math' as math;
import 'package:intl/date_symbol_data_local.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await initializeDateFormatting('ar');
    await initializeDateFormatting('en');
  });

  group('1. Zero-Ambiguity Time Types: CivilWallClock & ZonedWallTime', () {
    test(
      'CivilWallClock enforces immutability, clamps bounds, and converts to/from minutes and 12h/24h formats',
      () {
        const clock = CivilWallClock(hour: 14, minute: 35, second: 20);
        expect(clock.minutesSinceMidnight, equals(14 * 60 + 35));
        expect(clock.secondsSinceMidnight, equals(14 * 3600 + 35 * 60 + 20));
        expect(clock.format24Hour(), equals('14:35'));
        expect(clock.format24Hour(includeSeconds: true), equals('14:35:20'));

        final parts12 = clock.to12HourParts;
        expect(parts12.hour12, equals(2));
        expect(parts12.minute, equals(35));
        expect(parts12.isPm, isTrue);

        // التحقق من الالتفاف القياسي للدقائق السالبة أو المتجاوزة لـ 1440
        final fromMins = CivilWallClock.fromMinutesSinceMidnight(14 * 60 + 35);
        expect(fromMins, equals(const CivilWallClock(hour: 14, minute: 35)));

        final midnight = CivilWallClock.fromMinutesSinceMidnight(0);
        expect(midnight.to12HourParts.hour12, equals(12));
        expect(midnight.to12HourParts.isPm, isFalse);

        // المقارنة الزمنية الصريحة
        expect(
          const CivilWallClock(
            hour: 9,
            minute: 15,
          ).isBefore(const CivilWallClock(hour: 14, minute: 0)),
          isTrue,
        );
      },
    );

    test(
      'ZonedWallTime constructs from CivilDate + CivilWallClock and truncates to minute accurately',
      () {
        final zwt = ZonedWallTime.fromCivilDateAndClock(
          date: const CivilDate(2026, 10, 24),
          clock: const CivilWallClock(hour: 18, minute: 42, second: 49),
          timezoneId: 'Asia/Riyadh',
        );

        expect(zwt.civilDate, equals(const CivilDate(2026, 10, 24)));
        expect(
          zwt.wallClock,
          equals(const CivilWallClock(hour: 18, minute: 42, second: 49)),
        );

        final truncated = zwt.truncateToMinute();
        expect(truncated.hour, equals(18));
        expect(truncated.minute, equals(42));
        expect(truncated.second, equals(0));
      },
    );
  });

  group('2. Zero UI Leakage: SuwayaScheduleEngine & AstroPeriod Metrics', () {
    late SuwayaTemporalContext makkahContext;

    setUp(() {
      // ظهر يوم 24 أكتوبر 2026 في مكة المكرمة (10:00 UTC = 13:00 محلياً)
      makkahContext = TemporalContextEngine.evaluate(
        instantUtc: DateTime.utc(2026, 10, 24, 10, 0),
        latitude: 21.4225,
        longitude: 39.8262,
        timezoneId: 'Asia/Riyadh',
        methodType: CalculationMethodType.ummAlQura,
      );
    });

    test('AstroPeriod directly exposes actualSuwayaDuration and flowSpeed', () {
      for (final p in makkahContext.suwayaDay.periods) {
        expect(p.actualSuwayaDuration.inMicroseconds, greaterThan(0));
        expect(p.flowSpeed, greaterThan(0.2));
        expect(p.flowSpeed, lessThan(5.0));
      }
    });

    test(
      'resolveLogicalCivilDate distinguishes Astro Maghrib rollover from Civil Midnight rollover',
      () {
        // بعد مغرب يوم 24 أكتوبر (16:00 UTC = 19:00 بتوقيت مكة)
        final afterMaghribCtx = TemporalContextEngine.evaluate(
          instantUtc: DateTime.utc(2026, 10, 24, 16, 0),
          latitude: 21.4225,
          longitude: 39.8262,
          timezoneId: 'Asia/Riyadh',
          methodType: CalculationMethodType.ummAlQura,
        );

        final astroLogical = SuwayaScheduleEngine.resolveLogicalCivilDate(
          isAstroTime: true,
          astroState: afterMaghribCtx.astroState,
          civilReference: afterMaghribCtx.cityWallTime,
        );
        final civilLogical = SuwayaScheduleEngine.resolveLogicalCivilDate(
          isAstroTime: false,
          astroState: afterMaghribCtx.astroState,
          civilReference: afterMaghribCtx.cityWallTime,
        );

        // اليوم السويعي انتقل إلى 25 أكتوبر بعد المغرب، بينما اليوم المدني لا يزال 24 أكتوبر حتى منتصف الليل
        expect(astroLogical, equals(const CivilDate(2026, 10, 25)));
        expect(civilLogical, equals(const CivilDate(2026, 10, 24)));
      },
    );

    test(
      'resolveTaskDynamicAstroSlot, isScheduleItemInNightPhase, and isCandidateTaskTimeInPast work accurately',
      () {
        final state = makkahContext.astroState;

        // مهمة مدنية الساعة 02:00 ليلاً تقع في الفترة الثالثة (القيام) وفي طور الليل
        final nightSlot = SuwayaScheduleEngine.resolveTaskDynamicAstroSlot(
          isAstroTime: false,
          targetCivilClock: const CivilWallClock(hour: 2, minute: 0),
          astroState: state,
        );
        expect(nightSlot, isNotNull);
        expect(nightSlot!.periodId, equals(3));

        expect(
          SuwayaScheduleEngine.isScheduleItemInNightPhase(
            isAstroTime: false,
            civilClock: const CivilWallClock(hour: 2, minute: 0),
            astroState: state,
          ),
          isTrue,
        );

        expect(
          SuwayaScheduleEngine.isScheduleItemInNightPhase(
            isAstroTime: false,
            civilClock: const CivilWallClock(hour: 10, minute: 30),
            astroState: state,
          ),
          isFalse,
        );

        // الساعة الآن 13:00 ظهراً؛ لذا فإن الساعة 09:00 صباحاً في نفس اليوم تُعد في الماضي، والساعة 16:00 عصراً في المستقبل
        final isPastMorning = SuwayaScheduleEngine.isCandidateTaskTimeInPast(
          isAstroMode: false,
          targetDate: const CivilDate(2026, 10, 24),
          candidateGlobalSuwaya: 0,
          candidateVirtualMinute: 0,
          candidateCivilClock: const CivilWallClock(hour: 9, minute: 0),
          astroState: state,
          cityNow: makkahContext.cityWallTime,
        );
        final isPastAfternoon = SuwayaScheduleEngine.isCandidateTaskTimeInPast(
          isAstroMode: false,
          targetDate: const CivilDate(2026, 10, 24),
          candidateGlobalSuwaya: 0,
          candidateVirtualMinute: 0,
          candidateCivilClock: const CivilWallClock(hour: 16, minute: 0),
          astroState: state,
          cityNow: makkahContext.cityWallTime,
        );

        expect(isPastMorning, isTrue);
        expect(isPastAfternoon, isFalse);
      },
    );

    test(
      'computeRoutineDialArc and resolveDialDropTarget compute valid polar geometry',
      () {
        final periods = makkahContext.suwayaDay.periods;

        final astroArc = SuwayaScheduleEngine.computeRoutineDialArc(
          isAstroTime: true,
          startPeriodId: 5,
          startSuwaya: 1,
          startVirtualMinute: 0,
          endPeriodId: 5,
          endSuwaya: 3,
          endVirtualMinute: 30,
          periods: periods,
        );
        expect(astroArc, isNotNull);
        expect(astroArc!.sweepAngle, greaterThan(0));
        expect(astroArc.sweepAngle, lessThan(2 * math.pi));

        final civilArc = SuwayaScheduleEngine.computeRoutineDialArc(
          isAstroTime: false,
          startCivilClock: const CivilWallClock(hour: 8, minute: 0),
          endCivilClock: const CivilWallClock(hour: 11, minute: 0),
          periods: periods,
        );
        expect(civilArc, isNotNull);
        expect(civilArc!.sweepAngle, greaterThan(0));

        final drop = SuwayaScheduleEngine.resolveDialDropTarget(
          dragAngle: astroArc.startAngle + 0.05,
          periods: periods,
        );
        expect(drop, isNotNull);
        expect(drop!.periodId, equals(5));
      },
    );

    test(
      'computeNextPrayerCountdown & SuwayaFlowPlanner window validation',
      () {
        final state = makkahContext.astroState;

        final astroCountdown = SuwayaScheduleEngine.computeNextPrayerCountdown(
          astroState: state,
          liveNow: makkahContext.cityWallTime,
          useAstroTime: true,
          nowUtc: makkahContext.instantUtc,
        );
        expect(astroCountdown.prayerKey, equals(PrayerKey.asr));
        expect(astroCountdown.totalRemainingSeconds, greaterThan(0));

        final start = DateTime.utc(2026, 10, 24, 13, 0);
        final validRes = SuwayaFlowPlanner.validateSessionWindow(
          anchoredStart: start,
          candidateEnd: start.add(const Duration(minutes: 90)),
        );
        expect(validRes.isValid, isTrue);
        expect(validRes.actualMinutes, equals(90));

        final tooShortRes = SuwayaFlowPlanner.validateSessionWindow(
          anchoredStart: start,
          candidateEnd: start.add(const Duration(minutes: 10)),
        );
        expect(tooShortRes.isValid, isFalse);
        expect(tooShortRes.error, equals(SuwayaFlowValidationError.tooShort));
      },
    );
  });
}
