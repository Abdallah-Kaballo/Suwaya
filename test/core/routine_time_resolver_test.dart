import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya/core/notification/routine_time_resolver.dart';
import 'package:suwaya/models/routine_model.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  test('resolves the next Suwaya boundary without scheduling early', () {
    final start = DateTime.utc(2026, 10, 5);
    final period = AstroPeriod(
      id: 1,
      name: 'Test period',
      nameKey: 'test',
      startTime: start,
      endTime: start.add(const Duration(microseconds: 10000001)),
      suwayasCount: 7,
      colorValue: 0xFFFFFFFF,
    );

    final boundary = resolveAstroRoutineTime(
      period: period,
      localSuwaya: 2,
      virtualMinute: 0,
    );
    final elapsed = boundary.difference(start).inMicroseconds;

    expect(elapsed * 7, greaterThanOrEqualTo(10000001));
    expect((elapsed - 1) * 7, lessThan(10000001));
  });

  test('resolves 04|00 to the fourth local Suwaya boundary', () {
    final start = DateTime.utc(2026, 10, 5);
    final period = AstroPeriod(
      id: 1,
      name: 'Test period',
      nameKey: 'test',
      startTime: start,
      endTime: start.add(const Duration(hours: 7)),
      suwayasCount: 7,
      colorValue: 0xFFFFFFFF,
    );

    final boundary = resolveAstroRoutineTime(
      period: period,
      localSuwaya: 4,
      virtualMinute: 0,
    );

    expect(boundary, start.add(const Duration(hours: 3)));
  });

  test('round-trips a scheduled boundary as the next Suwaya at minute zero',
      () {
    final start = DateTime.utc(2026, 10, 5);
    final period = AstroPeriod(
      id: 1,
      name: 'Test period',
      nameKey: 'test',
      startTime: start,
      endTime: start.add(const Duration(microseconds: 10000001)),
      suwayasCount: 7,
      colorValue: 0xFFFFFFFF,
    );
    final state = AstroState(
      virtualTime: start,
      periods: [period],
      currentPeriod: period,
      currentSuwaya: 1,
      elapsedVirtualTime: Duration.zero,
      suwayaProgress: 0,
      timeSpeedMultiplier: 1,
      ibadatTimings: IbadatTimings(
        fajr: start,
        sunrise: start,
        dhuhr: start,
        asr: start,
        maghrib: start,
        isha: start,
        nextFajr: start.add(const Duration(days: 1)),
        nightParts: const [],
      ),
      currentFormattedVirtualTime: '00:00',
    );

    final boundary = resolveAstroRoutineTime(
      period: period,
      localSuwaya: 2,
      virtualMinute: 0,
    );

    expect(state.toVirtualTime(boundary), '00:30');
  });

  test('changes in an adjacent Suwaya start invalidate the schedule key', () {
    final routine = RoutineModel()
      ..id = 42
      ..startPeriodId = 3
      ..startSuwaya = 4
      ..startVirtualMinute = 29;
    final beforeEdit = buildRoutineScheduleFingerprint([routine]);

    routine
      ..startSuwaya = 5
      ..startVirtualMinute = 0;

    expect(buildRoutineScheduleFingerprint([routine]), isNot(beforeEdit));
  });
}
