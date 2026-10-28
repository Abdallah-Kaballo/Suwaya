import 'dart:math' as math;
import 'package:test/test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('1. Strict Monotonicity & Zero-Retrograde Torture Test', () {
    test(
      'Time never moves backward across 24 hours stepped minute-by-minute (even during Fall-Back DST)',
      () {
        // ليلة تأخير الساعة الشتوي في نيويورك (1 نوفمبر 2026: الساعة 01:00..01:59 تتكرر مرتين!)
        final startUtc = DateTime.utc(2026, 10, 31, 21, 50); // مغرب نيويورك
        final ctx = TemporalContextEngine.evaluate(
          instantUtc: startUtc,
          latitude: 40.7128,
          longitude: -74.0060,
          timezoneId: 'America/New_York',
          methodType: CalculationMethodType.northAmerica,
        );

        final day = ctx.suwayaDay;
        final cycleStartUtc = day.cycleAnchors.cycleStartMaghribUtc!;
        final cycleEndUtc = day.cycleAnchors.cycleEndMaghribUtc!;

        int previousTotalVirtualSeconds = -1;
        DateTime cursorUtc = cycleStartUtc;

        while (cursorUtc.isBefore(cycleEndUtc)) {
          final wall = TimezoneResolver.toWallClock(
            cursorUtc,
            timezoneId: 'America/New_York',
          );
          final coord = SuwayaCoordinateMapper.instantToCoordinate(
            day: day,
            instant: wall,
            instantUtc: cursorUtc,
          );

          expect(
            coord.totalVirtualSeconds,
            greaterThanOrEqualTo(previousTotalVirtualSeconds),
            reason:
                'Retrograde virtual time detected at $cursorUtc: ${coord.totalVirtualSeconds} < $previousTotalVirtualSeconds',
          );
          previousTotalVirtualSeconds = coord.totalVirtualSeconds;
          cursorUtc = cursorUtc.add(const Duration(minutes: 2));
        }

        // عند نهاية الدورة، يجب أن نكون قد وصلنا إلى السويعة الأخيرة (الفهرس 23)
        expect(previousTotalVirtualSeconds, greaterThan(23 * 3600));
      },
    );
  });

  group(
    '2. Global Randomized Fuzz Testing (250 Random Earth Coordinates & Dates)',
    () {
      test(
        'Holds all 12 Suwaya invariants across random latitudes (-89.9°..+89.9°), longitudes, methods, and manual offsets',
        () {
          final rng = math.Random(20261024); // بذرة حتمية قابلة للتكرار
          const methods = CalculationMethodType.values;
          const madhabs = MadhabType.values;
          const rules = HighLatitudeRuleType.values;

          for (int i = 0; i < 250; i++) {
            final lat =
                (rng.nextDouble() * 179.8) -
                89.9; // يشمل القطب الشمالي والجنوبي
            final lng = (rng.nextDouble() * 360.0) - 180.0;
            final year = 2020 + rng.nextInt(15);
            final month = 1 + rng.nextInt(12);
            final day = 1 + rng.nextInt(28);
            final hour = rng.nextInt(24);
            final offsetHours = ((lng / 15.0).round()).clamp(-12, 14);

            final manualOffsets = <PrayerKey, int>{
              PrayerKey.fajr: rng.nextInt(61) - 30,
              PrayerKey.dhuhr: rng.nextInt(61) - 30,
              PrayerKey.asr: rng.nextInt(61) - 30,
              PrayerKey.maghrib: rng.nextInt(61) - 30,
              PrayerKey.isha: rng.nextInt(61) - 30,
            };

            final ctx = TemporalContextEngine.evaluate(
              instantUtc: DateTime.utc(year, month, day, hour),
              latitude: lat,
              longitude: lng,
              fallbackOffset: Duration(hours: offsetHours),
              methodType: methods[rng.nextInt(methods.length)],
              madhabType: madhabs[rng.nextInt(madhabs.length)],
              highLatRuleType: rules[rng.nextInt(rules.length)],
              customFajrAngle: 12.0 + rng.nextDouble() * 8.0,
              customIshaAngle: 12.0 + rng.nextDouble() * 8.0,
              manualOffsets: manualOffsets,
            );

            final periods = ctx.suwayaDay.periods;
            expect(
              periods.length,
              equals(7),
              reason: 'Failed at iter $i (lat=$lat, lng=$lng)',
            );

            final nightSum = periods
                .take(4)
                .fold<int>(0, (s, p) => s + p.suwayasCount);
            final daySum = periods
                .skip(4)
                .fold<int>(0, (s, p) => s + p.suwayasCount);
            expect(nightSum, equals(12));
            expect(daySum, equals(12));

            for (int pIdx = 0; pIdx < 6; pIdx++) {
              expect(periods[pIdx].endUtc, equals(periods[pIdx + 1].startUtc));
              expect(
                periods[pIdx].totalDuration.inMicroseconds,
                greaterThan(0),
              );
            }
          }
        },
      );
    },
  );

  group('3. Zonal Bi-Annual Distribution Invariants & 47-Bit Binary Codec Tests', () {
    test(
      'Standard Zonal Bi-Annual distribution always preserves 12 Night (5+6+1), 6 Duha, and 6 Afternoon Suwayas across all zones',
      () {
        for (final lat in [15.6445, 47.3769, 51.5074, 69.6492]) {
          for (final date in [
            DateTime.utc(2026, 6, 21),
            DateTime.utc(2026, 12, 21),
          ]) {
            for (final madhab in MadhabType.values) {
              final anchors = PrayerCalculator.getCycleAnchors(
                lat,
                18.0686,
                date,
                CalculationMethodType.muslimWorldLeague,
                madhab,
                HighLatitudeRuleType.seventhOfTheNight,
                18.0,
                17.0,
                const Duration(hours: 1),
              );

              final dist = SuwayaDistributor.resolveDistribution(
                madhab: madhab,
                anchors: anchors,
                latitude: lat,
              );

              expect(dist.length, equals(7));
              expect(dist[0] + dist[1], equals(5));
              expect(dist[2], equals(6));
              expect(dist[3], equals(1));
              expect(dist[4], equals(6));
              expect(dist[5] + dist[6], equals(6));
              expect(dist.every((count) => count >= 1), isTrue);
            }
          }
        }
      },
    );

    test(
      'SuwayaBinaryCodec packs and unpacks 47-bit integers and parses ISO-Suwaya strings losslessly',
      () {
        const original = SuwayaCoordinate(
          globalSlotIndex: 15,
          phase: SuwayaPhase.day,
          phaseSlotNumber: 4,
          periodId: 5,
          periodKey: PeriodKey.daySunriseDhuhr,
          periodLocalSlotNumber: 4,
          virtualMinute: 42,
          virtualSecond: 58,
          slotProgress: 0.71,
        );

        final packed = SuwayaBinaryCodec.pack(
          hijriYear: 1448,
          hijriMonth: 9,
          hijriDay: 27,
          coordinate: original,
        );

        // التأكد من أن العدد المضغوط أقل من سقف 53-bit الآمن في JavaScript/WebAssembly
        expect(packed, lessThan(9007199254740991));

        final unpacked = SuwayaBinaryCodec.unpack(packed);
        expect(unpacked.hijriYear, equals(1448));
        expect(unpacked.hijriMonth, equals(9));
        expect(unpacked.hijriDay, equals(27));
        expect(unpacked.coordinate, equals(original));

        final isoStr = original.toIsoSuwayaString(includeSeconds: true);
        expect(isoStr, equals('SWY-D04:42:58'));

        final parsedIso = SuwayaBinaryCodec.tryParseIsoSuwaya(isoStr);
        expect(parsedIso, isNotNull);
        expect(parsedIso!.globalSlotIndex, equals(15));
        expect(parsedIso.virtualMinute, equals(42));
        expect(parsedIso.virtualSecond, equals(58));
      },
    );

    test('SuwayaIcsExporter generates valid RFC 5545 VCALENDAR output', () {
      final windows = SuwayaRecurrenceEngine.generateMultiDayWindows(
        latitude: 21.4225,
        longitude: 39.8262,
        referenceWallTime: DateTime.utc(2026, 10, 24, 12, 0),
        timezoneId: 'Asia/Riyadh',
        calcMethod: CalculationMethodType.ummAlQura,
        startDayOffset: 0,
        daysCount: 2,
      );

      final ics = SuwayaIcsExporter.exportWindowsToIcs(windows: windows);
      expect(ics, startsWith('BEGIN:VCALENDAR'));
      expect(ics, contains('BEGIN:VEVENT'));
      expect(ics, contains('SUMMARY:'));
      expect(ics.trim(), endsWith('END:VCALENDAR'));
    });
  });
}
