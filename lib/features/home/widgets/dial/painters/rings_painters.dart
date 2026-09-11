import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:suwaya/core/theme/astro_ui_extensions.dart';
import 'package:suwaya/core/theme/dial_design_provider.dart';
import 'package:suwaya/features/routines/routines_provider.dart';
import 'package:suwaya_time/suwaya_time.dart';

import '../dial_constants.dart';

class RoutinesRingPainter extends CustomPainter {
  final List<RoutineArcData> routineArcs;
  final bool isDark;
  final DialDesign design;
  
  RoutinesRingPainter({required this.routineArcs, required this.isDark, required this.design});

  @override
  void paint(Canvas canvas, Size size) {
    if (routineArcs.isEmpty) return;
    
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    final innerRadius = R * kInnerR; 
    final outerRadius = R * kRailwayR; 
    
    for (var arc in routineArcs) {
      final rectOuter = Rect.fromCircle(center: center, radius: outerRadius);
      final rectInner = Rect.fromCircle(center: center, radius: innerRadius);

      final path = Path()
        ..arcTo(rectOuter, arc.startAngle, arc.sweepAngle, true)
        ..arcTo(rectInner, arc.startAngle + arc.sweepAngle, -arc.sweepAngle, false)
        ..close();

      final fillPaint = Paint()
        ..color = arc.color.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      if (design != DialDesign.minimal) {
        canvas.save();
        canvas.clipPath(path); 
        final hatchPaint = Paint()..color = arc.color.withValues(alpha: 0.4)..strokeWidth = 1.0..style = PaintingStyle.stroke;
        final bounds = path.getBounds();
        _drawLinearGrid(canvas, bounds, hatchPaint); 
        canvas.restore();
      }

      canvas.drawPath(path, Paint()..color = arc.color.withValues(alpha: 0.8)..strokeWidth = 1.5..style = PaintingStyle.stroke..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0));
    }
  }

  void _drawLinearGrid(Canvas canvas, Rect bounds, Paint paint) {
    const double step = 6.0; 
    for (double i = -bounds.height; i < bounds.width + bounds.height; i += step) {
      canvas.drawLine(Offset(bounds.left + i, bounds.top), Offset(bounds.left + i - bounds.height, bounds.bottom), paint);
    }
  }
  @override bool shouldRepaint(covariant RoutinesRingPainter old) => old.isDark != isDark || old.routineArcs.length != routineArcs.length || old.design != design;
}

class PeriodRingPainter extends CustomPainter {
  final List<AstroPeriod> periods;
  final AstroPeriod currentPeriod;
  final DateTime dayStart;
  final DateTime dayEnd;
  final bool isDark;
  final String langCode; 
  final DialDesign design;

  PeriodRingPainter({required this.periods, required this.currentPeriod, required this.dayStart, required this.dayEnd, required this.isDark, required this.langCode, required this.design});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    final innerRadius = R * kInnerR;
    final outerRadius = R * kPeriodR;
    final width = design == DialDesign.minimal ? (outerRadius - innerRadius) * 0.4 : (outerRadius - innerRadius);
    final drawRadius = design == DialDesign.minimal ? innerRadius + (width / 2) + 10 : innerRadius + (width / 2);
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr, textAlign: TextAlign.center);

    for (var period in periods) {
      final startAngle = timeToAngle(period.startTime, dayStart, dayEnd);
      final endAngle = timeToAngle(period.endTime, dayStart, dayEnd);
      double sweepAngle = endAngle - startAngle;
      if (sweepAngle <= 0) sweepAngle += 2 * pi;

      Color pColor = period.uiColor;
      if (period.id == 6 || period.nameKey == 'period_second_third') pColor = const Color(0xFF3F51B5); 
      final isCurrent = period.id == currentPeriod.id;
      
      if (isCurrent && design != DialDesign.minimal) {
        final glowPaint = Paint()..color = pColor.withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = width + 6..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        canvas.drawArc(Rect.fromCircle(center: center, radius: drawRadius), startAngle, sweepAngle, false, glowPaint);
      }
      
      final gradient = SweepGradient(startAngle: startAngle, endAngle: startAngle + sweepAngle, colors: [pColor.withValues(alpha: isCurrent ? 0.9 : 0.4), pColor.withValues(alpha: isCurrent ? 0.6 : 0.2)]);
      final rect = Rect.fromCircle(center: center, radius: drawRadius);
      canvas.drawArc(rect, startAngle, sweepAngle, false, Paint()..style = PaintingStyle.stroke..strokeWidth = width..strokeCap = StrokeCap.butt..shader = gradient.createShader(rect));

      if (design == DialDesign.minimal) continue;

      final middleAngle = (startAngle + (sweepAngle / 2)) % (2 * pi);
      canvas.save();
      canvas.translate(center.dx + drawRadius * cos(middleAngle), center.dy + drawRadius * sin(middleAngle));
      canvas.rotate(middleAngle + pi / 2); 
      
      String pName = '';
      switch(period.id) {
        case 1: pName = 'periods.fajr'.tr(); break;
        case 2: pName = 'periods.duha'.tr(); break;
        case 3: pName = 'periods.dhuhr'.tr(); break;
        case 4: pName = 'periods.asr'.tr(); break;
        case 5: pName = 'periods.maghrib'.tr(); break;
        case 6: pName = 'periods.middle_third'.tr(); break;
        case 7: pName = 'periods.last_third'.tr(); break;
        default: pName = period.nameKey.tr();
      }

      textPainter.text = TextSpan(
        text: pName, 
        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Tajawal', shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)), Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 0))])
      );
      textPainter.layout();
      
      final double maxW = (sweepAngle * drawRadius) * 0.85; 
      final double maxH = width * 0.65;
      double scale = 1.0;
      if (textPainter.width > maxW && maxW > 0) scale = maxW / textPainter.width;
      if (textPainter.height > maxH && maxH > 0) scale = min(scale, maxH / textPainter.height);
      
      canvas.scale(scale, scale);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
  }
  @override bool shouldRepaint(covariant PeriodRingPainter old) => old.currentPeriod.id != currentPeriod.id || old.isDark != isDark || old.dayStart != dayStart || old.langCode != langCode || old.design != design || old.periods.length != periods.length;
}

class OuterRingPainter extends CustomPainter {
  final List<AstroPeriod> periods;
  final DateTime dayStart;
  final DateTime dayEnd;
  final bool isDark;
  final DialDesign design;

  OuterRingPainter({required this.periods, required this.dayStart, required this.dayEnd, required this.isDark, required this.design});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    
    final pinStart = R * kRailwayR; 
    final pinEnd = pinStart + (R * 0.04); 
    final textR = pinEnd + (R * 0.07);    

    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr, textAlign: TextAlign.center);
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
        canvas.rotate(lineAngle + pi/2); 
        
        if (design != DialDesign.minimal) {
          canvas.drawLine(Offset(0, -pinStart), Offset(0, -pinEnd), Paint()..color = Colors.white..strokeWidth = 2.0..strokeCap = StrokeCap.round);
        }
        canvas.drawCircle(Offset(0, -pinEnd), design == DialDesign.minimal ? 1.0 : 1.5, Paint()..color = Colors.white);

        if (design != DialDesign.minimal || globalLineIndex % 5 == 0) {
          textPainter.text = TextSpan(
            text: globalLineIndex.toString().padLeft(2, '0'), 
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'Playfair Display', shadows: [Shadow(color: Colors.black, blurRadius: 4)])
          );
          textPainter.layout();
          canvas.translate(0, -textR);
          textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
        }
        
        canvas.restore();
        globalLineIndex++;
      }
    }
  }
  @override bool shouldRepaint(covariant OuterRingPainter old) => old.isDark != isDark || old.dayStart != dayStart || old.design != design || old.periods.length != periods.length; 
}

class DividerRingPainter extends CustomPainter {
  final List<AstroPeriod> periods;
  final DateTime dayStart;
  final DateTime dayEnd;
  final bool isDark;
  final DialDesign design;
  
  DividerRingPainter({required this.periods, required this.dayStart, required this.dayEnd, required this.isDark, required this.design});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    final innerR = R * kInnerR;
    final outerR = R * kRailwayR; 

    for (var period in periods) {
      final angle = timeToAngle(period.startTime, dayStart, dayEnd);
      final p1 = Offset(center.dx + innerR * cos(angle), center.dy + innerR * sin(angle));
      final p2 = Offset(center.dx + outerR * cos(angle), center.dy + outerR * sin(angle));
      
      if (design == DialDesign.minimal) {
        canvas.drawLine(p1, p2, Paint()..color = isDark ? Colors.white24 : Colors.black26..strokeWidth = 1.5..strokeCap = StrokeCap.round);
        continue;
      }

      canvas.drawLine(p1, p2, Paint()..color = isDark ? Colors.black : Colors.white..strokeWidth = 6.0..strokeCap = StrokeCap.round);
      canvas.drawLine(p1, p2, Paint()..color = goldBase..strokeWidth = 2.5..strokeCap = StrokeCap.round);
      
      canvas.drawCircle(p2, 4.0, Paint()..color = goldBase);
      canvas.drawCircle(p2, 2.0, Paint()..color = isDark ? Colors.black : Colors.white);
    }
  }
  
  @override bool shouldRepaint(covariant DividerRingPainter old) => old.isDark != isDark || old.dayStart != dayStart || old.design != design || old.periods.length != periods.length;
}