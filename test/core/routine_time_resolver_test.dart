import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya_time/suwaya_time.dart';
import 'package:suwaya/core/notification/routine_time_resolver.dart';

void main() {
  test('resolveAstroRoutineTime calculates exact mid-suwaya time', () {
    final start = DateTime(2023, 1, 1, 12, 0);
    final end = start.add(const Duration(hours: 1)); // 60 minutes
    
    final period = AstroPeriod(
      id: 1,
      periodKey: PeriodKey.daySunriseDhuhr,
      nameKey: 'test',
      startTime: start,
      endTime: end,
      suwayasCount: 1,
      colorValue: 0,
    );

    // Test exactly halfway through the period (minute 30 of 60)
    final resolved = resolveAstroRoutineTime(
      period: period,
      localSuwaya: 1,
      virtualMinute: 30,
    );

    expect(resolved, equals(start.add(const Duration(minutes: 30))));
  });
}