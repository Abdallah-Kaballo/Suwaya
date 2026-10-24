import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya/features/home/widgets/dial/period_metrics.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  group('PeriodMetrics V2 (60 Virtual Minutes per Suwaya)', () {
    test('calculates 1.00x flow speed when 1 Suwaya lasts 60 real minutes', () {
      final period = AstroPeriod(
        id: 3,
        periodKey: PeriodKey.nightMidnightFajr,
        nameKey: 'ibadat.qiyam_tab',
        startTime: DateTime.utc(2026, 10, 16, 0, 0),
        endTime: DateTime.utc(2026, 10, 16, 6, 0), // 6 ساعات لـ 6 سويعات
        suwayasCount: 6,
        colorValue: 0xFF1A237E,
      );

      final metrics = PeriodMetrics.fromPeriod(period);
      expect(metrics.suwayaCount, 6);
      expect(metrics.actualSuwayaDuration, const Duration(minutes: 60));
      expect(metrics.flowSpeed, closeTo(1.0, 0.001));
    });

    test('calculates 2.00x flow speed when 1 Suwaya lasts 30 real minutes', () {
      final period = AstroPeriod(
        id: 4,
        periodKey: PeriodKey.nightFajrSunrise,
        nameKey: 'periods.fajr',
        startTime: DateTime.utc(2026, 10, 16, 5, 0),
        endTime: DateTime.utc(2026, 10, 16, 5, 30), // 30 دقيقة لسويعة واحدة
        suwayasCount: 1,
        colorValue: 0xFF64B5F6,
      );

      final metrics = PeriodMetrics.fromPeriod(period);
      expect(metrics.suwayaCount, 1);
      expect(metrics.actualSuwayaDuration, const Duration(minutes: 30));
      expect(metrics.flowSpeed, closeTo(2.0, 0.001));
    });

    test('returns zero metrics safely when suwayasCount is 0', () {
      final period = AstroPeriod(
        id: 1,
        periodKey: PeriodKey.nightMaghribIsha,
        nameKey: 'periods.maghrib',
        startTime: DateTime.utc(2026, 10, 16, 18, 0),
        endTime: DateTime.utc(2026, 10, 16, 19, 0),
        suwayasCount: 0,
        colorValue: 0xFFE53935,
      );

      final metrics = PeriodMetrics.fromPeriod(period);
      expect(metrics.suwayaCount, 0);
      expect(metrics.actualSuwayaDuration, Duration.zero);
      expect(metrics.flowSpeed, 0);
    });
  });
}
