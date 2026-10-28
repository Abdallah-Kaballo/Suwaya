import 'package:test/test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('Zonal & Bi-Annual Equinox Distribution System (Fiqh Academy Zones 1, 2, 3)', () {
    test(
      '1. Exact latitude boundary classification (45.00°, 48.56°, 66.56°)',
      () {
        expect(SuwayaDistributor.zone1StartLatitude, equals(45.00));
        expect(SuwayaDistributor.zone2TwilightLimitLatitude, equals(48.56));
        expect(SuwayaDistributor.zone3PolarCircleLatitude, equals(66.56));

        // مكة (21.42°) وأم درمان (15.64°) -> المنطقة الطبيعية
        expect(
          SuwayaDistributor.classifyLatitudeZone(21.4225),
          equals(SuwayaLatitudeZone.normalTemperate),
        );

        // ميلانو (45.46°) وميونخ (48.13°) وخط 48.56° -> المنطقة الأولى (ثابت سنوياً)
        expect(
          SuwayaDistributor.classifyLatitudeZone(45.00),
          equals(SuwayaLatitudeZone.highLatZone1Canonical),
        );
        expect(
          SuwayaDistributor.classifyLatitudeZone(48.56),
          equals(SuwayaLatitudeZone.highLatZone1Canonical),
        );

        // باريس (48.85°)، لندن (51.50°)، برلين (52.52°)، ستوكهولم (59.33°) -> المنطقة الثانية (تقسيمتان سنويتان)
        expect(
          SuwayaDistributor.classifyLatitudeZone(48.57),
          equals(SuwayaLatitudeZone.highLatZone2BiAnnual),
        );
        expect(
          SuwayaDistributor.classifyLatitudeZone(51.5074),
          equals(SuwayaLatitudeZone.highLatZone2BiAnnual),
        );
        expect(
          SuwayaDistributor.classifyLatitudeZone(66.56),
          equals(SuwayaLatitudeZone.highLatZone2BiAnnual),
        );

        // ترومسو (69.65°N) -> المنطقة الثالثة القطبية (تُقاس على 45.00° وتأخذ التوزيع الثابت)
        expect(
          SuwayaDistributor.classifyLatitudeZone(66.57),
          equals(SuwayaLatitudeZone.highLatZone3PolarProjected),
        );
        expect(
          SuwayaDistributor.classifyLatitudeZone(69.6492),
          equals(SuwayaLatitudeZone.highLatZone3PolarProjected),
        );
      },
    );

    test(
      '2. Normal Zone, Zone 1 (<= 48.56°), and Zone 3 (> 66.56°) keep fixed canonical distribution year-round (Summer & Winter)',
      () {
        for (final lat in [21.4225, 47.3769, 69.6492]) {
          for (final date in [
            DateTime.utc(2026, 6, 21),
            DateTime.utc(2026, 12, 21),
          ]) {
            final shafiDay = SuwayaTimeEngine.generateDay(
              lat,
              18.9553,
              date,
              CalculationMethodType.muslimWorldLeague,
              MadhabType.shafi,
              HighLatitudeRuleType.seventhOfTheNight,
              18.0,
              17.0,
              const Duration(hours: 2),
            );
            expect(
              shafiDay.periods.map((p) => p.suwayasCount).toList(),
              equals([1, 4, 6, 1, 6, 3, 3]),
              reason: 'Shafi distribution must be fixed at lat=$lat on $date',
            );

            final hanafiDay = SuwayaTimeEngine.generateDay(
              lat,
              18.9553,
              date,
              CalculationMethodType.muslimWorldLeague,
              MadhabType.hanafi,
              HighLatitudeRuleType.seventhOfTheNight,
              18.0,
              17.0,
              const Duration(hours: 2),
            );
            expect(
              hanafiDay.periods.map((p) => p.suwayasCount).toList(),
              equals([1, 4, 6, 1, 6, 4, 2]),
              reason: 'Hanafi distribution must be fixed at lat=$lat on $date',
            );
          }
        }
      },
    );

    test(
      '3. Zone 2 (48.56° < |lat| <= 66.56°) switches cleanly between Summer and Winter presets at the Equinoxes (Northern & Southern Hemispheres)',
      () {
        // 1. لندن (51.5074°N — نصف الكرة الشمالي):
        // أ) النصف الصيفي (بعد الاعتدال الربيعي: يونيو)
        final londonSummerShafi = SuwayaTimeEngine.generateDay(
          51.5074,
          -0.1278,
          DateTime.utc(2026, 6, 21),
          CalculationMethodType.muslimWorldLeague,
          MadhabType.shafi,
          HighLatitudeRuleType.seventhOfTheNight,
          18.0,
          17.0,
          const Duration(hours: 1),
        );
        final londonSummerHanafi = SuwayaTimeEngine.generateDay(
          51.5074,
          -0.1278,
          DateTime.utc(2026, 6, 21),
          CalculationMethodType.muslimWorldLeague,
          MadhabType.hanafi,
          HighLatitudeRuleType.seventhOfTheNight,
          18.0,
          17.0,
          const Duration(hours: 1),
        );

        expect(
          londonSummerShafi.periods.map((p) => p.suwayasCount).toList(),
          equals([2, 3, 6, 1, 6, 3, 3]),
        );
        expect(
          londonSummerHanafi.periods.map((p) => p.suwayasCount).toList(),
          equals([2, 3, 6, 1, 6, 4, 2]),
        );

        // ب) النصف الشتوي (بعد الاعتدال الخريفي: ديسمبر)
        final londonWinterShafi = SuwayaTimeEngine.generateDay(
          51.5074,
          -0.1278,
          DateTime.utc(2026, 12, 21),
          CalculationMethodType.muslimWorldLeague,
          MadhabType.shafi,
          HighLatitudeRuleType.seventhOfTheNight,
          18.0,
          17.0,
          Duration.zero,
        );
        final londonWinterHanafi = SuwayaTimeEngine.generateDay(
          51.5074,
          -0.1278,
          DateTime.utc(2026, 12, 21),
          CalculationMethodType.muslimWorldLeague,
          MadhabType.hanafi,
          HighLatitudeRuleType.seventhOfTheNight,
          18.0,
          17.0,
          Duration.zero,
        );

        expect(
          londonWinterShafi.periods.map((p) => p.suwayasCount).toList(),
          equals([1, 4, 6, 1, 6, 2, 4]),
        );
        expect(
          londonWinterHanafi.periods.map((p) => p.suwayasCount).toList(),
          equals([1, 4, 6, 1, 6, 3, 3]),
        );

        // 2. بونتا أريناس، تشيلي (-53.15°S — نصف الكرة الجنوبي):
        // في يونيو يكون شتاءً في نصف الكرة الجنوبي، وفي ديسمبر يكون صيفاً!
        final chileJuneWinterShafi = SuwayaTimeEngine.generateDay(
          -53.1500,
          -70.9070,
          DateTime.utc(2026, 6, 21),
          CalculationMethodType.muslimWorldLeague,
          MadhabType.shafi,
          HighLatitudeRuleType.seventhOfTheNight,
          18.0,
          17.0,
          const Duration(hours: -3),
        );
        final chileJuneWinterHanafi = SuwayaTimeEngine.generateDay(
          -53.1500,
          -70.9070,
          DateTime.utc(2026, 6, 21),
          CalculationMethodType.muslimWorldLeague,
          MadhabType.hanafi,
          HighLatitudeRuleType.seventhOfTheNight,
          18.0,
          17.0,
          const Duration(hours: -3),
        );
        final chileDecSummerShafi = SuwayaTimeEngine.generateDay(
          -53.1500,
          -70.9070,
          DateTime.utc(2026, 12, 21),
          CalculationMethodType.muslimWorldLeague,
          MadhabType.shafi,
          HighLatitudeRuleType.seventhOfTheNight,
          18.0,
          17.0,
          const Duration(hours: -3),
        );
        final chileDecSummerHanafi = SuwayaTimeEngine.generateDay(
          -53.1500,
          -70.9070,
          DateTime.utc(2026, 12, 21),
          CalculationMethodType.muslimWorldLeague,
          MadhabType.hanafi,
          HighLatitudeRuleType.seventhOfTheNight,
          18.0,
          17.0,
          const Duration(hours: -3),
        );

        expect(
          chileJuneWinterShafi.periods.map((p) => p.suwayasCount).toList(),
          equals([1, 4, 6, 1, 6, 2, 4]),
        );
        expect(
          chileJuneWinterHanafi.periods.map((p) => p.suwayasCount).toList(),
          equals([1, 4, 6, 1, 6, 3, 3]),
        );
        expect(
          chileDecSummerShafi.periods.map((p) => p.suwayasCount).toList(),
          equals([2, 3, 6, 1, 6, 3, 3]),
        );
        expect(
          chileDecSummerHanafi.periods.map((p) => p.suwayasCount).toList(),
          equals([2, 3, 6, 1, 6, 4, 2]),
        );
      },
    );

    test(
      '4. Fixed boundary coordinates (Isha, Qiyam, Fajr, Dhuhr, Asr) adapt seamlessly in Zone 2 Summer & Winter',
      () {
        final berlinWinterShafi = SuwayaTimeEngine.generateDay(
          52.5200,
          13.4050,
          DateTime.utc(2026, 12, 21),
          CalculationMethodType.muslimWorldLeague,
          MadhabType.shafi,
          HighLatitudeRuleType.seventhOfTheNight,
          18.0,
          17.0,
          const Duration(hours: 1),
        );

        // في شتاء المنطقة الثانية للجمهور [1, 4, 6, 1, 6, 2, 4]:
        // العشاء عند السويعة 2 ليلاً (globalIndex = 1)، الظهر عند السويعة 7 نهاراً (globalIndex = 18)، والعصر عند السويعة 9 نهاراً (globalIndex = 20)
        expect(
          SuwayaCoordinateMapper.fixedBoundaryCoordinate(
            'isha',
            berlinWinterShafi.periods,
          ).globalIndex,
          equals(1),
        );
        expect(
          SuwayaCoordinateMapper.fixedBoundaryCoordinate(
            'qiyam',
            berlinWinterShafi.periods,
          ).globalIndex,
          equals(5),
        );
        expect(
          SuwayaCoordinateMapper.fixedBoundaryCoordinate(
            'dhuhr',
            berlinWinterShafi.periods,
          ).globalIndex,
          equals(18),
        );
        expect(
          SuwayaCoordinateMapper.fixedBoundaryCoordinate(
            'asr',
            berlinWinterShafi.periods,
          ).globalIndex,
          equals(20),
        );
      },
    );
  });
}