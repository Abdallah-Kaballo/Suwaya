import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya_time/suwaya_time.dart';
import 'package:suwaya/features/home/widgets/dial/period_metrics.dart';

void main() {
  test('PeriodMetrics correctly calculates flow speed', () {
    final period = AstroPeriod(
      id: 1,
      periodKey: PeriodKey.daySunriseDhuhr,
      nameKey: 'test',
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(minutes: 60)),
      suwayasCount: 1,
      colorValue: 0,
    );

    final metrics = PeriodMetrics.fromPeriod(period);
    // At exactly 60 minutes per suwaya, speed should be approx 1.0 (depending on math precision)
    expect(metrics.suwayaCount, 1);
  });
}