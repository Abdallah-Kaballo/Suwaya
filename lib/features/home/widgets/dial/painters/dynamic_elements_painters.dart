import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:suwaya/core/theme/dial_design_provider.dart';
import 'package:suwaya/models/task_model.dart';
import 'package:suwaya_time/suwaya_time.dart';

import '../dial_constants.dart';
import '../dial_models.dart';

class RailwayRingPainter extends CustomPainter {
  final dynamic ibadat;
  final List<Map<String, dynamic>> nightMarkers;
  final List<DialTask> tasks; 
  final List<AstroPeriod> periods; 
  final DateTime dayStart;
  final DateTime dayEnd;
  final bool isDark;
  final TaskModel? draggedTask; 
  final double? dragAngle;      
  final String langCode;
  final DialDesign design;
  final int? highlightedTaskId; 
  
  RailwayRingPainter({
    required this.ibadat, required this.nightMarkers, required this.tasks, required this.periods,
    required this.dayStart, required this.dayEnd, required this.isDark,
    this.draggedTask, this.dragAngle, required this.langCode, required this.design, this.highlightedTaskId,
  });

  void _drawEquilateralArrow(Canvas canvas, Offset center, double radius, double baseWidth, double angle, Color color, {bool isDragged = false, bool isPrayer = false, bool isHighlighted = false}) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle + pi / 2);
    canvas.translate(0, -radius);
    
    if (isDragged || isHighlighted) canvas.scale(1.4); 

    if (design == DialDesign.minimal) {
      canvas.drawCircle(Offset.zero, 4.0, Paint()..color = color);
      canvas.restore();
      return;
    }

    final double height = baseWidth * 0.866; 

    final path = Path();
    path.moveTo(0, -height); 
    path.lineTo(-baseWidth / 2, 0); 
    path.lineTo(baseWidth / 2, 0); 
    path.close();

    if (isPrayer || isDragged || isHighlighted) {
       canvas.drawPath(path, Paint()..color = color..maskFilter = MaskFilter.blur(BlurStyle.normal, (isDragged || isHighlighted) ? 10 : 3));
    }
    canvas.drawPath(path, Paint()..color = color); 
    
    if (!isPrayer) {
      final inner = Path()..moveTo(0, -height + 2)..lineTo(-baseWidth / 2 + 2, -1)..lineTo(baseWidth / 2 - 2, -1)..close();
      canvas.drawPath(inner, Paint()..color = Colors.white.withValues(alpha: 0.8));
    }
    canvas.restore();
  }

  void _drawTextBadge(Canvas canvas, Offset center, double radius, double angle, String text, Color color) {
    if (design == DialDesign.minimal) return; 

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle + pi / 2);
    canvas.translate(0, -radius);

    final textPainterStroke = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'Tajawal', foreground: Paint()..style=PaintingStyle.stroke..strokeWidth=0.6..color=Colors.white)),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    textPainterStroke.paint(canvas, Offset(-textPainterStroke.width / 2, -textPainterStroke.height / 2));

    final textPainterFill = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'Tajawal', shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 4, offset: const Offset(0, 1))])),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    textPainterFill.paint(canvas, Offset(-textPainterFill.width / 2, -textPainterFill.height / 2));
    
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (ibadat == null || ibadat.maghrib == null) return;
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    
    final innerRadius = R * kPeriodR;
    final outerRadius = R * kRailwayR;
    final width = outerRadius - innerRadius;

    canvas.drawCircle(center, innerRadius + (width / 2), Paint()..color = isDark ? Colors.black.withValues(alpha: 0.8) : Colors.black.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = width);
    canvas.drawCircle(center, outerRadius, Paint()..color = goldBase.withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = 1.0);
    
    const int numTracks = 3;
    final double trackStep = width / numTracks;
    
    final double outerTrackTip = outerRadius - 8.0; 
    final double midTrackTip = outerTrackTip - trackStep;
    final double innerTrackTip = midTrackTip - trackStep;
    final trackRadii = [outerTrackTip, midTrackTip, innerTrackTip];

    if (design != DialDesign.minimal) {
      for (var r in trackRadii) {
         canvas.drawCircle(center, r, Paint()..color = Colors.white.withValues(alpha: 0.1)..style = PaintingStyle.stroke..strokeWidth = 0.5);
      }
    }

    final stationPaint = Paint()..color = goldLight.withValues(alpha: 0.2)..style = PaintingStyle.fill;
    for (var period in periods) {
      final startAngle = timeToAngle(period.startTime, dayStart, dayEnd);
      final endAngle = timeToAngle(period.endTime, dayStart, dayEnd);
      double sweepAngle = endAngle - startAngle;
      if (sweepAngle <= 0) sweepAngle += 2 * pi;
      final suwayaAngle = sweepAngle / period.suwayasCount;

      for (int i = 0; i < period.suwayasCount; i++) {
        final angle = startAngle + (i * suwayaAngle);
        for (int t = 0; t < numTracks; t++) {
          final r = trackRadii[t] - (trackStep * 0.433);
          canvas.drawCircle(Offset(center.dx + r * cos(angle), center.dy + r * sin(angle)), design == DialDesign.minimal ? 0.5 : 1.2, stationPaint);
        }
      }
    }

    List<UnifiedDialItem> prayersList = [];
    prayersList.add(UnifiedDialItem(text: 'prayers.fajr'.tr(), time: ibadat.fajr, color: goldLight, isPrayer: true));
    prayersList.add(UnifiedDialItem(text: 'prayers.dhuhr'.tr(), time: ibadat.dhuhr, color: goldLight, isPrayer: true));
    prayersList.add(UnifiedDialItem(text: 'prayers.asr'.tr(), time: ibadat.asr, color: goldLight, isPrayer: true));
    prayersList.add(UnifiedDialItem(text: 'prayers.maghrib'.tr(), time: ibadat.maghrib, color: goldLight, isPrayer: true));
    prayersList.add(UnifiedDialItem(text: 'prayers.isha'.tr(), time: ibadat.isha, color: goldLight, isPrayer: true));
    for(var nm in nightMarkers) { prayersList.add(UnifiedDialItem(text: nm['n'] as String, time: nm['t'] as DateTime, color: goldBase, isPrayer: true)); }

    List<List<Map<String, double>>> occupied = [[], [], []];

    for (var p in prayersList) {
      double angle = timeToAngle(p.time, dayStart, dayEnd);
      
      _drawEquilateralArrow(canvas, center, trackRadii[0], 12.0, angle, p.color, isPrayer: true);
      occupied[0].add({'angle': angle, 'margin': 0.04});
      
      double midBadgeCenter = trackRadii[0] - (trackStep * 0.4); 
      _drawTextBadge(canvas, center, midBadgeCenter, angle, p.text, p.color);
      occupied[1].add({'angle': angle, 'margin': 0.10}); 
    }

    List<UnifiedDialItem> taskItems = tasks.map((t) => UnifiedDialItem(taskModel: t.taskModel, text: t.shortName, time: t.time, color: t.color, isPrayer: false)).toList();
    taskItems.sort((a, b) => a.time.compareTo(b.time));

    for (var item in taskItems) {
      bool isDragged = draggedTask != null && item.taskModel!.id == draggedTask!.id;
      bool isHighlighted = highlightedTaskId != null && item.taskModel!.id == highlightedTaskId;
      double angle = (isDragged && dragAngle != null) ? dragAngle! : timeToAngle(item.time, dayStart, dayEnd);
      
      int targetTrack = 2; 
      double taskMargin = 0.04;

      for (int t = 0; t < numTracks; t++) {
        bool isFree = true;
        for (var occ in occupied[t]) {
          double diff = (angle - occ['angle']!).abs();
          if (diff > pi) diff = 2 * pi - diff;
          if (diff < (taskMargin + occ['margin']!)) {
            isFree = false;
            break;
          }
        }
        if (isFree) {
          targetTrack = t;
          break;
        }
      }
      
      occupied[targetTrack].add({'angle': angle, 'margin': taskMargin});
      _drawEquilateralArrow(canvas, center, trackRadii[targetTrack], 12.0, angle, item.color, isDragged: isDragged, isPrayer: false, isHighlighted: isHighlighted);
    }
  }
  
  @override 
  bool shouldRepaint(covariant RailwayRingPainter old) => true; 
}

class CrownPainter extends CustomPainter {
  final DateTime dayStart;
  final DateTime dayEnd;
  CrownPainter({required this.dayStart, required this.dayEnd});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    final angle = timeToAngle(dayStart, dayStart, dayEnd); 
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle + pi / 2); 
    canvas.translate(0, -R * kRailwayR); 
    
    final scale = R / 185.0; 
    canvas.scale(scale, scale);

    final Path base = Path()..moveTo(-14, 0)..lineTo(-8, -6)..quadraticBezierTo(0, -8, 8, -6)..lineTo(14, 0)..close();
    final shader = const LinearGradient(colors: [goldLight, goldBase, goldDark]).createShader(const Rect.fromLTRB(-15, -30, 15, 0));
    final metalPaint = Paint()..shader = shader;
    
    canvas.drawPath(base, Paint()..color = Colors.black..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawPath(base, metalPaint);
    canvas.drawPath(base, Paint()..color = Colors.black87..style = PaintingStyle.stroke..strokeWidth = 1.0);
    
    final Rect hoopRect = Rect.fromCircle(center: const Offset(0, -16), radius: 14);
    canvas.drawArc(hoopRect, 0, 2*pi, false, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 5.0..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    canvas.drawArc(hoopRect, 0, 2*pi, false, Paint()..shader = shader..style = PaintingStyle.stroke..strokeWidth = 4.0);
    canvas.drawArc(hoopRect, 0, 2*pi, false, Paint()..color = Colors.black87..style = PaintingStyle.stroke..strokeWidth = 1.0);
    
    canvas.drawCircle(const Offset(0, -32), 4.0, metalPaint);
    canvas.drawCircle(const Offset(0, -32), 4.0, Paint()..color = Colors.black87..style = PaintingStyle.stroke..strokeWidth = 1.0);
    
    canvas.drawLine(const Offset(-6, -2), const Offset(-6, -5), Paint()..color = Colors.black54..strokeWidth = 1.5);
    canvas.drawLine(const Offset(6, -2), const Offset(6, -5), Paint()..color = Colors.black54..strokeWidth = 1.5);
    canvas.drawCircle(const Offset(0, -4), 2.5, Paint()..color = Colors.white); 

    canvas.restore();
  }
  @override bool shouldRepaint(covariant CrownPainter old) => false;
}

class DynamicNeedlePainter extends CustomPainter {
  final DateTime currentTime;
  final DateTime dayStart;
  final DateTime dayEnd;
  final bool isDark;
  final DialDesign design;

  DynamicNeedlePainter({required this.currentTime, required this.dayStart, required this.dayEnd, required this.isDark, required this.design});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    final angle = timeToAngle(currentTime, dayStart, dayEnd);
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle + pi/2); 

    final needleLength = R * kRailwayR - 8.0; 
    final needleStart = R * 0.25; 

    if (design == DialDesign.minimal) {
      canvas.drawLine(Offset(0, -needleStart), Offset(0, -needleLength), Paint()..color = const Color(0xFF007BFF)..strokeWidth = 2.0..strokeCap = StrokeCap.round);
      canvas.drawCircle(Offset(0, -needleLength), 4.0, Paint()..color = const Color(0xFF007BFF));
      canvas.restore();
      return;
    }

    final stripedPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        const Offset(8, 8), 
        [const Color(0xFF007BFF), const Color(0xFF007BFF), const Color(0xFFFFD700), const Color(0xFFFFD700)],
        [0.0, 0.5, 0.5, 1.0],
        TileMode.repeated,
      );

    canvas.drawLine(Offset(0, -needleStart), Offset(0, -needleLength), Paint()..color = const Color(0xFF007BFF).withValues(alpha: 0.3)..strokeWidth = 6.0..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawLine(Offset(0, -needleStart), Offset(0, -needleLength), stripedPaint..strokeWidth = 3.5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);
    
    final Path compassArrow = Path()
      ..moveTo(0, -needleLength - 8) 
      ..lineTo(-5, -needleLength + 4)
      ..lineTo(5, -needleLength + 4)
      ..close();

    canvas.drawPath(compassArrow, stripedPaint..style = PaintingStyle.fill);
    canvas.drawPath(compassArrow, Paint()..color = isDark ? Colors.black87 : Colors.white..style = PaintingStyle.stroke..strokeWidth = 0.8);

    canvas.restore();
  }
  @override bool shouldRepaint(covariant DynamicNeedlePainter old) => old.currentTime != currentTime || old.design != design;
}