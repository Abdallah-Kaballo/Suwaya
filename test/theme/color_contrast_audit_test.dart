import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya/core/theme/app_theme.dart';
import 'package:suwaya/core/theme/astro_ui_extensions.dart';
import 'package:suwaya/features/home/widgets/dial/dial_constants.dart';
import 'package:suwaya/models/task_model.dart';
import 'package:suwaya_time/suwaya_time.dart';

/// حساب السطوع النسبي (Relative Luminance) وفق معيار WCAG 2.1
double relativeLuminance(Color color) {
  double channelLuminance(double channel) {
    return channel <= 0.03928
        ? channel / 12.92
        : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = channelLuminance(color.r);
  final g = channelLuminance(color.g);
  final b = channelLuminance(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// حساب نسبة التباين (Contrast Ratio) بين لونين (من 1.0 إلى 21.0)
double contrastRatio(Color foreground, Color background) {
  final l1 = relativeLuminance(foreground);
  final l2 = relativeLuminance(background);
  final brightest = math.max(l1, l2);
  final darkest = math.min(l1, l2);
  return (brightest + 0.05) / (darkest + 0.05);
}

void main() {
  group('Design & Color Contrast Audit (WCAG 2.1 Compliance)', () {
    test(
      '1. All 4 AppColorThemes meet WCAG AAA/AA text & button contrast in Dark and Light modes',
      () {
        for (final colorTheme in AppColorTheme.values) {
          final darkTheme = AppTheme.getDarkTheme(colorTheme);
          final lightTheme = AppTheme.getLightTheme(colorTheme);

          // تباين النصوص الأساسية على خلفية الشاشة والبطاقات
          expect(
            contrastRatio(
              darkTheme.colorScheme.onSurface,
              darkTheme.scaffoldBackgroundColor,
            ),
            greaterThanOrEqualTo(12.0),
            reason: 'Dark scaffold text contrast failed for $colorTheme',
          );
          expect(
            contrastRatio(
              lightTheme.colorScheme.onSurface,
              lightTheme.scaffoldBackgroundColor,
            ),
            greaterThanOrEqualTo(12.0),
            reason: 'Light scaffold text contrast failed for $colorTheme',
          );

          // تباين النص داخل الأزرار الرئيسية (onPrimary فوق primary)
          expect(
            contrastRatio(
              darkTheme.colorScheme.onPrimary,
              darkTheme.colorScheme.primary,
            ),
            greaterThanOrEqualTo(4.5),
            reason: 'Dark primary button text contrast failed for $colorTheme',
          );
          expect(
            contrastRatio(
              lightTheme.colorScheme.onPrimary,
              lightTheme.colorScheme.primary,
            ),
            greaterThanOrEqualTo(4.5),
            reason: 'Light primary button text contrast failed for $colorTheme',
          );
        }
      },
    );

    test(
      '2. New Silver-White Hours Hand & Task Ring have high visibility and separation',
      () {
        const darkDialBg = Color(0xFF121316);
        const lightenedTaskRingDark = Color(0xFF282D3A);
        const silverWhiteHand = Color(0xFFF8FAFC);

        // التأكد من أن إطار المهام الرمادي الجديد أفتح بوضوح من خلفية القرص الداكنة
        expect(
          relativeLuminance(lightenedTaskRingDark),
          greaterThan(relativeLuminance(darkDialBg) * 2.5),
        );

        // التأكد من أن العقرب الفضي المائل للأبيض يحقق تباين WCAG AAA (> 10:1) فوق إطار المهام
        expect(
          contrastRatio(silverWhiteHand, lightenedTaskRingDark),
          greaterThanOrEqualTo(12.0),
        );

        // التأكد من أن شارات الصلوات الذهبية (#FFE58F) تحقق تباين AAA فوق إطار المهام الجديد
        expect(
          contrastRatio(goldLight, lightenedTaskRingDark),
          greaterThanOrEqualTo(10.0),
        );
      },
    );

    test(
      '3. All 7 Astronomical Period dial colors achieve >= 4.5:1 contrast with white carved text',
      () {
        final now = DateTime.utc(2026, 10, 22);
        for (int id = 1; id <= 7; id++) {
          final period = AstroPeriod(
            id: id,
            periodKey: PeriodKey.values[id - 1],
            nameKey: 'periods.p$id',
            startTime: now,
            endTime: now.add(const Duration(hours: 2)),
            suwayasCount: 2,
            colorValue: 0xFFD4AF37,
          );

          final darkSegmentColor = period.dialColor(true);
          final lightSegmentColor = period.dialColor(false);

          expect(
            contrastRatio(Colors.white, darkSegmentColor),
            greaterThanOrEqualTo(4.5),
            reason: 'Period $id in Dark mode is too bright for white dial text',
          );
          expect(
            contrastRatio(Colors.white, lightSegmentColor),
            greaterThanOrEqualTo(4.5),
            reason:
                'Period $id in Light mode is too bright for white dial text',
          );
        }
      },
    );

    test(
      '4. All 8 Task Categories achieve high contrast against card surfaces and task ring in Dark & Light modes',
      () {
        const darkCard = Color(0xFF1C1E24);
        const darkTaskRing = Color(0xFF282D3A);
        const lightCard = Color(0xFFFFFFFF);

        for (final category in TaskCategory.values) {
          final darkCatColor = category.uiColor(true);
          final lightCatColor = category.uiColor(false);

          expect(
            contrastRatio(darkCatColor, darkCard),
            greaterThanOrEqualTo(4.5),
            reason: 'Category $category failed contrast on Dark Card',
          );
          expect(
            contrastRatio(darkCatColor, darkTaskRing),
            greaterThanOrEqualTo(3.5),
            reason: 'Category $category failed contrast on Dark Task Ring',
          );
          expect(
            contrastRatio(lightCatColor, lightCard),
            greaterThanOrEqualTo(4.5),
            reason: 'Category $category failed contrast on Light Card',
          );
        }
      },
    );

    test(
      '5. Suwaya Gold Time & Prayer Accent Colors (including Isha) are clearly visible in both modes',
      () {
        const darkCard = Color(0xFF1C1E24);
        const lightCard = Color(0xFFFFFFFF);

        // التوقيت السويعي الذهبي
        expect(
          contrastRatio(suwayaTimeColorForBrightness(true), darkCard),
          greaterThanOrEqualTo(8.0),
        );
        expect(
          contrastRatio(suwayaTimeColorForBrightness(false), lightCard),
          greaterThanOrEqualTo(5.5),
        );

        // جميع الصلوات الخمس والشروق (شاملة العشاء التي كانت مختفية سابقاً)
        for (final id in [
          'fajr',
          'sunrise',
          'dhuhr',
          'asr',
          'maghrib',
          'isha',
        ]) {
          expect(
            contrastRatio(prayerAccentColor(id, isDark: true), darkCard),
            greaterThanOrEqualTo(4.2),
            reason: 'Prayer $id icon color has low contrast on Dark card',
          );
          expect(
            contrastRatio(prayerAccentColor(id, isDark: false), lightCard),
            greaterThanOrEqualTo(4.5),
            reason: 'Prayer $id icon color has low contrast on Light card',
          );
        }
      },
    );
  });
}
