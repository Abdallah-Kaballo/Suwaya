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

// 🌟 دالة مساعدة لتحديد لون المهام حسب التصنيف
Color getNeonColorForCategory(TaskCategory category) {
  final catStr = category.toString().toLowerCase();
  if (catStr.contains('work')) return const Color(0xFF00E5FF);
  if (catStr.contains('study')) return const Color(0xFF00E676);
  if (catStr.contains('sport')) return const Color(0xFFFF3D00);
  if (catStr.contains('worship')) return const Color(0xFFFFC400);
  if (catStr.contains('entertainment')) return const Color(0xFFFF4081);
  if (catStr.contains('personal')) return const Color(0xFFD500F9);
  if (catStr.contains('social')) return const Color(0xFF76FF03);
  return const Color(0xFF18FFFF);
}

// 🌟 دالة مساعدة لتحويل الوقت إلى زاوية على القرص (تم إزالة _ لتصبح عامة)
double timeToAngle(DateTime time, DateTime start, DateTime end) {
  final total = end.difference(start).inMicroseconds;
  if (total <= 0) return -pi / 2;
  return -pi / 2 + (time.difference(start).inMicroseconds / total) * 2 * pi;
}