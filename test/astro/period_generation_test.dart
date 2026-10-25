import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  test(
    'Period generation creates exactly 7 continuous periods totaling 24 suwayas',
    () {
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

      final distribution = SuwayaDistributor.getDistributionForMadhab(
        MadhabType.shafi,
      );
      final periods = PeriodGenerator.generatePeriods(anchors, distribution);

      expect(periods.length, 7);

      // Check continuity
      for (int i = 0; i < periods.length - 1; i++) {
        expect(periods[i].endTime, equals(periods[i + 1].startTime));
      }

      // Total suwayas should be 24
      int totalSuwayas = periods.fold(0, (sum, p) => sum + p.suwayasCount);
      expect(totalSuwayas, 24);
    },
  );
}
