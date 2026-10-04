import 'package:intl/intl.dart';

String formatCivilRoutineTime(int minutes, String locale) {
  final safeLocale = locale == 'ff' || locale == 'ug' ? 'en' : locale;
  final time = DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60);
  return DateFormat('HH:mm', safeLocale).format(time);
}

String? formatRoutineRecurrence(List<int>? days, String locale) {
  if (days == null || days.isEmpty) return null;

  final safeLocale = locale == 'ff' || locale == 'ug' ? 'en' : locale;
  final monday = DateTime(2024, 1, 1);
  final orderedDays = days.toSet().where((day) => day >= 1 && day <= 7).toList()
    ..sort();
  return orderedDays
      .map((day) => DateFormat('EEE', safeLocale)
          .format(monday.add(Duration(days: day - 1))))
      .join(', ');
}
