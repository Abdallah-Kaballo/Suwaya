import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  test('DST transitions do not cause negative periods', () {
    final now = DateTime.now();
    final anchors = SuwayaCycleAnchors(
      cycleStartMaghrib: now,
      cycleIsha: now.add(const Duration(hours: 1)),
      sharIMidnight: now.add(const Duration(hours: 5)),
      cycleFajr: now.add(const Duration(hours: 10)),
      cycleSunrise: now.add(const Duration(hours: 11)),
      cycleDhuhr: now.add(const Duration(hours: 17)),
      cycleAsr: now.add(const Duration(hours: 20)),
      cycleEndMaghrib: now.add(const Duration(hours: 24)),
    );

    final periods = PeriodGenerator.generatePeriods(
      anchors,
      SuwayaDistributor.getDistributionForMadhab(MadhabType.shafi)
    );

    for (var period in periods) {
      expect(period.totalDuration.inMicroseconds, greaterThanOrEqualTo(0));
    }
  });
}