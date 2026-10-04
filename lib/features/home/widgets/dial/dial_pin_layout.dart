import 'dart:math' as math;

import 'package:suwaya_time/suwaya_time.dart';

import 'dial_constants.dart';

class CivilDialPin {
  final int hour;
  final double angle;

  const CivilDialPin({required this.hour, required this.angle});
}

class SuwayaPinRadiusBand {
  final double innerRadius;
  final double outerRadius;

  const SuwayaPinRadiusBand({
    required this.innerRadius,
    required this.outerRadius,
  });
}

SuwayaPinRadiusBand buildSuwayaPinRadiusBand(double dialRadius) {
  final outerRadius = dialRadius * kRailwayR;
  return SuwayaPinRadiusBand(
    innerRadius: outerRadius - dialRadius * 0.015,
    outerRadius: outerRadius,
  );
}

List<CivilDialPin> buildCivilDialPins(DateTime dayStart, DateTime dayEnd) {
  final firstHour = dayStart.isUtc
      ? DateTime.utc(dayStart.year, dayStart.month, dayStart.day, dayStart.hour)
      : DateTime(dayStart.year, dayStart.month, dayStart.day, dayStart.hour);
  final firstPinTime = firstHour.isBefore(dayStart)
      ? firstHour.add(const Duration(hours: 1))
      : firstHour;

  return List.generate(24, (index) {
    final time = firstPinTime.add(Duration(hours: index));
    return CivilDialPin(
      hour: time.hour,
      angle: timeToAngle(time, dayStart, dayEnd),
    );
  });
}

List<double> buildSuwayaPinAngles(
  List<AstroPeriod> periods,
  DateTime dayStart,
  DateTime dayEnd,
) {
  final angles = <double>[];
  for (final period in periods) {
    if (period.suwayasCount <= 0) continue;
    final startAngle = timeToAngle(period.startTime, dayStart, dayEnd);
    final endAngle = timeToAngle(period.endTime, dayStart, dayEnd);
    var sweepAngle = endAngle - startAngle;
    if (sweepAngle <= 0) sweepAngle += 2 * math.pi;
    final pinStep = sweepAngle / period.suwayasCount;
    for (var index = 0; index < period.suwayasCount; index++) {
      angles.add(startAngle + index * pinStep);
    }
  }
  return angles;
}
