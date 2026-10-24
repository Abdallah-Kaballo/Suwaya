import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:suwaya_time/suwaya_time.dart';

class _WorldCitySpec {
  final String name;
  final double lat;
  final double lng;
  final String timezoneId;
  final CalculationMethodType method;
  final MadhabType madhab;
  final HighLatitudeRuleType highLatRule;

  const _WorldCitySpec({
    required this.name,
    required this.lat,
    required this.lng,
    required this.timezoneId,
    required this.method,
    this.madhab = MadhabType.shafi,
    this.highLatRule = HighLatitudeRuleType.middleOfTheNight,
  });
}

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  const worldCities = <_WorldCitySpec>[
    _WorldCitySpec(
      name: 'Makkah (Middle East)',
      lat: 21.4225,
      lng: 39.8262,
      timezoneId: 'Asia/Riyadh',
      method: CalculationMethodType.ummAlQura,
    ),
    _WorldCitySpec(
      name: 'Cairo (North Africa - DST)',
      lat: 30.0444,
      lng: 31.2357,
      timezoneId: 'Africa/Cairo',
      method: CalculationMethodType.egyptian,
    ),
    _WorldCitySpec(
      name: 'Istanbul (Eurasia - Hanafi)',
      lat: 41.0082,
      lng: 28.9784,
      timezoneId: 'Europe/Istanbul',
      method: CalculationMethodType.turkey,
      madhab: MadhabType.hanafi,
    ),
    _WorldCitySpec(
      name: 'London (Europe - DST & 7th of Night)',
      lat: 51.5074,
      lng: -0.1278,
      timezoneId: 'Europe/London',
      method: CalculationMethodType.muslimWorldLeague,
      highLatRule: HighLatitudeRuleType.seventhOfTheNight,
    ),
    _WorldCitySpec(
      name: 'New York (North America - DST)',
      lat: 40.7128,
      lng: -74.0060,
      timezoneId: 'America/New_York',
      method: CalculationMethodType.northAmerica,
    ),
    _WorldCitySpec(
      name: 'Sydney (Southern Hemisphere - Inverted Seasons DST)',
      lat: -33.8688,
      lng: 151.2093,
      timezoneId: 'Australia/Sydney',
      method: CalculationMethodType.muslimWorldLeague,
    ),
    _WorldCitySpec(
      name: 'Singapore (Equator)',
      lat: 1.3521,
      lng: 103.8198,
      timezoneId: 'Asia/Singapore',
      method: CalculationMethodType.singapore,
    ),
    _WorldCitySpec(
      name: 'Kathmandu (Fractional Offset UTC+5:45)',
      lat: 27.7172,
      lng: 85.3240,
      timezoneId: 'Asia/Kathmandu',
      method: CalculationMethodType.karachi,
      madhab: MadhabType.hanafi,
    ),
    _WorldCitySpec(
      name: 'Adelaide (Fractional Offset + Southern DST UTC+9:30/+10:30)',
      lat: -34.9285,
      lng: 138.6007,
      timezoneId: 'Australia/Adelaide',
      method: CalculationMethodType.muslimWorldLeague,
    ),
    _WorldCitySpec(
      name: 'Reykjavik (Extreme High Latitude 64°N)',
      lat: 64.1466,
      lng: -21.9426,
      timezoneId: 'Atlantic/Reykjavik',
      method: CalculationMethodType.muslimWorldLeague,
      highLatRule: HighLatitudeRuleType.seventhOfTheNight,
    ),
    _WorldCitySpec(
      name: 'Buenos Aires (South America)',
      lat: -34.6037,
      lng: -58.3816,
      timezoneId: 'America/Argentina/Buenos_Aires',
      method: CalculationMethodType.muslimWorldLeague,
    ),
    _WorldCitySpec(
      name: 'Tokyo (Far East)',
      lat: 35.6762,
      lng: 139.6503,
      timezoneId: 'Asia/Tokyo',
      method: CalculationMethodType.muslimWorldLeague,
    ),
  ];

  final keyDatesUtc = <DateTime>[
    DateTime.utc(2026, 3, 20, 12, 0), // الاعتدال الربيعي
    DateTime.utc(2026, 6, 21, 12, 0), // الانقلاب الصيفي
    DateTime.utc(2026, 9, 22, 12, 0), // الاعتدال الخريفي
    DateTime.utc(2026, 12, 21, 12, 0), // الانقلاب الشتوي
    DateTime.utc(2024, 2, 29, 12, 0), // سنة كبيسة (29 فبراير)
    DateTime.utc(2026, 12, 31, 20, 0), // ليلة رأس السنة الميلادية
  ];

  group(
      '1. Global Geographical & Seasonal Matrix (100% Mathematical Invariants)',
      () {
    for (final city in worldCities) {
      test(
          'Verifies 7 contiguous periods, 24 Suwayas, and microsecond precision in ${city.name}',
          () {
        for (final baseInstant in keyDatesUtc) {
          final ctx = TemporalContextEngine.evaluate(
            instantUtc: baseInstant,
            latitude: city.lat,
            longitude: city.lng,
            timezoneId: city.timezoneId,
            methodType: city.method,
            madhabType: city.madhab,
            highLatRuleType: city.highLatRule,
          );

          final day = ctx.suwayaDay;
          expect(day.cycleAnchors.isValidSequence, isTrue,
              reason:
                  'Invalid anchor sequence in ${city.name} at $baseInstant');
          expect(day.periods.length, 7);

          // المجموع الكلي 24 سويعة: 12 ليل (1+4+6+1) و 12 نهار
          final nightSuwayas =
              day.periods.take(4).fold<int>(0, (s, p) => s + p.suwayasCount);
          final daySuwayas =
              day.periods.skip(4).fold<int>(0, (s, p) => s + p.suwayasCount);

          expect(nightSuwayas, 12,
              reason: 'Night suwayas != 12 in ${city.name}');
          expect(daySuwayas, 12, reason: 'Day suwayas != 12 in ${city.name}');

          // اتصال الفترات السبع بدون أي فجوة أو تداخل بالمايكروثانية
          for (int i = 0; i < day.periods.length - 1; i++) {
            expect(
              day.periods[i].endUtc,
              equals(day.periods[i + 1].startUtc),
              reason:
                  'UTC gap between period ${i + 1} and ${i + 2} in ${city.name}',
            );
            expect(
              day.periods[i].endTime,
              equals(day.periods[i + 1].startTime),
              reason:
                  'Wall-clock gap between period ${i + 1} and ${i + 2} in ${city.name}',
            );
            expect(day.periods[i].totalDuration.inMicroseconds, greaterThan(0));
          }

          // التحقق من أجزاء قيام الليل الخمسة ومجموعها المطابق للنصف الثاني من الليل (الفترة 3)
          final p3 = day.periods[2]; // الفترة الثالثة: النصف الثاني من الليل
          final parts = day.ibadatTimings.nightParts;
          expect(parts.length, 5);

          final half2 = parts.firstWhere((np) => np.id == 'half_2');
          final third3 = parts.firstWhere((np) => np.id == 'third_3');
          final s4 = parts.firstWhere((np) => np.id == 'sixth_4');
          final s5 = parts.firstWhere((np) => np.id == 'sixth_5');
          final s6 = parts.firstWhere((np) => np.id == 'sixth_6');

          expect(half2.startUtc, equals(p3.startUtc));
          expect(half2.endUtc, equals(p3.endUtc));
          expect(s4.startUtc, equals(half2.startUtc));
          expect(s4.endUtc, equals(s5.startUtc));
          expect(s5.endUtc, equals(s6.startUtc));
          expect(s6.endUtc, equals(half2.endUtc));
          expect(
            (s5.realDuration + s6.realDuration - third3.realDuration)
                .inMicroseconds
                .abs(),
            lessThanOrEqualTo(5),
          );
        }
      });
    }
  });

  group('2. Daylight Saving Time (Spring Forward & Fall Back) Immunity Tests',
      () {
    test(
        'Spring-Forward (+1h) and Fall-Back (-1h) in New York & London never distort virtual minutes or slot resolution',
        () {
      // 1. نيويورك: تقديم الساعة (Spring Forward) يوم 8 مارس 2026 الساعة 02:00 صباحاً (UTC-5 -> UTC-4)
      final nySpringEveningUtc = DateTime.utc(
          2026, 3, 8, 1, 0); // بعد مغرب السبت 7 مارس بتوقيت نيويورك
      final nySpringCtx = TemporalContextEngine.evaluate(
        instantUtc: nySpringEveningUtc,
        latitude: 40.7128,
        longitude: -74.0060,
        timezoneId: 'America/New_York',
        methodType: CalculationMethodType.northAmerica,
      );

      final springDay = nySpringCtx.suwayaDay;
      final totalRealCycleMicro = springDay.cycleAnchors.cycleEndMaghribUtc!
          .difference(springDay.cycleAnchors.cycleStartMaghribUtc!)
          .inMicroseconds;
      final sumPeriodsMicro = springDay.periods.fold<int>(
        0,
        (sum, p) => sum + p.totalDuration.inMicroseconds,
      );

      // مجموع مدد الفترات السبع الفعلي يساوي تماماً الفرق بين الغروبين بالـ UTC
      expect(sumPeriodsMicro, equals(totalRealCycleMicro));

      // فحص كل سويعة ودقيقة افتراضية خلال فترة الفجر والقيام العابرة للتوقيت الصيفي
      final qiyamPeriod = springDay.periods[
          2]; // الفترة 3 (تعبر الساعة 02:00 صباحاً لحظة قفزة التوقيت الصيفي)
      for (int s = 1; s <= qiyamPeriod.suwayasCount; s++) {
        for (int vm = 0; vm < 60; vm += 15) {
          final slotUtc = qiyamPeriod.resolveSlotUtc(s, vm);
          final slotWall = qiyamPeriod.resolveSlotWallTime(
            s,
            vm,
            toWallClock: (u) =>
                TimezoneResolver.toWallClock(u, timezoneId: 'America/New_York'),
          );

          final stateAtSlot = SuwayaTimeEngine.calculateCurrentState(
            springDay,
            slotWall,
            nowUtc: slotUtc,
          );

          expect(stateAtSlot.currentPeriod.id, qiyamPeriod.id);
          expect(stateAtSlot.currentSuwayaTime.periodLocalSlotNumber, s);
          expect(stateAtSlot.currentSuwayaTime.virtualMinute, vm);
        }
      }

      // 2. نيويورك: تأخير الساعة (Fall Back) يوم 1 نوفمبر 2026 الساعة 02:00 صباحاً (UTC-4 -> UTC-5)
      // الساعة 01:30 صباحاً تتكرر مرتين على ساعة الحائط! نتحقق من أن الاعتماد على nowUtc يفرّق بينهما بدقة 100%
      final nyFallEveningUtc = DateTime.utc(2026, 11, 1, 1, 0);
      final nyFallCtx = TemporalContextEngine.evaluate(
        instantUtc: nyFallEveningUtc,
        latitude: 40.7128,
        longitude: -74.0060,
        timezoneId: 'America/New_York',
        methodType: CalculationMethodType.northAmerica,
      );

      final fallDay = nyFallCtx.suwayaDay;
      // اللحظة الأولى قبل التراجع (05:30 UTC = 01:30 EDT)
      final first0130Utc = DateTime.utc(2026, 11, 1, 5, 30);
      final first0130Wall = TimezoneResolver.toWallClock(
        first0130Utc,
        timezoneId: 'America/New_York',
      );
      // اللحظة الثانية بعد التراجع بساعة كاملة (06:30 UTC = 01:30 EST)
      final second0130Utc = DateTime.utc(2026, 11, 1, 6, 30);
      final second0130Wall = TimezoneResolver.toWallClock(
        second0130Utc,
        timezoneId: 'America/New_York',
      );

      // رغم أن ساعة الحائط في اللحظتين تشير إلى 01:30، إلا أن الوقت السويعي يتقدم للأمام ولا يتراجع أبداً!
      expect(first0130Wall.hour, equals(second0130Wall.hour));
      expect(first0130Wall.minute, equals(second0130Wall.minute));

      final stateFirst = SuwayaTimeEngine.calculateCurrentState(
        fallDay,
        first0130Wall,
        nowUtc: first0130Utc,
      );
      final stateSecond = SuwayaTimeEngine.calculateCurrentState(
        fallDay,
        second0130Wall,
        nowUtc: second0130Utc,
      );

      final totalVirtualMinutesFirst =
          (stateFirst.currentSuwayaTime.phaseSlotNumber - 1) * 60 +
              stateFirst.currentSuwayaTime.virtualMinute;
      final totalVirtualMinutesSecond =
          (stateSecond.currentSuwayaTime.phaseSlotNumber - 1) * 60 +
              stateSecond.currentSuwayaTime.virtualMinute;

      expect(totalVirtualMinutesSecond, greaterThan(totalVirtualMinutesFirst));
    });
  });

  group('3. Manual Offsets Clamping & Sunrise Protection Tests', () {
    test('Clamps extreme manual offsets to [-30, +30] and never shifts Sunrise',
        () {
      final date = DateTime.utc(2026, 5, 10);
      const offset = Duration(hours: 3);

      final baseline = PrayerCalculator.getIbadatTimings(
        21.4225,
        39.8262,
        date,
        CalculationMethodType.ummAlQura,
        MadhabType.shafi,
        HighLatitudeRuleType.middleOfTheNight,
        18.0,
        18.0,
        offset,
      );

      final extreme = PrayerCalculator.getIbadatTimings(
        21.4225,
        39.8262,
        date,
        CalculationMethodType.ummAlQura,
        MadhabType.shafi,
        HighLatitudeRuleType.middleOfTheNight,
        18.0,
        18.0,
        offset,
        manualOffsets: const {
          PrayerKey.fajr: 999, // يجب أن تُقيد بـ +30
          PrayerKey.dhuhr: -999, // يجب أن تُقيد بـ -30
          PrayerKey.sunrise: 25, // يجب أن يتم تجاهلها تماماً
        },
      );

      expect(extreme.fajr.difference(baseline.fajr).inMinutes, 30);
      expect(extreme.dhuhr.difference(baseline.dhuhr).inMinutes, -30);
      expect(extreme.sunrise, equals(baseline.sunrise));
    });
  });
}
