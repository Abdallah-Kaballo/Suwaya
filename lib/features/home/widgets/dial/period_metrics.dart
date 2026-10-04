import 'package:suwaya_time/suwaya_time.dart';

class PeriodMetrics {
  final int suwayaCount;
  final Duration actualSuwayaDuration;
  final double flowSpeed;

  const PeriodMetrics({
    required this.suwayaCount,
    required this.actualSuwayaDuration,
    required this.flowSpeed,
  });

  factory PeriodMetrics.fromPeriod(AstroPeriod period) {
    if (period.suwayasCount <= 0) {
      return const PeriodMetrics(
        suwayaCount: 0,
        actualSuwayaDuration: Duration.zero,
        flowSpeed: 0,
      );
    }

    final actualMicroseconds =
        period.totalDuration.inMicroseconds ~/ period.suwayasCount;
    if (actualMicroseconds <= 0) {
      return PeriodMetrics(
        suwayaCount: period.suwayasCount,
        actualSuwayaDuration: Duration.zero,
        flowSpeed: 0,
      );
    }
    return PeriodMetrics(
      suwayaCount: period.suwayasCount,
      actualSuwayaDuration: Duration(microseconds: actualMicroseconds),
      flowSpeed: 1800 / (actualMicroseconds / Duration.microsecondsPerSecond),
    );
  }
}
