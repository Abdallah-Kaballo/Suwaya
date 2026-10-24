import 'package:suwaya_time/suwaya_time.dart';

String formatCivilRoutineTime(int minutes, String locale) {
  final clock = CivilWallClock.fromMinutesSinceMidnight(minutes);
  return SuwayaTimeFormatter.formatCivilRoutineClock(clock, locale);
}

String? formatRoutineRecurrence(List<int>? days, String locale) {
  return SuwayaTimeFormatter.formatRecurrenceDays(days, locale);
}
