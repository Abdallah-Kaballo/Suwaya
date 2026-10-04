import 'package:suwaya_time/suwaya_time.dart';
import '../../models/routine_model.dart';

DateTime resolveAstroRoutineTime({
  required AstroPeriod period,
  required int localSuwaya,
  required int virtualMinute,
}) {
  final count = period.suwayasCount > 0 ? period.suwayasCount : 1;
  final suwayaIndex = (localSuwaya - 1).clamp(0, count - 1);
  final minute = virtualMinute.clamp(0, 29);
  final periodDuration = period.totalDuration.inMicroseconds;
  final denominator = count * 30;
  final requestedUnits = suwayaIndex * 30 + minute;
  final numerator = periodDuration * requestedUnits;
  final offsetMicroseconds = (numerator + denominator - 1) ~/ denominator;

  return period.startTime.add(Duration(microseconds: offsetMicroseconds));
}

String buildRoutineScheduleFingerprint(Iterable<RoutineModel> routines) {
  final buffer = StringBuffer();
  for (final routine in routines) {
    buffer.write('${routine.id}_${routine.title}_${routine.isActive}_'
        '${routine.isAstroTime}_'
        '${routine.alertLevel}_${routine.startPeriodId}_'
        '${routine.startSuwaya}_${routine.startVirtualMinute}_'
        '${routine.startTimeMinutes}_${routine.endPeriodId}_'
        '${routine.endSuwaya}_${routine.endVirtualMinute}_'
        '${routine.endTimeMinutes}_${routine.recurrenceDays}_'
        '${routine.alarmTone}_${routine.alarmVolume}');
  }
  return buffer.toString();
}
