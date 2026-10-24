import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  test('AstroState returns correct virtual time string', () {
    final now = DateTime(2023, 1, 1, 12, 0);

    final clockTime = SuwayaClockTime(
      phase: SuwayaPhase.day,
      phaseSlotNumber: 6,
      periodKey: PeriodKey.daySunriseDhuhr,
      periodLocalSlotNumber: 6,
      slotProgress: 0.5,
      cycleStartDate: now.subtract(const Duration(hours: 12)),
      instant: now,
    );

    expect(clockTime.virtualMinute, 30);
  });
}
