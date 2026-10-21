import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/task_model.dart';

// 🌟 الألوان الأساسية للقرص
const Color goldBase = Color(0xFFD4AF37);
const Color goldLight = Color(0xFFFFE58F);
const Color goldDark = Color(0xFFAA7900);
const Color carvedText = Color(0xFFFFD87A);
const Color astroGold = Color(0xFFF2C94C); 

// 🌟 الأبعاد النسبية (Radii)
const double kInnerR = 0.35;   
const double kPeriodR = 0.50;  
const double kRailwayR = 0.82; 
const double kOuterR = 0.98;   

// 🌟 مزود حالة توهج المهام (تم عزله ليكون متاحاً لجميع أجزاء القرص)
final highlightedTaskProvider = StateProvider<int?>((ref) => null);

Color getNeonColorForCategory(TaskCategory category, {bool isDark = true}) {
  return category.uiColor(isDark);
}

// 🌟 دالة مساعدة لتحويل الوقت إلى زاوية على القرص (تم إزالة _ لتصبح عامة)
double timeToAngle(DateTime time, DateTime start, DateTime end) {
  final total = end.difference(start).inMicroseconds;
  if (total <= 0) return -pi / 2;
  return -pi / 2 + (time.difference(start).inMicroseconds / total) * 2 * pi;
}