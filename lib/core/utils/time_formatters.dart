import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const civilTimeFormatSystem = 'system';
const civilTimeFormat12Hour = '12-hour';
const civilTimeFormat24Hour = '24-hour';

String formatCivilTime(
  DateTime time, {
  required String format,
  required String locale,
  required BuildContext context,
}) {
  if (format == civilTimeFormatSystem) {
    return TimeOfDay.fromDateTime(time).format(context);
  }

  final safeLocale = locale == 'ff' || locale == 'ug' ? 'en' : locale;
  final pattern = format == civilTimeFormat12Hour ? 'h:mm a' : 'HH:mm';
  return DateFormat(pattern, safeLocale).format(time);
}

String formatSuwayaTime(int globalSuwayaIndex, int minute,
    {String separator = ':'}) {
  final normalizedIndex = globalSuwayaIndex + (minute ~/ 30);
  final normalizedMinute = minute % 30;
  return '${normalizedIndex.toString().padLeft(2, '0')}$separator${normalizedMinute.toString().padLeft(2, '0')}';
}
