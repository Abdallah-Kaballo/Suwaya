import 'package:flutter/material.dart';
import 'package:suwaya_time/suwaya_time.dart';

extension AstroPeriodColor on AstroPeriod {
  Color get uiColor => Color(colorValue);
}

extension SmartContrast on Color {
  Color adapt(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) return this;

    final hsl = HSLColor.fromColor(this);
    final safeLightness = hsl.lightness > 0.34 ? 0.32 : hsl.lightness;
    final safeSaturation = (hsl.saturation * 1.1).clamp(0.45, 0.95);
    return hsl
        .withLightness(safeLightness)
        .withSaturation(safeSaturation)
        .toColor();
  }
}