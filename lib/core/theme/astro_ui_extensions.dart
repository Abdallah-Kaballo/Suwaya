import 'package:flutter/material.dart';
import '../astro_engine/astro_models.dart';

// 🌟 هذا الملف يربط بين المحرك الفلكي النظيف وواجهة Flutter

extension AstroPeriodColor on AstroPeriod {
  // تحويل colorValue (int) القادم من المحرك إلى Color لاستخدامه في الشاشات
  Color get uiColor => Color(colorValue);
}

extension SmartContrast on Color {
  // دالتك الذكية للتباين
  Color adapt(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) return this; 

    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.25).clamp(0.0, 1.0)).toColor();
  }
}