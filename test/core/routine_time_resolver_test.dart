import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya/core/notification/routine_time_resolver.dart';
import 'package:suwaya/models/routine_model.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  group('resolveAstroRoutineTime (V2 - 60 Virtual Minutes)', () {
    final period = AstroPeriod(
      id: 3,
      periodKey: PeriodKey.nightMidnightFajr,
      nameKey: 'ibadat.qiyam_tab',
      startTime: DateTime.utc(2026, 10, 16, 0, 0),
      endTime: DateTime.utc(2026, 10, 16, 6, 0), // 6 ساعات = 6 سويعات (كل سويعة 60 دقيقة فعلية)
      suwayasCount: 6,
      colorValue: 0xFF1A237E,
    );

    test('resolves start of first Suwaya (localSuwaya: 1, virtualMinute: 0)', () {
      final resolved = resolveAstroRoutineTime(
        period: period,
        localSuwaya: 1,
        virtualMinute: 0,
      );
      expect(resolved, DateTime.utc(2026, 10, 16, 0, 0));
    });

    test('resolves midpoint of 3rd Suwaya (localSuwaya: 3, virtualMinute: 30)', () {
      final resolved = resolveAstroRoutineTime(
        period: period,
        localSuwaya: 3,
        virtualMinute: 30,
      );
      // السويعة 3 تبدأ الساعة 02:00، والدقيقة 30 تعني 02:30
      expect(resolved, DateTime.utc(2026, 10, 16, 2, 30));
    });

    test('clamps out-of-range virtualMinute to 59', () {
      final resolved = resolveAstroRoutineTime(
        period: period,
        localSuwaya: 1,
        virtualMinute: 95,
      );
      expect(resolved, DateTime.utc(2026, 10, 16, 0, 59));
    });

    test('buildRoutineScheduleFingerprint includes scheduleModelVersion', () {
      final r1 = RoutineModel()
        ..id = 1
        ..title = 'Reading'
        ..scheduleModelVersion = 1;
      final r2 = RoutineModel()
        ..id = 1
        ..title = 'Reading'
        ..scheduleModelVersion = 2;

      expect(
        buildRoutineScheduleFingerprint([r1]),
        isNot(equals(buildRoutineScheduleFingerprint([r2]))),
      );
    });
  });
}