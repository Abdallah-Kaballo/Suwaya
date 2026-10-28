import 'package:test/test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('Batch 1 & 2 Verification: Ephemeris, Qibla, JSON, and Regional Fiqh', () {
    test(
      '1. Web-safe 47-bit Binary Codec and 48-bit SuwayaCoordinate packing without bitwise overflow',
      () {
        const coord = SuwayaCoordinate(
          globalSlotIndex: 23,
          phase: SuwayaPhase.day,
          phaseSlotNumber: 12,
          periodId: 7,
          periodKey: PeriodKey.dayAsrMaghrib,
          periodLocalSlotNumber: 3,
          virtualMinute: 59,
          virtualSecond: 59,
          slotProgress: 0.999,
        );

        final packedCodec = SuwayaBinaryCodec.pack(
          hijriYear: 1500,
          hijriMonth: 12,
          hijriDay: 30,
          coordinate: coord,
        );
        final unpackedCodec = SuwayaBinaryCodec.unpack(packedCodec);
        expect(unpackedCodec.hijriYear, equals(1500));
        expect(unpackedCodec.hijriMonth, equals(12));
        expect(unpackedCodec.hijriDay, equals(30));
        expect(unpackedCodec.coordinate, equals(coord));

        final packedInt64 = coord.toPackedInt64(
          cycleYear: 1448,
          cycleMonth: 9,
          cycleDay: 27,
        );
        final unpackedInt64 = SuwayaCoordinate.unpackInt64(packedInt64);
        expect(unpackedInt64.cycleYear, equals(1448));
        expect(unpackedInt64.cycleMonth, equals(9));
        expect(unpackedInt64.cycleDay, equals(27));
        expect(unpackedInt64.globalSlotIndex, equals(23));
        expect(unpackedInt64.virtualMinute, equals(59));
        expect(unpackedInt64.virtualSecond, equals(59));
      },
    );

    test(
      '2. Complete JSON round-trip (toJson / fromJson) for SuwayaTemporalContext & AstroState',
      () {
        final ctx = TemporalContextEngine.evaluate(
          instantUtc: DateTime.utc(2026, 10, 27, 9, 0),
          latitude: 15.6445,
          longitude: 32.4777, // أم درمان، السودان
          elevationMeters: 390.0,
          timezoneId: 'Africa/Khartoum',
          methodType: CalculationMethodType.egyptian,
        );

        final jsonMap = ctx.toJson();
        final restored = SuwayaTemporalContext.fromJson(jsonMap);

        expect(restored.civilDate, equals(ctx.civilDate));
        expect(restored.hijriDate.year, equals(ctx.hijriDate.year));
        expect(restored.hijriDate.month, equals(ctx.hijriDate.month));
        expect(restored.hijriDate.day, equals(ctx.hijriDate.day));
        expect(
          restored.astroState.currentPeriod.id,
          equals(ctx.astroState.currentPeriod.id),
        );
        expect(
          restored.astroState.currentSuwayaTime.phaseSlotNumber,
          equals(ctx.astroState.currentSuwayaTime.phaseSlotNumber),
        );
      },
    );

    test('3. WGS84 Ellipsoidal Qibla & Solar Zenith over Kaaba accuracy', () {
      // أم درمان (15.6445°N, 32.4777°E) -> القبلة الجيوديسية WGS84 = 49.3809° (والكروية = 49.2117°)
      final omdurmanQibla = QiblaCalculator.calculate(15.6445, 32.4777);
      expect(omdurmanQibla.bearingDegrees, closeTo(49.38, 0.05));
      expect(omdurmanQibla.sphericalBearingDegrees, closeTo(49.21, 0.05));
      expect(omdurmanQibla.distanceKilometers, closeTo(1005.0, 15.0));

      // التحقق من تعامد الشمس على الكعبة المشرفة يوم 28 مايو الساعة 09:18 UTC
      final zeniths = QiblaCalculator.annualKaabaSolarZeniths(2026);
      final sunAtKaabaZenith = SolarEphemerisCalculator.evaluateSolarPosition(
        instant: zeniths.firstZenithUtc,
        latitude: QiblaCalculator.kaabaLatitude,
        longitude: QiblaCalculator.kaabaLongitude,
      );

      // عند التعامد، تكون زاوية ارتفاع الشمس في مكة ~89.8° إلى 90.0°
      expect(sunAtKaabaZenith.apparentAltitudeDegrees, greaterThan(89.5));
    });

    test(
      '4. ProhibitedTimesCalculator computes dynamic spear-height (+3.5°), zenith, and sunset windows',
      () {
        final ctx = TemporalContextEngine.evaluate(
          instantUtc: DateTime.utc(2026, 6, 21, 9, 0),
          latitude: 30.0444,
          longitude: 31.2357,
          timezoneId: 'Africa/Cairo',
          methodType: CalculationMethodType.egyptian,
        );

        final prohibited = SolarEphemerisCalculator.calculateProhibitedTimes(
          latitude: 30.0444,
          longitude: 31.2357,
          ibadat: ctx.suwayaDay.civilDayIbadat,
          utcOffset: ctx.timezone.utcOffset,
        );

        final postSunriseMins = prohibited.postSunriseEnd
            .difference(prohibited.postSunriseStart)
            .inMinutes;
        expect(postSunriseMins, inInclusiveRange(12, 30));

        final duringIshraq = prohibited.postSunriseStart.add(
          const Duration(minutes: 5),
        );
        expect(prohibited.isInstantProhibited(duringIshraq), isTrue);
      },
    );

    test(
      '5. Regional Calculation Methods (Morocco, JAKIM, Kemenag) & Odeh Crescent Visibility',
      () {
        expect(
          AstroSmartDefaults.getDefaultsForCountry('SD').methodType,
          equals(CalculationMethodType.egyptian),
        );
        expect(
          AstroSmartDefaults.getDefaultsForCountry('MA').methodType,
          equals(CalculationMethodType.morocco),
        );
        expect(
          AstroSmartDefaults.getDefaultsForCountry('MY').methodType,
          equals(CalculationMethodType.malaysiaJakim),
        );
        expect(
          AstroSmartDefaults.getDefaultsForCountry('ID').methodType,
          equals(CalculationMethodType.indonesiaKemenag),
        );

        const odehProvider = OdehCrescentVisibilityProvider(
          observerLatitude: 21.4225,
          observerLongitude: 39.8262,
        );
        final hijri = odehProvider.dateForGregorianDate(
          date: const CivilDate(2026, 10, 27),
        );
        expect(hijri.moonSightingProbability, isNotNull);
        expect(hijri.moonSightingProbability, inInclusiveRange(0.0, 1.0));
      },
    );
  });
}
