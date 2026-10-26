import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:suwaya_time/suwaya_time.dart';

const civilTimeFormatSystem = SuwayaTimeFormatter.civilTimeFormatSystem;
const civilTimeFormat12Hour = SuwayaTimeFormatter.civilTimeFormat12Hour;
const civilTimeFormat24Hour = SuwayaTimeFormatter.civilTimeFormat24Hour;

String formatDigitsForStyle(
  String input, {
  String numberStyle = 'english',
  String locale = 'en',
}) {
  if (numberStyle == 'localized') {
    return SuwayaTimeFormatter.toLocalizedDigits(input, locale);
  }
  return SuwayaTimeFormatter.toEnglishDigits(input);
}

String formatCivilClock(
  CivilWallClock clock, {
  required String format,
  required String locale,
  required BuildContext context,
  String numberStyle = 'english',
}) {
  final isRTL = Directionality.of(context) == ui.TextDirection.rtl;
  final bool use24Hour =
      format == civilTimeFormat24Hour ||
      (format == civilTimeFormatSystem &&
          (MediaQuery.maybeAlwaysUse24HourFormatOf(context) ?? false));

  return SuwayaTimeFormatter.formatCivilWallClock(
    clock,
    use24Hour: use24Hour,
    locale: locale,
    isRTL: isRTL,
    useEnglishDigits: numberStyle != 'localized',
  );
}

String formatCivilTime(
  DateTime time, {
  required String format,
  required String locale,
  required BuildContext context,
  String numberStyle = 'english',
}) {
  return formatCivilClock(
    CivilWallClock.fromDateTime(time),
    format: format,
    locale: locale,
    context: context,
    numberStyle: numberStyle,
  );
}

String getSuwayaIcon(bool isNight, bool isRTL, String iconMode) {
  return SuwayaCoordinateMapper.formatParts(
    isNight ? 0 : 12,
    0,
    isRTL: isRTL,
    iconMode: iconMode,
  ).icon;
}

({String suwayaStr, String minStr, String icon}) getSuwayaTimeParts(
  int globalSuwayaIndex,
  int minute,
  bool isRTL,
  String iconMode, {
  String numberStyle = 'english',
  String locale = 'en',
}) {
  final raw = SuwayaCoordinateMapper.formatParts(
    globalSuwayaIndex,
    minute,
    isRTL: isRTL,
    iconMode: iconMode,
  );
  return (
    suwayaStr: formatDigitsForStyle(
      raw.suwayaStr,
      numberStyle: numberStyle,
      locale: locale,
    ),
    minStr: formatDigitsForStyle(
      raw.minStr,
      numberStyle: numberStyle,
      locale: locale,
    ),
    icon: raw.icon,
  );
}

String formatSuwayaClockTime(
  SuwayaClockTime time, {
  String separator = '|',
  required bool isRTL,
  String iconMode = 'emoji',
  String numberStyle = 'english',
  String locale = 'en',
}) {
  final globalIndex = time.phase.isNight
      ? (time.phaseSlotNumber - 1)
      : (12 + time.phaseSlotNumber - 1);
  return formatSuwayaTime(
    globalIndex,
    time.virtualMinute,
    separator: separator,
    isRTL: isRTL,
    iconMode: iconMode,
    numberStyle: numberStyle,
    locale: locale,
  );
}

String formatSuwayaTime(
  int globalSuwayaIndex,
  int minute, {
  String separator = '|',
  bool isRTL = true,
  String iconMode = 'emoji',
  String numberStyle = 'english',
  String locale = 'en',
}) {
  final raw = SuwayaCoordinateMapper.formatString(
    globalSuwayaIndex,
    minute,
    separator: separator,
    isRTL: isRTL,
    iconMode: iconMode,
  );
  return formatDigitsForStyle(raw, numberStyle: numberStyle, locale: locale);
}

({int globalIndex, int minute}) getFixedAstroTime(
  String id,
  AstroState state, {
  bool isEnd = false,
}) {
  return SuwayaCoordinateMapper.fixedBoundaryCoordinate(
    id,
    state.periods,
    isEnd: isEnd,
  );
}

CivilDate getLogicalCivilDateForMode({
  required bool isAstroTime,
  required AstroState astroState,
  DateTime? civilReference,
}) {
  return SuwayaScheduleEngine.resolveLogicalCivilDate(
    isAstroTime: isAstroTime,
    astroState: astroState,
    civilReference: civilReference,
  );
}

DateTime getLogicalDateForMode({
  required bool isAstroTime,
  required AstroState astroState,
  DateTime? civilReference,
}) {
  final civilDate = getLogicalCivilDateForMode(
    isAstroTime: isAstroTime,
    astroState: astroState,
    civilReference: civilReference,
  );
  return DateTime(civilDate.year, civilDate.month, civilDate.day);
}
