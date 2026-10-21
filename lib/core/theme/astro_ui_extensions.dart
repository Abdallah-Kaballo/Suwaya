import 'package:flutter/material.dart';
import 'package:suwaya_time/suwaya_time.dart';

extension AstroPeriodColor on AstroPeriod {
  Color get uiColor => Color(colorValue);

  /// 🌟 لون الفترة المتكيف بصرياً لتحقيق أعلى تباين على القرص وفي البطاقات (ليلاً ونهاراً)
  Color dialColor(bool isDark) {
    switch (id) {
      case 1: // المغرب
        return isDark ? const Color(0xFFEF5350) : const Color(0xFFC62828);
      case 2: // العشاء (تفتيح الكحلي في الوضع الداكن ليبرز بوضوح)
        return isDark ? const Color(0xFF5C6BC0) : const Color(0xFF283593);
      case 3: // النصف الثاني من الليل / القيام
        return isDark ? const Color(0xFF7E57C2) : const Color(0xFF4527A0);
      case 4: // الفجر
        return isDark ? const Color(0xFF42A5F5) : const Color(0xFF1565C0);
      case 5: // الضحى
        return isDark ? const Color(0xFFFFD54F) : const Color(0xFF9A6700);
      case 6: // الظهر
        return isDark ? const Color(0xFFFFB300) : const Color(0xFFB25000);
      case 7: // العصر
        return isDark ? const Color(0xFFFF8F00) : const Color(0xFFC25E00);
      default:
        return uiColor;
    }
  }
}

extension SmartContrast on Color {
  Color adapt(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hsl = HSLColor.fromColor(this);

    if (isDark) {
      // 🌟 تفتيح الألوان شديدة القتامة (كالعشاء والقيام) في الوضع الداكن لتحقيق تباين ممتاز
      final safeLightness = hsl.lightness < 0.62 ? 0.65 : hsl.lightness;
      final safeSaturation = hsl.saturation.clamp(0.50, 0.90);
      return hsl
          .withLightness(safeLightness)
          .withSaturation(safeSaturation)
          .toColor();
    }

    // 🌟 تغميق الألوان الفاتحة (كالضحى والظهر والذهبي) في الوضع الفاتح لتحقيق تباين WCAG AA
    final safeLightness = hsl.lightness > 0.34 ? 0.30 : hsl.lightness;
    final safeSaturation = (hsl.saturation * 1.1).clamp(0.55, 0.95);
    return hsl
        .withLightness(safeLightness)
        .withSaturation(safeSaturation)
        .toColor();
  }
}

/// 🌟 دالة موحدة للون الوقت السويعي تعطي الأولوية للتباين والوضوح البصري في الوضعين
Color suwayaTimeContrastColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? const Color(0xFFF2C94C) : const Color(0xFF8A5A00);
}