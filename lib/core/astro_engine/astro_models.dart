import 'package:flutter/material.dart';

class AstroPeriod {
  final int id;
  final String name;
  final String nameKey;
  final DateTime startTime;
  final DateTime endTime;
  final int suwayasCount;
  final Color color;

  AstroPeriod({
    required this.id,
    required this.name,
    required this.nameKey,
    required this.startTime,
    required this.endTime,
    required this.suwayasCount,
    required this.color,
  });

  Duration get totalDuration => endTime.difference(startTime);
}

class NightPart {
  final String id;
  final String nameKey;
  final DateTime startTime;
  final DateTime endTime;

  NightPart({
    required this.id, required this.nameKey, required this.startTime, required this.endTime,
  });
}

class IbadatTimings {
  final DateTime fajr, sunrise, dhuhr, asr, maghrib, isha, nextFajr;
  final List<NightPart> nightParts;

  IbadatTimings({
    required this.fajr, required this.sunrise, required this.dhuhr, 
    required this.asr, required this.maghrib, required this.isha, 
    required this.nextFajr, required this.nightParts,
  });
}

extension SmartContrast on Color {
  Color adapt(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) return this; 

    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.25).clamp(0.0, 1.0)).toColor();
  }
}

extension AstroPeriodNaming on AstroPeriod {
  String get longName {
    switch (id) {
      case 1: return 'الفترة الأولى (الفجر)';
      case 2: return 'الفترة الثانية ';
      case 3: return 'الفترة الثالثة (الظهر)';
      case 4: return 'الفترة الرابعة (العصر)';
      case 5: return 'الفترة الخامسة (المغرب)';
      case 6: return 'الفترة السادسة';
      case 7: return 'الفترة السابعة (الثلث الأخير)';
      default: return 'الفترة $id';
    }
  }

  String get shortName => longName.replaceAll(RegExp(r'\s*\(.*?\)'), '');
}