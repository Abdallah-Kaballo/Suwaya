import 'package:test/test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('Phase 1 & 2: Strict Primitives & Bi-Directional Coordinate Mapper', () {
    test('1. Round-trip identity across all 1,440 virtual minutes (including DST Spring-Forward night)', () {
      // ليلة قفزة التوقيت الصيفي في نيويورك (8 مارس 2026)
      final ctx = TemporalContextEngine.evaluate(
        instantUtc: DateTime.utc(2026, 3, 8, 1, 0),
        latitude: 40.7128,
        longitude: -74.0060,
        timezoneId: 'America/New_York',
        methodType: CalculationMethodType.northAmerica,
      );

      final day = ctx.suwayaDay;

      for (int globalSlot = 0; globalSlot < 24; globalSlot++) {
        for (int vMin = 0; vMin < 60; vMin++) {
          final resolved = SuwayaCoordinateMapper.coordinateToInstant(
            day: day,
            globalSlotIndex: globalSlot,
            virtualMinute: vMin,
            toWallClock: (u) =>
                TimezoneResolver.toWallClock(u, timezoneId: 'America/New_York'),
          );

          final roundTrip = SuwayaCoordinateMapper.instantToCoordinate(
            day: day,
            instant: resolved.wallTime,
            instantUtc: resolved.instantUtc,
          );

          expect(
            roundTrip.globalSlotIndex,
            equals(globalSlot),
            reason: 'Slot mismatch at globalSlot=$globalSlot, vMin=$vMin',
          );
          expect(
            roundTrip.virtualMinute,
            equals(vMin),
            reason: 'Virtual minute mismatch at globalSlot=$globalSlot, vMin=$vMin',
          );
        }
      }
    });

    test('2. Global <-> Local slot mapping is symmetric for both Shafi and Hanafi distributions', () {
      for (final madhab in MadhabType.values) {
        final ctx = TemporalContextEngine.evaluate(
          instantUtc: DateTime.utc(2026, 10, 22, 12, 0),
          latitude: 21.4225,
          longitude: 39.8262,
          timezoneId: 'Asia/Riyadh',
          methodType: CalculationMethodType.ummAlQura,
          madhabType: madhab,
        );

        final periods = ctx.suwayaDay.periods;
        for (int g = 0; g < 24; g++) {
          final local = SuwayaCoordinateMapper.globalToLocal(g, periods);
          final backToGlobal = SuwayaCoordinateMapper.localToGlobal(
            local.periodId,
            local.localSuwaya,
            periods,
          );
          expect(backToGlobal, equals(g));
        }
      }
    });

    test('3. ZonedWallTime preserves exact physical duration across DST shift', () {
      final beforeDst = ZonedWallTime.fromInstant(
        InstantUtc.fromDateTime(DateTime.utc(2026, 3, 8, 6, 0)), // 01:00 EST (-5)
        timezoneId: 'America/New_York',
      );
      final afterDst = ZonedWallTime.fromInstant(
        InstantUtc.fromDateTime(DateTime.utc(2026, 3, 8, 8, 0)), // 04:00 EDT (-4)
        timezoneId: 'America/New_York',
      );

      // الفرق على ساعة الحائط يبدو 3 ساعات (من 1:00 إلى 4:00)، لكن الفرق الفيزيائي الفعلي ساعتان فقط
      expect(afterDst.hour - beforeDst.hour, equals(3));
      expect(afterDst.realDifference(beforeDst), equals(const Duration(hours: 2)));
    });
  });
}