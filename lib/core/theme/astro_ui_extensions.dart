import 'package:flutter/material.dart';
import 'package:suwaya_time/suwaya_time.dart';

extension AstroPeriodColor on AstroPeriod {
  Color get uiColor => Color(colorValue);

  /// 🌟 ألوان قطاعات القرص الفلكي مضبوطة هندسياً لتحقيق تباين WCAG AA مع النص الأبيض المحفور فوقها
  Color dialColor(bool isDark) {
    switch (id) {
      case 1: // المغرب (ياقوتي دافئ)
        return isDark ? const Color(0xFFD32F2F) : const Color(0xFFB71C1C);
      case 2: // العشاء (نيلي ملكي)
        return isDark ? const Color(0xFF3949AB) : const Color(0xFF283593);
      case 3: // النصف الثاني من الليل / القيام (بنفسجي فلكي)
        return isDark ? const Color(0xFF5E35B1) : const Color(0xFF4527A0);
      case 4: // الفجر (أزرق سماوي عميق)
        return isDark ? const Color(0xFF1565C0) : const Color(0xFF0D47A1);
      case 5: // الضحى (ذهبي كهرماني متوازن يضمن قراءة النص الأبيض فوقه)
        return isDark ? const Color(0xFF9E6B00) : const Color(0xFF8A5A00);
      case 6: // الظهر (برتقالي ذهبي غني)
        return isDark ? const Color(0xFFB85D00) : const Color(0xFF9E4700);
      case 7: // العصر (برتقالي غروبي نحاسي)
        return isDark ? const Color(0xFFC84B11) : const Color(0xFFB23A00);
      default:
        return uiColor;
    }
  }
}

extension SmartContrast on Color {
  Color adapt(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return adaptForBrightness(isDark);
  }

  Color adaptForBrightness(bool isDark) {
    final hsl = HSLColor.fromColor(this);

    if (isDark) {
      final safeLightness = hsl.lightness < 0.66
          ? 0.68
          : hsl.lightness.clamp(0.66, 0.82);
      final safeSaturation = hsl.saturation.clamp(0.55, 0.90);
      return hsl
          .withLightness(safeLightness)
          .withSaturation(safeSaturation)
          .toColor();
    }

    final safeLightness = hsl.lightness > 0.32
        ? 0.28
        : hsl.lightness.clamp(0.20, 0.32);
    final safeSaturation = (hsl.saturation * 1.1).clamp(0.60, 0.95);
    return hsl
        .withLightness(safeLightness)
        .withSaturation(safeSaturation)
        .toColor();
  }
}

/// 🌟 لون التوقيت السويعي الذهبي المتكيف مع الوضع الداكن والفاتح (تباين > 6.5:1 في الوضعين)
Color suwayaTimeContrastColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return suwayaTimeColorForBrightness(isDark);
}

Color suwayaTimeColorForBrightness(bool isDark) {
  return isDark ? const Color(0xFFF2C94C) : const Color(0xFF7C4D00);
}

/// 🌟 ألوان موحدة وعالية التباين لأيقونات ومؤشرات الصلوات الخمس والشروق في البطاقات
Color prayerAccentColor(String prayerId, {required bool isDark}) {
  switch (prayerId.toLowerCase().trim()) {
    case '1':
    case 'fajr':
      return isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0);
    case 'sunrise':
      return isDark ? const Color(0xFFFFB74D) : const Color(0xFFB45309);
    case '3':
    case 'dhuhr':
      return isDark ? const Color(0xFFFFD54F) : const Color(0xFF9A6700);
    case '4':
    case 'asr':
      return isDark ? const Color(0xFFFF9800) : const Color(0xFFC2410C);
    case '5':
    case 'maghrib':
      return isDark ? const Color(0xFFEF5350) : const Color(0xFFC62828);
    case '9':
    case 'isha':
      return isDark ? const Color(0xFF7986CB) : const Color(0xFF283593);
    default:
      return isDark ? const Color(0xFFE5C158) : const Color(0xFF8A5A00);
  }
}

/// 🌟 اللون الأصفر/الذهبي الثابت للشاشة الرئيسية وزر الإضافة (متطابق مع العبادات وباقي الشاشات في الوضعين الداكن والفاتح)
Color homeFixedYellowColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return homeFixedYellowForBrightness(isDark);
}

Color homeFixedYellowForBrightness(bool isDark) {
  return isDark ? const Color(0xFFE5C158) : const Color(0xFF8A5A00);
}
