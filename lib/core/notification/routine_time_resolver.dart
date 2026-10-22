import 'package:suwaya_time/suwaya_time.dart';
import '../../models/routine_model.dart';

DateTime resolveAstroRoutineTime({
  required AstroPeriod period,
  required int localSuwaya,
  required int virtualMinute,
  DateTime Function(DateTime utcInstant)? toWallClock,
}) {
  return period.resolveSlotWallTime(
    localSuwaya,
    virtualMinute,
    toWallClock: toWallClock,
  );
}

String buildRoutineScheduleFingerprint(Iterable<RoutineModel> routines) {
  final buffer = StringBuffer();
  for (final routine in routines) {
    buffer.write('${routine.id}_${routine.title}_${routine.isActive}_'
        '${routine.isAstroTime}_${routine.scheduleModelVersion}_' // 🌟 تضمين الإصدار في البصمة
        '${routine.alertLevel}_${routine.startPeriodId}_'
        '${routine.startSuwaya}_${routine.startVirtualMinute}_'
        '${routine.startTimeMinutes}_${routine.endPeriodId}_'
        '${routine.endSuwaya}_${routine.endVirtualMinute}_'
        '${routine.endTimeMinutes}_${routine.recurrenceDays}_'
        '${routine.alarmTone}_${routine.alarmVolume}');
  }
  return buffer.toString();
}