import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya/features/home/widgets/dial/period_metrics.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  test('calculates metrics from the selected period duration and count', () {
    final period = AstroPeriod(
      id: 2,
      name: 'Period',
      nameKey: 'period',
      startTime: DateTime.utc(2026, 1, 1),
      endTime: DateTime.utc(2026, 1, 1, 2),
      suwayasCount: 4,
      colorValue: 0xFFFFFFFF,
    );

    final metrics = PeriodMetrics.fromPeriod(period);

    expect(metrics.suwayaCount, 4);
    expect(metrics.actualSuwayaDuration, const Duration(minutes: 30));
    expect(metrics.flowSpeed, 1);
  });

  test('returns zero speed when the period has no Suwayas', () {
    final period = AstroPeriod(
      id: 1,
      name: 'Empty',
      nameKey: 'empty',
      startTime: DateTime.utc(2026, 1, 1),
      endTime: DateTime.utc(2026, 1, 1, 2),
      suwayasCount: 0,
      colorValue: 0xFFFFFFFF,
    );

    final metrics = PeriodMetrics.fromPeriod(period);

    expect(metrics.suwayaCount, 0);
    expect(metrics.actualSuwayaDuration, Duration.zero);
    expect(metrics.flowSpeed, 0);
  });
}
