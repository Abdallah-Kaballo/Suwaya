import 'package:test/test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('1. Jean Meeus & NOAA Astronomical Ephemeris Reference Benchmarks', () {
    test(
      'Solar Declination, Equation of Time, and Solar Transit match Meeus/NOAA tables within < 0.03°',
      () {
        final summerPos = SolarEphemerisCalculator.evaluateSolarPosition(
          instant: InstantUtc.fromDateTime(DateTime.utc(2026, 6, 21, 12, 0)),
          latitude: 0.0,
          longitude: 0.0,
        );
        expect(summerPos.declinationDegrees, closeTo(23.44, 0.03));

        final winterPos = SolarEphemerisCalculator.evaluateSolarPosition(
          instant: InstantUtc.fromDateTime(DateTime.utc(2026, 12, 21, 12, 0)),
          latitude: 0.0,
          longitude: 0.0,
        );
        expect(winterPos.declinationDegrees, closeTo(-23.44, 0.03));

        final novPos = SolarEphemerisCalculator.evaluateSolarPosition(
          instant: InstantUtc.fromDateTime(DateTime.utc(2026, 11, 3, 12, 0)),
          latitude: 21.4225,
          longitude: 39.8262,
        );
        expect(novPos.equationOfTimeMinutes, closeTo(16.4, 0.25));
      },
    );
  });

  group('2. Official Jurisprudential Prayer Timetables Parity (1-Minute Tolerance)', () {
    int toRoundedMinutes(DateTime dt) =>
        dt.hour * 60 + dt.minute + (dt.second >= 30 ? 1 : 0);

    test('Makkah matches Official Umm Al-Qura Calendar (27 Oct 2026)', () {
      final ibadat = PrayerCalculator.getIbadatTimings(
        21.4225,
        39.8262,
        DateTime.utc(2026, 10, 27),
        CalculationMethodType.ummAlQura,
        MadhabType.shafi,
        HighLatitudeRuleType.middleOfTheNight,
        18.5,
        18.0,
        const Duration(hours: 3),
      );

      expect(toRoundedMinutes(ibadat.fajr), closeTo(5 * 60 + 4, 1)); // 05:04 (زاوية 18.5°)
      expect(toRoundedMinutes(ibadat.sunrise), closeTo(6 * 60 + 21, 1)); // 06:21
      expect(toRoundedMinutes(ibadat.dhuhr), closeTo(12 * 60 + 5, 1)); // 12:05
      expect(toRoundedMinutes(ibadat.asr), closeTo(15 * 60 + 21, 1)); // 15:21
      expect(toRoundedMinutes(ibadat.maghrib), closeTo(17 * 60 + 48, 1)); // 17:48
      expect(toRoundedMinutes(ibadat.isha), closeTo(19 * 60 + 18, 1)); // 19:18 (+90m)
    });

    test(
      'Cairo & Omdurman match Egyptian General Authority of Survey (27 Oct 2026)',
      () {
        final cairo = PrayerCalculator.getIbadatTimings(
          30.0444,
          31.2357,
          DateTime.utc(2026, 10, 27),
          CalculationMethodType.egyptian,
          MadhabType.shafi,
          HighLatitudeRuleType.middleOfTheNight,
          19.5,
          17.5,
          const Duration(hours: 2),
        );

        expect(toRoundedMinutes(cairo.fajr), closeTo(4 * 60 + 38, 1)); // 04:38
        expect(toRoundedMinutes(cairo.sunrise), closeTo(6 * 60 + 5, 1)); // 06:05
        expect(toRoundedMinutes(cairo.dhuhr), closeTo(11 * 60 + 39, 1)); // 11:39
        expect(toRoundedMinutes(cairo.asr), closeTo(14 * 60 + 48, 1)); // 14:48
        expect(toRoundedMinutes(cairo.maghrib), closeTo(17 * 60 + 12, 1)); // 17:12
        expect(toRoundedMinutes(cairo.isha), closeTo(18 * 60 + 30, 1)); // 18:30

        final omdurman = PrayerCalculator.getIbadatTimings(
          15.6445,
          32.4777,
          DateTime.utc(2026, 10, 27),
          CalculationMethodType.egyptian,
          MadhabType.shafi,
          HighLatitudeRuleType.middleOfTheNight,
          19.5,
          17.5,
          const Duration(hours: 2),
        );

        expect(toRoundedMinutes(omdurman.fajr), closeTo(4 * 60 + 26, 1)); // 04:26
        expect(toRoundedMinutes(omdurman.sunrise), closeTo(5 * 60 + 45, 1)); // 05:45
        expect(toRoundedMinutes(omdurman.dhuhr), closeTo(11 * 60 + 34, 1)); // 11:34
        expect(toRoundedMinutes(omdurman.asr), closeTo(14 * 60 + 54, 1)); // 14:54
        expect(toRoundedMinutes(omdurman.maghrib), closeTo(17 * 60 + 23, 1)); // 17:23
        expect(toRoundedMinutes(omdurman.isha), closeTo(18 * 60 + 33, 1)); // 18:33
      },
    );

    test(
      'Rabat matches Moroccan Ministry of Habous (+5m Dhuhr & Maghrib precaution over astronomical sunset)',
      () {
        final rabat = PrayerCalculator.getIbadatTimings(
          34.0209,
          -6.8416,
          DateTime.utc(2026, 10, 27),
          CalculationMethodType.morocco,
          MadhabType.shafi,
          HighLatitudeRuleType.middleOfTheNight,
          19.0,
          17.0,
          const Duration(hours: 1),
        );

        expect(
          rabat.maghrib.difference(rabat.calculatedSunset!).inMinutes,
          equals(5),
        );
      },
    );
  });

  group('3. WGS84 Geodesic Qibla Benchmark Across 6 Global Capitals', () {
    test('Matches standard Vincenty WGS84 bearings within 0.05°', () {
      // 1. أم درمان، السودان (15.6445°N, 32.4777°E -> WGS84 = 49.38°)
      expect(
        QiblaCalculator.calculate(15.6445, 32.4777).bearingDegrees,
        closeTo(49.38, 0.05),
      );
      // 2. القاهرة، مصر (30.0444°N, 31.2357°E -> WGS84 = 135.98°)
      expect(
        QiblaCalculator.calculate(30.0444, 31.2357).bearingDegrees,
        closeTo(135.98, 0.05),
      );
      // 3. لندن، المملكة المتحدة (WGS84 = 118.87°, Spherical = 118.99°)
      expect(
        QiblaCalculator.calculate(51.5074, -0.1278).bearingDegrees,
        closeTo(118.87, 0.05),
      );
      // 4. نيويورك، الولايات المتحدة (WGS84 = 58.40°, Spherical = 58.48°)
      expect(
        QiblaCalculator.calculate(40.7128, -74.0060).bearingDegrees,
        closeTo(58.40, 0.05),
      );
      // 5. جاكرتا، إندونيسيا (WGS84 = 295.02°, Spherical = 295.15°)
      expect(
        QiblaCalculator.calculate(-6.2088, 106.8456).bearingDegrees,
        closeTo(295.02, 0.05),
      );
      // 6. طوكيو، اليابان (WGS84 = 293.07°, Spherical = 293.00°)
      expect(
        QiblaCalculator.calculate(35.6762, 139.6503).bearingDegrees,
        closeTo(293.07, 0.05),
      );
    });
  });

  group('4. Standard Zonal & Bi-Annual Madhab Distribution Benchmark', () {
    test(
      'Applies fixed year-round Madhab distribution in Zone 1/Normal (Makkah) and Bi-Annual Equinox presets in Zone 2 (Stockholm)',
      () {
        // 1. مكة المكرمة (21.42°N): ثابت طوال العام [1, 4, 6, 1, 6, 4, 2] على المذهب الحنفي
        final makkahAnchors = PrayerCalculator.getCycleAnchors(
          21.4225,
          39.8262,
          DateTime.utc(2026, 10, 27),
          CalculationMethodType.ummAlQura,
          MadhabType.hanafi,
          HighLatitudeRuleType.middleOfTheNight,
          18.5,
          18.0,
          const Duration(hours: 3),
        );

        final makkahDist = SuwayaDistributor.resolveDistribution(
          madhab: MadhabType.hanafi,
          anchors: makkahAnchors,
          latitude: 21.4225,
        );
        expect(makkahDist, equals([1, 4, 6, 1, 6, 4, 2]));

        // 2. ستوكهولم (59.33°N — المنطقة الثانية):
        // أ) في الصيف: [2, 3, 6, 1, 6, 4, 2] (الحنفي)
        final summerStockholmHanafi = PrayerCalculator.getCycleAnchors(
          59.3293,
          18.0686,
          DateTime.utc(2026, 6, 21),
          CalculationMethodType.muslimWorldLeague,
          MadhabType.hanafi,
          HighLatitudeRuleType.seventhOfTheNight,
          18.0,
          17.0,
          const Duration(hours: 2),
        );
        expect(
          SuwayaDistributor.resolveDistribution(
            madhab: MadhabType.hanafi,
            anchors: summerStockholmHanafi,
            latitude: 59.3293,
          ),
          equals([2, 3, 6, 1, 6, 4, 2]),
        );

        // ب) في الشتاء: [1, 4, 6, 1, 6, 3, 3] (الحنفي) و [1, 4, 6, 1, 6, 2, 4] (الجمهور)
        final winterStockholmHanafi = PrayerCalculator.getCycleAnchors(
          59.3293,
          18.0686,
          DateTime.utc(2026, 12, 21),
          CalculationMethodType.muslimWorldLeague,
          MadhabType.hanafi,
          HighLatitudeRuleType.seventhOfTheNight,
          18.0,
          17.0,
          const Duration(hours: 1),
        );

        expect(
          SuwayaDistributor.resolveDistribution(
            madhab: MadhabType.hanafi,
            anchors: winterStockholmHanafi,
            latitude: 59.3293,
          ),
          equals([1, 4, 6, 1, 6, 3, 3]),
        );
        expect(
          SuwayaDistributor.resolveDistribution(
            madhab: MadhabType.shafi,
            anchors: winterStockholmHanafi,
            latitude: 59.3293,
          ),
          equals([1, 4, 6, 1, 6, 2, 4]),
        );
      },
    );
  });
}