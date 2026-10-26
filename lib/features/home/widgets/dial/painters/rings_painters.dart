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

    // 🌟 تفتيح درجة الرمادي في إطار المهام والروتينات لبروز المسار بوضوح وأناقة
    canvas.drawCircle(
      center,
      innerRadius + (width / 2),
      Paint()
        ..color = isDark
            ? const Color(0xFF282D3A).withValues(alpha: 0.92)
            : const Color(0xFFEDF2F7).withValues(alpha: 0.90)
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
          alpha: isHighlighted ? 0.45 : (isDark ? 0.28 : 0.30),
        )
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      if (design != DialDesign.minimal) {
        canvas.save();
        canvas.clipPath(path);
        final patternPaint = Paint()
          ..color = arc.color.withValues(
            alpha: isHighlighted ? 0.90 : (isDark ? 0.58 : 0.65),
          )
          ..strokeWidth = isHighlighted ? 1.6 : 1.15
          ..style = PaintingStyle.stroke;

        final bounds = path.getBounds();
        _drawPattern(canvas, bounds, patternPaint, arc.pattern);
        canvas.restore();
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = arc.color.withValues(alpha: isHighlighted ? 1.0 : 0.90)
          ..strokeWidth = isHighlighted ? 2.5 : 1.6
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawPattern(Canvas canvas, Rect bounds, Paint paint, String pattern) {
    const double step = 6.0;

    if (pattern == 'linear') {
      for (
        double i = -bounds.height;
        i < bounds.width + bounds.height;
        i += step
      ) {
        canvas.drawLine(
          Offset(bounds.left + i, bounds.top),
          Offset(bounds.left + i - bounds.height, bounds.bottom),
          paint,
        );
      }
    } else if (pattern == 'hexagon') {
      for (
        double i = -bounds.height;
        i < bounds.width + bounds.height;
        i += step * 1.5
      ) {
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
        canvas.drawLine(Offset(x, bounds.top), Offset(x, bounds.bottom), paint);
      }
      for (double y = bounds.top; y < bounds.bottom; y += step * 1.2) {
        canvas.drawLine(Offset(bounds.left, y), Offset(bounds.right, y), paint);
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
  final double totalRotation;
  final String? fontFamily;

  PeriodRingPainter({
    required this.periods,
    required this.currentPeriod,
    required this.dayStart,
    required this.dayEnd,
    required this.isDark,
    required this.langCode,
    required this.design,
    this.highlightedPeriodId,
    this.totalRotation = 0.0,
    this.fontFamily = 'Inter',
  });

  int _computeFlipMask() {
    int mask = 0;
    int bit = 0;
    for (final period in periods) {
      final startAngle = timeToAngle(period.startTime, dayStart, dayEnd);
      final endAngle = timeToAngle(period.endTime, dayStart, dayEnd);
      double sweepAngle = endAngle - startAngle;
      if (sweepAngle <= 0) sweepAngle += 2 * pi;

      if (period.id == 3 && period.suwayasCount == 6) {
        final suwayaAngle = sweepAngle / 6;
        final mid1 = startAngle + suwayaAngle;
        final mid2 = startAngle + suwayaAngle * 4;
        if (sin(mid1 + totalRotation) > 0) mask |= (1 << bit);
        bit++;
        if (sin(mid2 + totalRotation) > 0) mask |= (1 << bit);
        bit++;
      } else {
        final mid = startAngle + (sweepAngle / 2);
        if (sin(mid + totalRotation) > 0) mask |= (1 << bit);
        bit++;
      }
    }
    return mask;
  }

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

    // 🌟 قلب النص تلقائياً بناءً على زاويته الفعلية على الشاشة أثناء التدوير
    double textRotation = middleAngle + pi / 2;
    if (sin(middleAngle + totalRotation) > 0) {
      textRotation += pi;
    }
    canvas.rotate(textRotation);

    textPainter.text = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        fontFamily: fontFamily,
        shadows: const [
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

      if (period.id == 3 && period.suwayasCount == 6) {
        final suwayaAngle = sweepAngle / 6;

        final s4Color = isDark
            ? const Color(0xFF3949AB)
            : const Color(0xFF303F9F);
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

        final lastThirdColor = isDark
            ? const Color(0xFF7E57C2)
            : const Color(0xFF512DA8);
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
        old.periods.length != periods.length ||
        old._computeFlipMask() != _computeFlipMask()) {
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
  final double totalRotation;
  final ui.Image? sunImage;
  final ui.Image? moonImage;

  OuterRingPainter({
    required this.periods,
    required this.dayStart,
    required this.dayEnd,
    required this.isDark,
    required this.design,
    this.pinMode = 'suwaya24',
    this.totalRotation = 0.0,
    this.sunImage,
    this.moonImage,
  });

  int _computePinsFlipMask() {
    int mask = 0;
    int bit = 0;
    if (pinMode == 'civil24') {
      final pins = buildCivilDialPins(dayStart, dayEnd);
      for (final pin in pins) {
        if (sin(pin.angle + totalRotation) > 0) mask |= (1 << bit);
        bit++;
      }
      return mask;
    }

    for (final period in periods) {
      final startAngle = timeToAngle(period.startTime, dayStart, dayEnd);
      final endAngle = timeToAngle(period.endTime, dayStart, dayEnd);
      double sweepAngle = endAngle - startAngle;
      if (sweepAngle <= 0) sweepAngle += 2 * pi;
      final suwayaAngle = sweepAngle / period.suwayasCount;

      for (int i = 0; i < period.suwayasCount; i++) {
        final lineAngle = startAngle + (i * suwayaAngle);
        if (sin(lineAngle + totalRotation) > 0) mask |= (1 << bit);
        bit++;
      }
    }
    return mask;
  }

  void _drawPhasePinBadge({
    required Canvas canvas,
    required double badgeRadius,
    required bool isNight,
    required int displayNum,
    required bool flipText,
  }) {
    final badgeRect = Rect.fromCircle(center: Offset.zero, radius: badgeRadius);
    final ui.Image? targetImage = isNight ? moonImage : sunImage;

    canvas.save();
    if (flipText) {
      canvas.rotate(pi);
    }

    // 1. رسم صورة القمر أو الشمس مقصوصة دائرياً فوق الدبوس مباشرة
    final clipPath = Path()..addOval(badgeRect);
    canvas.save();
    canvas.clipPath(clipPath);

    if (targetImage != null) {
      final srcRect = Rect.fromLTWH(
        0,
        0,
        targetImage.width.toDouble(),
        targetImage.height.toDouble(),
      );
      canvas.drawImageRect(
        targetImage,
        srcRect,
        badgeRect,
        Paint()..filterQuality = FilterQuality.medium,
      );
      // طبقة إضاءة ناعمة جداً تضمن بروز الرقم الأسود فوق تفاصيل الشمس والقمر
      canvas.drawRect(
        badgeRect,
        Paint()..color = Colors.white.withValues(alpha: isNight ? 0.22 : 0.14),
      );
    } else {
      canvas.drawCircle(
        Offset.zero,
        badgeRadius,
        Paint()
          ..color = isNight ? const Color(0xFFCBD5E1) : const Color(0xFFFDE047),
      );
    }
    canvas.restore();

    // 2. حلقة حافة دقيقة تحدد قرص الشمس/القمر
    canvas.drawCircle(
      Offset.zero,
      badgeRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = isNight
            ? const Color(0xFF93C5FD).withValues(alpha: 0.85)
            : const Color(0xFFFACC15).withValues(alpha: 0.95),
    );

    // 3. رسم الرقم باللون الأسود الصريح وبخط Inter في قلب قرص الشمس/القمر
    final numStr = displayNum.toString();
    final fontSize = displayNum >= 10 ? badgeRadius * 0.96 : badgeRadius * 1.08;

    const Color fillColor = Color(0xFF000000);
    final Color strokeColor = Colors.white.withValues(alpha: 0.90);

    final strokePainter = TextPainter(
      text: TextSpan(
        text: numStr,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          fontFamily: 'Inter',
          height: 1.0,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..strokeJoin = StrokeJoin.round
            ..color = strokeColor,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    final fillPainter = TextPainter(
      text: TextSpan(
        text: numStr,
        style: TextStyle(
          color: fillColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          fontFamily: 'Inter',
          height: 1.0,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    final offset = Offset(-fillPainter.width / 2, -fillPainter.height / 2);
    strokePainter.paint(canvas, offset);
    fillPainter.paint(canvas, offset);

    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;

    final pinStart = R * kRailwayR;
    final pinEnd = pinStart + (R * 0.022);
    final badgeRadius = (R * 0.058).clamp(10.5, 15.0);
    final badgeCenterR = pinEnd + badgeRadius + (R * 0.006);

    final Color pinAndTextColor = isDark
        ? const Color(0xFFF3F4F6)
        : const Color(0xFF111827);
    final List<Shadow> textShadows = isDark
        ? const [Shadow(color: Colors.black, blurRadius: 4)]
        : const [Shadow(color: Colors.white, blurRadius: 3)];

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    if (pinMode == 'civil24') {
      final textR = pinEnd + (R * 0.065);
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
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
              shadows: textShadows,
            ),
          );
          textPainter.layout();
          canvas.translate(0, -textR);
          if (sin(pin.angle + totalRotation) > 0) {
            canvas.rotate(pi);
          }
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

        final int displayNum = (globalLineIndex % 12) + 1;
        final bool isNight = globalLineIndex < 12;
        final bool flipText = sin(lineAngle + totalRotation) > 0;

        canvas.translate(0, -badgeCenterR);
        _drawPhasePinBadge(
          canvas: canvas,
          badgeRadius: badgeRadius,
          isNight: isNight,
          displayNum: displayNum,
          flipText: flipText,
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
      old.sunImage != sunImage ||
      old.moonImage != moonImage ||
      old.periods.length != periods.length ||
      old._computePinsFlipMask() != _computePinsFlipMask() ||
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
