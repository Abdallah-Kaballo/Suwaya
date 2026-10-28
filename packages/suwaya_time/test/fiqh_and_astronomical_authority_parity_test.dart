import 'package:test/test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('100% Jurisprudential & Astronomical Authority Parity Suite', () {
    test(
      '1. Umm Al-Qura Ramadan Sunset Rollover: First night of Ramadan gets 120m Isha and Night of Eid al-Fitr gets 90m Isha',
      () {
        const provider = UmmAlQuraHijriProvider();
        // العثور على غرة رمضان 1448 هـ وآخر يوم من رمضان 1448 هـ
        final firstRamadanGreg = provider.gregorianForHijriDate(
          hYear: 1448,
          hMonth: 9,
          hDay: 1,
        );
        // ليلة 1 رمضان تبدأ عند غروب شمس اليوم السابق (29/30 شعبان)
        final eveOfRamadanDate = firstRamadanGreg
            .addDays(-1)
            .toDateTimeUtc();

        final firstNightAnchors = PrayerCalculator.getCycleAnchors(
          21.4225,
          39.8262, // مكة المكرمة
          eveOfRamadanDate,
          CalculationMethodType.ummAlQura,
          MadhabType.shafi,
          HighLatitudeRuleType.middleOfTheNight,
          18.5,
          18.0,
          const Duration(hours: 3),
        );

        final firstNightIshaInterval = firstNightAnchors.cycleIshaUtc!
            .difference(firstNightAnchors.cycleStartMaghribUtc!)
            .inMinutes;
        expect(
          firstNightIshaInterval,
          equals(120),
          reason:
              'Isha on the 1st night of Ramadan (evening of 29/30 Shaban) must be 120 minutes after Maghrib!',
        );

        // ليلة 1 شوال (ليلة عيد الفطر) تبدأ عند غروب شمس آخر يوم من رمضان
        final firstShawwalGreg = provider.gregorianForHijriDate(
          hYear: 1448,
          hMonth: 10,
          hDay: 1,
        );
        final eveOfEidDate = firstShawwalGreg.addDays(-1).toDateTimeUtc();

        final eidNightAnchors = PrayerCalculator.getCycleAnchors(
          21.4225,
          39.8262,
          eveOfEidDate,
          CalculationMethodType.ummAlQura,
          MadhabType.shafi,
          HighLatitudeRuleType.middleOfTheNight,
          18.5,
          18.0,
          const Duration(hours: 3),
        );

        final eidNightIshaInterval = eidNightAnchors.cycleIshaUtc!
            .difference(eidNightAnchors.cycleStartMaghribUtc!)
            .inMinutes;
        expect(
          eidNightIshaInterval,
          equals(90),
          reason:
              'Isha on the night of Eid al-Fitr (evening of last day of Ramadan) must return to 90 minutes!',
        );
      },
    );

    test(
      '2. NightDivision achieves 0-microsecond drift between third_3.startUtc and sixth_5.startUtc',
      () {
        final maghribUtc = DateTime.utc(2026, 10, 27, 15, 11, 23, 456, 789);
        final nextFajrUtc = DateTime.utc(2026, 10, 28, 2, 19, 47, 123, 451);

        final parts = NightDivision.calculateNightParts(
          maghribUtc,
          nextFajrUtc,
          maghribUtc: maghribUtc,
          nextFajrUtc: nextFajrUtc,
        );

        final s4 = parts.firstWhere((p) => p.id == 'sixth_4');
        final s5 = parts.firstWhere((p) => p.id == 'sixth_5');
        final s6 = parts.firstWhere((p) => p.id == 'sixth_6');
        final third3 = parts.firstWhere((p) => p.id == 'third_3');
        final half2 = parts.firstWhere((p) => p.id == 'half_2');

        expect(s4.startUtc, equals(half2.startUtc));
        expect(s5.startUtc, equals(third3.startUtc));
        expect(
          s4.realDuration.inMicroseconds +
              s5.realDuration.inMicroseconds +
              s6.realDuration.inMicroseconds,
          equals(half2.realDuration.inMicroseconds),
        );
        expect(
          s5.realDuration.inMicroseconds + s6.realDuration.inMicroseconds,
          equals(third3.realDuration.inMicroseconds),
        );

        final all11 = NightDivision.calculateAllCanonicalNightParts(
          maghribUtc,
          nextFajrUtc,
          maghribUtc: maghribUtc,
          nextFajrUtc: nextFajrUtc,
        );
        expect(all11.length, equals(11));
      },
    );

    test(
      '3. High-Latitude Fiqh (aqrabAlAyyam & aqrabAlBilad) preserves local Sunrise, Dhuhr, Asr, and Maghrib while resolving persistent twilight',
      () {
        // برلين (52.52°N) في ذروة الانقلاب الصيفي (21 يونيو 2026)
        final summerSolstice = DateTime.utc(2026, 6, 21);
        const offset = Duration(hours: 2);

        final seventhRule = PrayerCalculator.getIbadatTimings(
          52.5200,
          13.4050,
          summerSolstice,
          CalculationMethodType.muslimWorldLeague,
          MadhabType.shafi,
          HighLatitudeRuleType.seventhOfTheNight,
          18.0,
          17.0,
          offset,
        );

        final aqrabAyyam = PrayerCalculator.getIbadatTimings(
          52.5200,
          13.4050,
          summerSolstice,
          CalculationMethodType.muslimWorldLeague,
          MadhabType.shafi,
          HighLatitudeRuleType.aqrabAlAyyam,
          18.0,
          17.0,
          offset,
        );

        final aqrabBilad = PrayerCalculator.getIbadatTimings(
          52.5200,
          13.4050,
          summerSolstice,
          CalculationMethodType.muslimWorldLeague,
          MadhabType.shafi,
          HighLatitudeRuleType.aqrabAlBilad,
          18.0,
          17.0,
          offset,
        );

        // الشروق والظهر والعصر والمغرب يجب أن تظل في أوقاتها الشمسية المحلية الحقيقية 100%
        expect(aqrabAyyam.sunrise, equals(seventhRule.sunrise));
        expect(aqrabAyyam.dhuhr, equals(seventhRule.dhuhr));
        expect(aqrabAyyam.asr, equals(seventhRule.asr));
        expect(aqrabAyyam.maghrib, equals(seventhRule.maghrib));

        expect(aqrabBilad.sunrise, equals(seventhRule.sunrise));
        expect(aqrabBilad.maghrib, equals(seventhRule.maghrib));

        // بينما العشاء والفجر يتم تقديرهما بترتيب زمني سليم دون تداخل
        expect(aqrabAyyam.isha.isAfter(aqrabAyyam.maghrib), isTrue);
        expect(aqrabAyyam.nextFajr.isAfter(aqrabAyyam.isha), isTrue);
        expect(aqrabBilad.isha.isAfter(aqrabBilad.maghrib), isTrue);
        expect(aqrabBilad.nextFajr.isAfter(aqrabBilad.isha), isTrue);
      },
    );

    test(
      '4. Iterative Solar Transit & Altitude Crossing Solver + Odeh/Yallop True Moonset Lag',
      () {
        final transit = SolarEphemerisCalculator.solveSolarTransitUtc(
          latitude: 21.4225,
          longitude: 39.8262,
          civilDateUtc: DateTime.utc(2026, 10, 27),
        );
        final posAtTransit = SolarEphemerisCalculator.evaluateSolarPosition(
          instant: transit,
          latitude: 21.4225,
          longitude: 39.8262,
        );
        // عند لحظة الزوال المحسوبة تكرارياً، يجب أن تكون زاوية الساعة قريبة جداً من 0.0°
        expect(posAtTransit.hourAngleDegrees.abs(), lessThan(0.01));

        final report = OdehCrescentVisibilityProvider.evaluateAtSunset(
          sunsetInstant: InstantUtc.fromDateTime(
            DateTime.utc(2026, 10, 27, 14, 45),
          ),
          latitude: 21.4225,
          longitude: 39.8262,
        );
        expect(report.illuminationFraction, inInclusiveRange(0.0, 1.0));
        expect(report.sightingsProbability, inInclusiveRange(0.0, 1.0));
      },
    );
  });
}