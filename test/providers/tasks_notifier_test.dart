import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  test('Tasks Notifier uses updated SuwayaClockTime architecture', () {
    final now = DateTime.now();
    final clockTime = SuwayaClockTime(
      phase: SuwayaPhase.night,
      phaseSlotNumber: 1,
      periodKey: PeriodKey.nightMaghribIsha,
      periodLocalSlotNumber: 1,
      slotProgress: 0.0,
      cycleStartDate: now,
      instant: now,
    );

    expect(clockTime.periodLocalSlotNumber, 1);
  });
}
