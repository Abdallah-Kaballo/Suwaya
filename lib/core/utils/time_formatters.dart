import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:suwaya_time/suwaya_time.dart';

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
  
  if (format == civilTimeFormat12Hour) {
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;
    final pattern = isRTL ? 'a h:mm' : 'h:mm a';
    return DateFormat(pattern, safeLocale).format(time);
  } else {
    return DateFormat('HH:mm', safeLocale).format(time);
  }
}

String getSuwayaIcon(bool isNight, bool isRTL, String iconMode) {
  if (iconMode == 'text') {
    return isNight ? (isRTL ? 'ل' : 'N') : (isRTL ? 'ن' : 'D');
  }
  return isNight ? '🌑' : '☀️';
}

({String suwayaStr, String minStr, String icon}) getSuwayaTimeParts(int globalSuwayaIndex, int minute, bool isRTL, String iconMode) {
  globalSuwayaIndex = globalSuwayaIndex.clamp(0, 23);
  final isNight = globalSuwayaIndex < 12;
  final localSlot = isNight ? globalSuwayaIndex + 1 : globalSuwayaIndex - 11;
  
  final slotStr = localSlot.toString().padLeft(2, '0');
  final minStr = minute.toString().padLeft(2, '0');
  final icon = getSuwayaIcon(isNight, isRTL, iconMode);
  
  return (suwayaStr: slotStr, minStr: minStr, icon: icon);
}

String formatSuwayaClockTime(SuwayaClockTime time, {String separator = '|', required bool isRTL, String iconMode = 'emoji'}) {
  final slotStr = time.phaseSlotNumber.toString().padLeft(2, '0');
  final minStr = time.virtualMinute.toString().padLeft(2, '0');
  final icon = getSuwayaIcon(time.phase.isNight, isRTL, iconMode); 
  final timeString = '$slotStr$separator$minStr';
  return isRTL ? '$icon $timeString' : '$timeString $icon';
}

String formatSuwayaTime(int globalSuwayaIndex, int minute, {String separator = '|', bool isRTL = true, String iconMode = 'emoji'}) {
  final parts = getSuwayaTimeParts(globalSuwayaIndex, minute, isRTL, iconMode);
  final timeString = '${parts.suwayaStr}$separator${parts.minStr}';
  return isRTL ? '${parts.icon} $timeString' : '$timeString ${parts.icon}';
}

// 🌟 الخريطة الفلكية الثابتة للنظام الجديد (V2: 24 سويعة + 5 أجزاء لقيام الليل)
({int globalIndex, int minute}) getFixedAstroTime(String id, AstroState state, {bool isEnd = false}) {
  int getCount(PeriodKey k) {
    try {
      return state.periods.firstWhere((p) => p.periodKey == k).suwayasCount;
    } catch (_) {
      return 1;
    }
  }
  
  int startG = 0;
  int length = 0;
  final sid = id.toLowerCase();
  
  if (sid == '1' || sid.contains('maghrib')) {
    startG = 0;
    length = getCount(PeriodKey.nightMaghribIsha);
  } else if (sid == '2' || sid.contains('isha')) {
    startG = getCount(PeriodKey.nightMaghribIsha);
    length = getCount(PeriodKey.nightIshaMidnight);
  } else if (sid == '3' || sid.contains('qiyam') || sid.contains('half_2')) {
    // 🌟 النصف الثاني من الليل (الفترة 3): يبدأ من الفهرس العالمي 5 (السويعة 06 🌑) بطول 6 سويعات
    startG = 5;
    length = 6;
  } else if (sid == '4' || sid.contains('fajr')) {
    startG = 11;
    length = 1;
  } else if (sid == '5' || sid.contains('duha') || sid.contains('sunrise')) {
    startG = 12;
    length = getCount(PeriodKey.daySunriseDhuhr);
  } else if (sid == '6' || sid.contains('dhuhr')) {
    startG = 12 + getCount(PeriodKey.daySunriseDhuhr);
    length = getCount(PeriodKey.dayDhuhrAsr);
  } else if (sid == '7' || sid.contains('asr')) {
    startG = 12 + getCount(PeriodKey.daySunriseDhuhr) + getCount(PeriodKey.dayDhuhrAsr);
    length = getCount(PeriodKey.dayAsrMaghrib);
  } else if (sid.contains('third_3')) {
    // 🌟 الثلث الأخير من الليل: 4 سويعات (من 08|00 🌑 إلى 11|59 🌑)
    startG = 7;
    length = 4;
  } else if (sid.contains('sixth_4')) {
    // 🌟 السدس الرابع: سويعتان (من 06|00 🌑 إلى 07|59 🌑)
    startG = 5;
    length = 2;
  } else if (sid.contains('sixth_5')) {
    // 🌟 السدس الخامس: سويعتان (من 08|00 🌑 إلى 09|59 🌑)
    startG = 7;
    length = 2;
  } else if (sid.contains('sixth_6')) {
    // 🌟 السدس السادس: سويعتان (من 10|00 🌑 إلى 11|59 🌑)
    startG = 9;
    length = 2;
  } else {
    startG = 0;
    length = 1;
  }
  
  if (isEnd) {
    final int endTotalMinutes = (startG * 60) + (length * 60) - 1;
    return (globalIndex: (endTotalMinutes ~/ 60) % 24, minute: endTotalMinutes % 60);
  }
  return (globalIndex: startG % 24, minute: 0);
}