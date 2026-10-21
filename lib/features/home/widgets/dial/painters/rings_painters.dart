import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:suwaya/core/theme/astro_ui_extensions.dart';
import 'package:suwaya/core/theme/dial_design_provider.dart';
import 'package:suwaya/features/routines/routines_provider.dart';
import 'package:suwaya_time/suwaya_time.dart';

import '../dial_constants.dart';
import '../dial_pin_layout.dart';

class RoutinesRingPainter extends CustomPainter {
  final List<RoutineArcData> routineArcs;
  final bool isDark;
  final DialDesign design;
  final int? highlightedRoutineId;

  RoutinesRingPainter({
    required this.routineArcs,
    required this.isDark,
    required this.design,
    this.highlightedRoutineId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    final innerRadius = R * kPeriodR;
    final outerRadius = R * kRailwayR;
    final width = outerRadius - innerRadius;

    // 🌟 رسم أرضية مسار السكة أولاً تحت الروتين حتى لا تُطمس ألوان وأنماط الروتين
    canvas.drawCircle(
      center,
      innerRadius + (width / 2),
      Paint()
        ..color = isDark
            ? const Color(0xFF090B10).withValues(alpha: 0.82)
            : const Color(0xFFE2E8F0).withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );

    if (routineArcs.isEmpty) return;

    for (var arc in routineArcs) {
      final isHighlighted = arc.id == highlightedRoutineId;

      final rectOuter = Rect.fromCircle(center: center, radius: outerRadius);
      final rectInner = Rect.fromCircle(center: center, radius: innerRadius);

      final path = Path()
        ..arcTo(rectOuter, arc.startAngle, arc.sweepAngle, true)
        ..arcTo(
          rectInner,
          arc.startAngle + arc.sweepAngle,
          -arc.sweepAngle,
          false,
        )
        ..close();

      if (isHighlighted) {
        canvas.drawPath(
          path,
          Paint()
            ..color = arc.color.withValues(alpha: 0.6)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0),
        );
      }

      final fillPaint = Paint()
        ..color = arc.color.withValues(
          alpha: isHighlighted ? 0.42 : (isDark ? 0.24 : 0.28),
        )
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      if (design != DialDesign.minimal) {
        canvas.save();
        canvas.clipPath(path);
        final patternPaint = Paint()
          ..color = arc.color.withValues(
            alpha: isHighlighted ? 0.85 : (isDark ? 0.50 : 0.60),
          )
          ..strokeWidth = isHighlighted ? 1.6 : 1.1
          ..style = PaintingStyle.stroke;

        final bounds = path.getBounds();
        _drawPattern(canvas, bounds, patternPaint, arc.pattern);
        canvas.restore();
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = arc.color.withValues(alpha: isHighlighted ? 1.0 : 0.85)
          ..strokeWidth = isHighlighted ? 2.5 : 1.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawPattern(Canvas canvas, Rect bounds, Paint paint, String pattern) {
    const double step = 6.0;

    if (pattern == 'linear') {
      for (double i = -bounds.height;
          i < bounds.width + bounds.height;
          i += step) {
        canvas.drawLine(
          Offset(bounds.left + i, bounds.top),
          Offset(bounds.left + i - bounds.height, bounds.bottom),
          paint,
        );
      }
    } else if (pattern == 'hexagon') {
      for (double i = -bounds.height;
          i < bounds.width + bounds.height;
          i += step * 1.5) {
        canvas.drawLine(
          Offset(bounds.left + i, bounds.top),
          Offset(bounds.left + i - bounds.height, bounds.bottom),
          paint,
        );
        canvas.drawLine(
          Offset(bounds.left + i, bounds.bottom),
          Offset(bounds.left + i - bounds.height, bounds.top),
          paint,
        );
      }
    } else if (pattern == 'stone') {
      paint.style = PaintingStyle.fill;
      int row = 0;
      for (double y = bounds.top; y < bounds.bottom; y += step * 1.2) {
        double offsetX = (row % 2 == 0) ? 0 : (step * 0.6);
        for (double x = bounds.left; x < bounds.right; x += step * 1.2) {
          canvas.drawCircle(
            Offset(x + offsetX, y),
            paint.strokeWidth * 1.2,
            paint,
          );
        }
        row++;
      }
    } else {
      for (double x = bounds.left; x < bounds.right; x += step * 1.2) {
        canvas.drawLine(
          Offset(x, bounds.top),
          Offset(x, bounds.bottom),
          paint,
        );
      }
      for (double y = bounds.top; y < bounds.bottom; y += step * 1.2) {
        canvas.drawLine(
          Offset(bounds.left, y),
          Offset(bounds.right, y),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant RoutinesRingPainter old) {
    if (old.isDark != isDark ||
        old.routineArcs.length != routineArcs.length ||
        old.design != design ||
        old.highlightedRoutineId != highlightedRoutineId) {
      return true;
    }
    for (int i = 0; i < routineArcs.length; i++) {
      final a = old.routineArcs[i];
      final b = routineArcs[i];
      if (a.id != b.id ||
          a.color != b.color ||
          a.startAngle != b.startAngle ||
          a.sweepAngle != b.sweepAngle ||
          a.pattern != b.pattern) {
        return true;
      }
    }
    return false;
  }
}

class PeriodRingPainter extends CustomPainter {
  final List<AstroPeriod> periods;
  final AstroPeriod currentPeriod;
  final DateTime dayStart;
  final DateTime dayEnd;
  final bool isDark;
  final String langCode;
  final DialDesign design;
  final int? highlightedPeriodId;

  PeriodRingPainter({
    required this.periods,
    required this.currentPeriod,
    required this.dayStart,
    required this.dayEnd,
    required this.isDark,
    required this.langCode,
    required this.design,
    this.highlightedPeriodId,
  });

  void _drawArcSegment(
    Canvas canvas,
    Offset center,
    double innerRadius,
    double outerRadius,
    double startAngle,
    double sweepAngle,
    Color color,
    String text,
    bool isHighlighted,
  ) {
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: [
        color.withValues(alpha: isHighlighted ? 0.95 : (isDark ? 0.62 : 0.78)),
        color.withValues(alpha: isHighlighted ? 0.80 : (isDark ? 0.42 : 0.58)),
      ],
    );

    final path = Path()
      ..arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sweepAngle,
        true,
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle + sweepAngle,
        -sweepAngle,
        false,
      )
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: outerRadius),
        ),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: isDark ? 0.45 : 0.70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    if (design == DialDesign.minimal || text.isEmpty) return;

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    final middleAngle = (startAngle + (sweepAngle / 2)) % (2 * pi);
    final drawRadius = innerRadius + (outerRadius - innerRadius) / 2;

    canvas.save();
    canvas.translate(
      center.dx + drawRadius * cos(middleAngle),
      center.dy + drawRadius * sin(middleAngle),
    );

    // 🌟 تعديل اتجاه النص في النصف السفلي من القرص فلا يظهر مقلوباً رأساً على عقب
    double textRotation = middleAngle + pi / 2;
    if (sin(middleAngle) > 0) {
      textRotation += pi;
    }
    canvas.rotate(textRotation);

    textPainter.text = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        fontFamily: 'Tajawal',
        shadows: [
          Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
          Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 0)),
        ],
      ),
    );
    textPainter.layout();

    final double maxW = (sweepAngle * drawRadius) * 0.85;
    final double maxH = (outerRadius - innerRadius) * 0.80;
    double scale = 1.0;
    if (textPainter.width > maxW && maxW > 0) scale = maxW / textPainter.width;
    if (textPainter.height > maxH && maxH > 0) {
      scale = min(scale, maxH / textPainter.height);
    }

    canvas.scale(scale, scale);
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    final innerRadius = R * kInnerR;
    final outerRadius = R * kPeriodR;

    for (var period in periods) {
      final startAngle = timeToAngle(period.startTime, dayStart, dayEnd);
      final endAngle = timeToAngle(period.endTime, dayStart, dayEnd);
      double sweepAngle = endAngle - startAngle;
      if (sweepAngle <= 0) sweepAngle += 2 * pi;

      final isHighlighted =
          period.id == highlightedPeriodId || period.id == currentPeriod.id;

      final Color pColor = period.dialColor(isDark);

      if (isHighlighted) {
        final glowPaint = Paint()
          ..color = pColor.withValues(alpha: isHighlighted ? 0.65 : 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (outerRadius - innerRadius) + (isHighlighted ? 12 : 6)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            isHighlighted ? 16 : 10,
          );
        final glowRadius = innerRadius + (outerRadius - innerRadius) / 2;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: glowRadius),
          startAngle,
          sweepAngle,
          false,
          glowPaint,
        );
      }

      // 🌟 الفترة 3 (النصف الثاني من الليل - 6 سويعات):
      // تقسيم نظيف بكامل عرض الحلقة بدون خط قسمة أفقي: (السدس الرابع = سويعتان) + (الثلث الأخير = 4 سويعات)
      if (period.id == 3 && period.suwayasCount == 6) {
        final suwayaAngle = sweepAngle / 6;

        // 1. أول سويعتين (بكامل عرض الحلقة): السدس الرابع
        final s4Color =
            isDark ? const Color(0xFF3949AB) : const Color(0xFF303F9F);
        _drawArcSegment(
          canvas,
          center,
          innerRadius,
          outerRadius,
          startAngle,
          suwayaAngle * 2,
          s4Color,
          'night_parts.sixth_4'.tr(),
          isHighlighted,
        );

        // 2. آخر 4 سويعات (بكامل عرض الحلقة): الثلث الأخير
        final lastThirdColor =
            isDark ? const Color(0xFF7E57C2) : const Color(0xFF512DA8);
        _drawArcSegment(
          canvas,
          center,
          innerRadius,
          outerRadius,
          startAngle + suwayaAngle * 2,
          suwayaAngle * 4,
          lastThirdColor,
          'night_parts.third_3'.tr(),
          isHighlighted,
        );

        continue;
      }

      String pName = '';
      switch (period.id) {
        case 1:
          pName = 'periods.maghrib'.tr();
          break;
        case 2:
          pName = 'periods.isha'.tr();
          break;
        case 3:
          pName = 'periods.qiyam'.tr();
          break;
        case 4:
          pName = 'periods.fajr'.tr();
          break;
        case 5:
          pName = 'periods.duha'.tr();
          break;
        case 6:
          pName = 'periods.dhuhr'.tr();
          break;
        case 7:
          pName = 'periods.asr'.tr();
          break;
        default:
          pName = period.nameKey.tr();
      }

      _drawArcSegment(
        canvas,
        center,
        innerRadius,
        outerRadius,
        startAngle,
        sweepAngle,
        pColor,
        pName,
        isHighlighted,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PeriodRingPainter old) {
    if (old.currentPeriod.id != currentPeriod.id ||
        old.isDark != isDark ||
        old.dayStart != dayStart ||
        old.dayEnd != dayEnd ||
        old.langCode != langCode ||
        old.design != design ||
        old.highlightedPeriodId != highlightedPeriodId ||
        old.periods.length != periods.length) {
      return true;
    }
    for (int i = 0; i < periods.length; i++) {
      final a = old.periods[i];
      final b = periods[i];
      if (a.id != b.id ||
          a.startTime != b.startTime ||
          a.endTime != b.endTime ||
          a.suwayasCount != b.suwayasCount ||
          a.uiColor != b.uiColor ||
          a.nameKey != b.nameKey) {
        return true;
      }
    }
    return false;
  }
}

class OuterRingPainter extends CustomPainter {
  final List<AstroPeriod> periods;
  final DateTime dayStart;
  final DateTime dayEnd;
  final bool isDark;
  final DialDesign design;
  final String pinMode;

  OuterRingPainter({
    required this.periods,
    required this.dayStart,
    required this.dayEnd,
    required this.isDark,
    required this.design,
    this.pinMode = 'suwaya48',
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;

    final pinStart = R * kRailwayR;
    final pinEnd = pinStart + (R * 0.04);
    final textR = pinEnd + (R * 0.08);

    final Color pinAndTextColor =
        isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827);
    final List<Shadow> textShadows = isDark
        ? const [Shadow(color: Colors.black, blurRadius: 4)]
        : const [Shadow(color: Colors.white, blurRadius: 3)];

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    if (pinMode == 'civil24') {
      final pins = buildCivilDialPins(dayStart, dayEnd);
      for (var index = 0; index < pins.length; index++) {
        final pin = pins[index];
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(pin.angle + pi / 2);
        if (design != DialDesign.minimal) {
          canvas.drawLine(
            Offset(0, -pinStart),
            Offset(0, -pinEnd),
            Paint()
              ..color = pinAndTextColor
              ..strokeWidth = 2.0
              ..strokeCap = StrokeCap.round,
          );
        }
        canvas.drawCircle(
          Offset(0, -pinEnd),
          design == DialDesign.minimal ? 1.0 : 1.5,
          Paint()..color = pinAndTextColor,
        );
        if (design != DialDesign.minimal || index % 5 == 0) {
          textPainter.text = TextSpan(
            text: pin.hour.toString().padLeft(2, '0'),
            style: TextStyle(
              color: pinAndTextColor,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
              shadows: textShadows,
            ),
          );
          textPainter.layout();
          canvas.translate(0, -textR);
          textPainter.paint(
            canvas,
            Offset(-textPainter.width / 2, -textPainter.height / 2),
          );
        }
        canvas.restore();
      }
      return;
    }

    int globalLineIndex = 0;

    for (var period in periods) {
      final startAngle = timeToAngle(period.startTime, dayStart, dayEnd);
      final endAngle = timeToAngle(period.endTime, dayStart, dayEnd);
      double sweepAngle = endAngle - startAngle;
      if (sweepAngle <= 0) sweepAngle += 2 * pi;
      final suwayaAngle = sweepAngle / period.suwayasCount;

      for (int i = 0; i < period.suwayasCount; i++) {
        final lineAngle = startAngle + (i * suwayaAngle);

        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(lineAngle + pi / 2);

        if (design != DialDesign.minimal) {
          canvas.drawLine(
            Offset(0, -pinStart),
            Offset(0, -pinEnd),
            Paint()
              ..color = pinAndTextColor
              ..strokeWidth = 2.0
              ..strokeCap = StrokeCap.round,
          );
        }
        canvas.drawCircle(
          Offset(0, -pinEnd),
          design == DialDesign.minimal ? 1.0 : 1.5,
          Paint()..color = pinAndTextColor,
        );

        int displayNum = (globalLineIndex % 12) + 1;
        String icon = globalLineIndex < 12 ? '🌑' : '☀️';

        textPainter.text = TextSpan(
          text: '$displayNum $icon',
          style: TextStyle(
            color: pinAndTextColor,
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            fontFamily: 'Inter',
            shadows: textShadows,
          ),
        );
        textPainter.layout();

        canvas.translate(0, -textR);
        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );

        canvas.restore();
        globalLineIndex++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant OuterRingPainter old) =>
      old.isDark != isDark ||
      old.dayStart != dayStart ||
      old.dayEnd != dayEnd ||
      old.design != design ||
      old.pinMode != pinMode ||
      old.periods.length != periods.length ||
      _periodsChanged(old.periods, periods);

  bool _periodsChanged(
    List<AstroPeriod> oldPeriods,
    List<AstroPeriod> newPeriods,
  ) {
    for (var index = 0; index < newPeriods.length; index++) {
      if (oldPeriods[index].startTime != newPeriods[index].startTime ||
          oldPeriods[index].endTime != newPeriods[index].endTime ||
          oldPeriods[index].suwayasCount != newPeriods[index].suwayasCount) {
        return true;
      }
    }
    return false;
  }
}

/// 🌟 رسم التاج الإسطرلابي الذهبي الفخم فوق نقطة المغرب (بنفس حجم وموقع السهم السابق)
void drawAstrolabeMaghribCrown(Canvas canvas, Offset center, double outerRadius) {
  final double crownBaseY = center.dy - outerRadius - 2;
  final double crownHeight = outerRadius * 0.13; // حجم متناسق مع السهم السابق
  final double crownHalfWidth = crownHeight * 0.92;
  final Offset apex = Offset(center.dx, crownBaseY - crownHeight);

  // 1. تدرج ذهبي ملكي ثلاثي الأبعاد يطابق الصورة المرفقة
  final Rect crownBounds = Rect.fromLTRB(
    center.dx - crownHalfWidth,
    apex.dy,
    center.dx + crownHalfWidth,
    crownBaseY + 4,
  );

  final Paint goldFillPaint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFF3B0), // لمعة القمة الذهبية
        Color(0xFFE5C158), // ذهب ساطع
        Color(0xFFB8860B), // ذهب عتيق عميق
        Color(0xFF7A5600), // ظل القاعدة
      ],
      stops: [0.0, 0.35, 0.78, 1.0],
    ).createShader(crownBounds)
    ..style = PaintingStyle.fill;

  final Paint goldRimPaint = Paint()
    ..color = const Color(0xFFFFE58F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..strokeJoin = StrokeJoin.round;

  // 2. المسار الخارجي للتاج الإسطرلابي ذي الفصوص المزخرفة (Cusped Astrolabe Crown)
  final Path outerCrown = Path()
    ..moveTo(apex.dx, apex.dy) // القمة المدببة
    // القوس العلوي الأيمن والفص الأول
    ..quadraticBezierTo(
      center.dx + crownHalfWidth * 0.22,
      apex.dy + crownHeight * 0.28,
      center.dx + crownHalfWidth * 0.45,
      apex.dy + crownHeight * 0.34,
    )
    ..cubicTo(
      center.dx + crownHalfWidth * 0.65,
      apex.dy + crownHeight * 0.38,
      center.dx + crownHalfWidth * 0.58,
      apex.dy + crownHeight * 0.58,
      center.dx + crownHalfWidth * 0.48,
      apex.dy + crownHeight * 0.64,
    )
    // الفص السفلي الأيمن
    ..quadraticBezierTo(
      center.dx + crownHalfWidth * 0.88,
      apex.dy + crownHeight * 0.68,
      center.dx + crownHalfWidth,
      crownBaseY,
    )
    // تقوس القاعدة الملاصق لحافة القرص
    ..quadraticBezierTo(
      center.dx,
      crownBaseY - crownHeight * 0.12,
      center.dx - crownHalfWidth,
      crownBaseY,
    )
    // الفص السفلي الأيسر
    ..quadraticBezierTo(
      center.dx - crownHalfWidth * 0.88,
      apex.dy + crownHeight * 0.68,
      center.dx - crownHalfWidth * 0.48,
      apex.dy + crownHeight * 0.64,
    )
    // الفص العلوي الأيسر والعودة للقمة
    ..cubicTo(
      center.dx - crownHalfWidth * 0.58,
      apex.dy + crownHeight * 0.58,
      center.dx - crownHalfWidth * 0.65,
      apex.dy + crownHeight * 0.38,
      center.dx - crownHalfWidth * 0.45,
      apex.dy + crownHeight * 0.34,
    )
    ..quadraticBezierTo(
      center.dx - crownHalfWidth * 0.22,
      apex.dy + crownHeight * 0.28,
      apex.dx,
      apex.dy,
    )
    ..close();

  // ظل خلفي ناعم لإبراز التاج فوق الحافة
  canvas.drawShadow(outerCrown, Colors.black.withValues(alpha: 0.65), 4.0, false);
  canvas.drawPath(outerCrown, goldFillPaint);
  canvas.drawPath(outerCrown, goldRimPaint);

  // 3. الزخرفة النباتية الإسطرلابية الداخلية (الدمعة العربية الوسطى)
  final Path innerMedallion = Path()
    ..moveTo(center.dx, apex.dy + crownHeight * 0.22)
    ..quadraticBezierTo(
      center.dx + crownHalfWidth * 0.34,
      apex.dy + crownHeight * 0.55,
      center.dx,
      crownBaseY - crownHeight * 0.16,
    )
    ..quadraticBezierTo(
      center.dx - crownHalfWidth * 0.34,
      apex.dy + crownHeight * 0.55,
      center.dx,
      apex.dy + crownHeight * 0.22,
    )
    ..close();

  final Paint filigreePaint = Paint()
    ..color = const Color(0xFF4A3200).withValues(alpha: 0.65)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  canvas.drawPath(innerMedallion, filigreePaint);
  canvas.drawCircle(
    Offset(center.dx, apex.dy + crownHeight * 0.54),
    crownHeight * 0.08,
    Paint()..color = const Color(0xFFFFF3B0),
  );
}

class DividerRingPainter extends CustomPainter {
  final List<AstroPeriod> periods;
  final DateTime dayStart;
  final DateTime dayEnd;
  final bool isDark;
  final DialDesign design;

  DividerRingPainter({
    required this.periods,
    required this.dayStart,
    required this.dayEnd,
    required this.isDark,
    required this.design,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    final innerR = R * kInnerR;
    final outerR = R * kRailwayR;

    for (var period in periods) {
      final angle = timeToAngle(period.startTime, dayStart, dayEnd);
      final p1 = Offset(
        center.dx + innerR * cos(angle),
        center.dy + innerR * sin(angle),
      );
      final p2 = Offset(
        center.dx + outerR * cos(angle),
        center.dy + outerR * sin(angle),
      );

      if (design == DialDesign.minimal) {
        canvas.drawLine(
          p1,
          p2,
          Paint()
            ..color = isDark ? Colors.white24 : Colors.black26
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round,
        );
        continue;
      }

      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = isDark ? Colors.black : Colors.white
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = goldBase
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(p2, 4.0, Paint()..color = goldBase);
      canvas.drawCircle(
        p2,
        2.0,
        Paint()..color = isDark ? Colors.black : Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DividerRingPainter old) =>
      old.isDark != isDark ||
      old.dayStart != dayStart ||
      old.design != design ||
      old.periods.length != periods.length;
}