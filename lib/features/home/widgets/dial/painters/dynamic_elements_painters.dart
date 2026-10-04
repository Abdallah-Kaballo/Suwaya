import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:suwaya/core/theme/dial_design_provider.dart';
import 'package:suwaya/models/task_model.dart';
import 'package:suwaya_time/suwaya_time.dart';

import '../dial_constants.dart';
import '../dial_pin_layout.dart';
import '../dial_models.dart';

List<DialMarkerLayout> layoutDialMarkers({
  required Size size,
  required dynamic ibadat,
  required List<Map<String, dynamic>> nightMarkers,
  required List<DialTask> tasks,
  required DialDesign design,
  required DateTime dayStart,
  required DateTime dayEnd,
}) {
  final radius = size.width / 2;
  final innerRadius = radius * kPeriodR;
  final outerRadius = radius * kRailwayR;
  final trackStep = (outerRadius - innerRadius) / 3;
  final outerTrackTip = outerRadius - 8.0;
  final trackRadii = [
    outerTrackTip,
    outerTrackTip - trackStep,
    outerTrackTip - trackStep * 2,
  ];

  final prayerItems = <UnifiedDialItem>[
    UnifiedDialItem(
        id: 'prayer:fajr',
        text: 'prayers.fajr'.tr(),
        time: ibadat.fajr,
        color: goldLight,
        isPrayer: true),
    UnifiedDialItem(
        id: 'prayer:dhuhr',
        text: 'prayers.dhuhr'.tr(),
        time: ibadat.dhuhr,
        color: goldLight,
        isPrayer: true),
    UnifiedDialItem(
        id: 'prayer:asr',
        text: 'prayers.asr'.tr(),
        time: ibadat.asr,
        color: goldLight,
        isPrayer: true),
    UnifiedDialItem(
        id: 'prayer:maghrib',
        text: 'prayers.maghrib'.tr(),
        time: ibadat.maghrib,
        color: goldLight,
        isPrayer: true),
    UnifiedDialItem(
        id: 'prayer:isha',
        text: 'prayers.isha'.tr(),
        time: ibadat.isha,
        color: goldLight,
        isPrayer: true),
    for (final marker in nightMarkers)
      UnifiedDialItem(
        id: 'marker:${marker['n']}:${(marker['t'] as DateTime).microsecondsSinceEpoch}',
        text: marker['n'] as String,
        time: marker['t'] as DateTime,
        color: goldBase,
        isPrayer: true,
      ),
  ];

  final occupied = <List<Map<String, double>>>[[], [], []];
  final layouts = <DialMarkerLayout>[];
  for (final item in prayerItems) {
    final angle = timeToAngle(item.time, dayStart, dayEnd);
    layouts
        .add(DialMarkerLayout(item: item, angle: angle, radius: trackRadii[0]));
    occupied[0].add({'angle': angle, 'margin': 0.04});
    final badgeRadius = trackRadii[0] - trackStep * 0.4;
    if (design != DialDesign.minimal) {
      layouts.add(DialMarkerLayout(
          item: item, angle: angle, radius: badgeRadius, isBadge: true));
    }
    occupied[1].add({'angle': angle, 'margin': 0.10});
  }

  final taskItems = tasks
      .map((task) => UnifiedDialItem(
            id: 'task:${task.taskModel.id}',
            taskModel: task.taskModel,
            text: task.shortName,
            time: task.time,
            color: task.color,
          ))
      .toList()
    ..sort((a, b) => a.time.compareTo(b.time));

  for (final item in taskItems) {
    final angle = timeToAngle(item.time, dayStart, dayEnd);
    var targetTrack = 2;
    const taskMargin = 0.04;
    for (var track = 0; track < occupied.length; track++) {
      var isFree = true;
      for (final existing in occupied[track]) {
        var difference = (angle - existing['angle']!).abs();
        if (difference > pi) difference = 2 * pi - difference;
        if (difference < taskMargin + existing['margin']!) {
          isFree = false;
          break;
        }
      }
      if (isFree) {
        targetTrack = track;
        break;
      }
    }
    occupied[targetTrack].add({'angle': angle, 'margin': taskMargin});
    layouts.add(DialMarkerLayout(
      item: item,
      angle: angle,
      radius: trackRadii[targetTrack],
    ));
  }
  return layouts;
}

DialMarkerLayout? hitTestDialMarker({
  required Offset position,
  required Size size,
  required double totalRotation,
  required List<DialMarkerLayout> layouts,
}) {
  final center = size.center(Offset.zero);
  final radius = size.width / 2;
  final candidates = layouts.map((layout) {
    final angle = layout.angle + totalRotation;
    final markerPosition = Offset(
      center.dx + layout.radius * cos(angle),
      center.dy + layout.radius * sin(angle),
    );
    return (layout: layout, distance: (position - markerPosition).distance);
  }).where((candidate) {
    final tolerance = candidate.layout.isBadge
        ? max(18.0, radius * 0.055)
        : max(15.0, radius * 0.045);
    return candidate.distance <= tolerance;
  }).toList()
    ..sort((a, b) => a.distance.compareTo(b.distance));
  return candidates.isEmpty ? null : candidates.first.layout;
}

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
  final String? highlightedMarkerId;
  final String dialPinMode;

  RailwayRingPainter({
    required this.ibadat,
    required this.nightMarkers,
    required this.tasks,
    required this.periods,
    required this.dayStart,
    required this.dayEnd,
    required this.isDark,
    this.draggedTask,
    this.dragAngle,
    required this.langCode,
    required this.design,
    this.highlightedTaskId,
    this.highlightedMarkerId,
    this.dialPinMode = 'suwaya48',
  });

  void _drawEquilateralArrow(Canvas canvas, Offset center, double radius,
      double baseWidth, double angle, Color color,
      {bool isDragged = false,
      bool isPrayer = false,
      bool isHighlighted = false}) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle + pi / 2);
    canvas.translate(0, -radius);

    if (isDragged || isHighlighted) canvas.scale(1.4);

    if (design == DialDesign.minimal) {
      if (isDragged || isHighlighted) {
        canvas.drawCircle(
          Offset.zero,
          8.0,
          Paint()
            ..color = color.withValues(alpha: 0.9)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
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

    if (isDragged || isHighlighted) {
      canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }

    canvas.drawPath(path, Paint()..color = color);

    if (!isPrayer) {
      final inner = Path()
        ..moveTo(0, -height + 2)
        ..lineTo(-baseWidth / 2 + 2, -1)
        ..lineTo(baseWidth / 2 - 2, -1)
        ..close();
      canvas.drawPath(
          inner, Paint()..color = Colors.white.withValues(alpha: 0.8));
    }
    canvas.restore();
  }

  void _drawTextBadge(Canvas canvas, Offset center, double radius, double angle,
      String text, Color color,
      {bool isHighlighted = false}) {
    if (design == DialDesign.minimal) return;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle + pi / 2);
    canvas.translate(0, -radius);

    if (isHighlighted) {
      canvas.drawCircle(
          Offset.zero,
          12,
          Paint()
            ..color = color.withValues(alpha: 0.8)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    }

    final textPainterStroke = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              fontFamily: 'Tajawal',
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.6
                ..color = Colors.white)),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    textPainterStroke.paint(canvas,
        Offset(-textPainterStroke.width / 2, -textPainterStroke.height / 2));

    final textPainterFill = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              fontFamily: 'Tajawal',
              shadows: [
                Shadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 4,
                    offset: const Offset(0, 1))
              ])),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    textPainterFill.paint(canvas,
        Offset(-textPainterFill.width / 2, -textPainterFill.height / 2));

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

    canvas.drawCircle(
        center,
        innerRadius + (width / 2),
        Paint()
          ..color = isDark
              ? Colors.black.withValues(alpha: 0.8)
              : Colors.black.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = width);
    canvas.drawCircle(
        center,
        outerRadius,
        Paint()
          ..color = goldBase.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);

    const int numTracks = 3;
    final double trackStep = width / numTracks;

    final double outerTrackTip = outerRadius - 8.0;
    final double midTrackTip = outerTrackTip - trackStep;
    final double innerTrackTip = midTrackTip - trackStep;
    final trackRadii = [outerTrackTip, midTrackTip, innerTrackTip];

    if (design != DialDesign.minimal) {
      for (var r in trackRadii) {
        canvas.drawCircle(
            center,
            r,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.1)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.5);
      }
    }

    final stationPaint = Paint()
      ..color = goldLight.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
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
          canvas.drawCircle(
              Offset(center.dx + r * cos(angle), center.dy + r * sin(angle)),
              design == DialDesign.minimal ? 0.5 : 1.2,
              stationPaint);
        }
      }
    }

    if (dialPinMode == 'civil24') {
      final pinRadiusBand = buildSuwayaPinRadiusBand(R);
      final pinPaint = Paint()
        ..color = goldLight.withValues(alpha: 0.9)
        ..strokeWidth = design == DialDesign.minimal ? 1.0 : 1.5
        ..strokeCap = StrokeCap.round;
      for (final angle in buildSuwayaPinAngles(periods, dayStart, dayEnd)) {
        canvas.drawLine(
          Offset(center.dx + pinRadiusBand.innerRadius * cos(angle),
              center.dy + pinRadiusBand.innerRadius * sin(angle)),
          Offset(center.dx + pinRadiusBand.outerRadius * cos(angle),
              center.dy + pinRadiusBand.outerRadius * sin(angle)),
          pinPaint,
        );
      }
    }

    final markerLayouts = layoutDialMarkers(
      size: size,
      ibadat: ibadat,
      nightMarkers: nightMarkers,
      tasks: tasks,
      design: design,
      dayStart: dayStart,
      dayEnd: dayEnd,
    );
    for (final layout
        in markerLayouts.where((layout) => layout.item.isPrayer)) {
      final isHighlighted = layout.item.id == highlightedMarkerId;
      if (layout.isBadge) {
        _drawTextBadge(canvas, center, layout.radius, layout.angle,
            layout.item.text, layout.item.color,
            isHighlighted: isHighlighted);
      } else {
        _drawEquilateralArrow(canvas, center, layout.radius, 12.0, layout.angle,
            layout.item.color,
            isPrayer: true, isHighlighted: isHighlighted);
      }
    }

    for (final layout
        in markerLayouts.where((layout) => !layout.item.isPrayer)) {
      final item = layout.item;
      final isDragged =
          draggedTask != null && item.taskModel!.id == draggedTask!.id;
      final isHighlighted = highlightedTaskId == item.taskModel!.id ||
          item.id == highlightedMarkerId;
      final angle = isDragged && dragAngle != null ? dragAngle! : layout.angle;
      _drawEquilateralArrow(
          canvas, center, layout.radius, 12.0, angle, item.color,
          isDragged: isDragged, isPrayer: false, isHighlighted: isHighlighted);
    }
  }

  @override
  bool shouldRepaint(covariant RailwayRingPainter old) {
    if (old.isDark != isDark ||
        old.draggedTask?.id != draggedTask?.id ||
        old.dragAngle != dragAngle ||
        old.langCode != langCode ||
        old.design != design ||
        old.highlightedTaskId != highlightedTaskId ||
        old.highlightedMarkerId != highlightedMarkerId ||
        old.dialPinMode != dialPinMode ||
        old.dayStart != dayStart ||
        old.dayEnd != dayEnd ||
        old.ibadat.fajr != ibadat.fajr ||
        old.ibadat.sunrise != ibadat.sunrise ||
        old.ibadat.dhuhr != ibadat.dhuhr ||
        old.ibadat.asr != ibadat.asr ||
        old.ibadat.maghrib != ibadat.maghrib ||
        old.ibadat.isha != ibadat.isha ||
        old.ibadat.nextFajr != ibadat.nextFajr ||
        old.nightMarkers.length != nightMarkers.length ||
        old.tasks.length != tasks.length) {
      return true;
    }

    if (old.periods.length != periods.length) return true;
    for (var i = 0; i < periods.length; i++) {
      final previous = old.periods[i];
      final current = periods[i];
      if (previous.startTime != current.startTime ||
          previous.endTime != current.endTime ||
          previous.suwayasCount != current.suwayasCount) {
        return true;
      }
    }

    for (int i = 0; i < nightMarkers.length; i++) {
      final a = old.nightMarkers[i];
      final b = nightMarkers[i];
      if (a['n'] != b['n'] || a['t'] != b['t']) return true;
    }

    for (int i = 0; i < tasks.length; i++) {
      final a = old.tasks[i];
      final b = tasks[i];
      if (a.taskModel.id != b.taskModel.id ||
          a.time != b.time ||
          a.color != b.color ||
          a.shortName != b.shortName) {
        return true;
      }
    }

    return false;
  }
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

    final Path base = Path()
      ..moveTo(-14, 0)
      ..lineTo(-8, -6)
      ..quadraticBezierTo(0, -8, 8, -6)
      ..lineTo(14, 0)
      ..close();
    final shader = const LinearGradient(colors: [goldLight, goldBase, goldDark])
        .createShader(const Rect.fromLTRB(-15, -30, 15, 0));
    final metalPaint = Paint()..shader = shader;

    canvas.drawPath(
        base,
        Paint()
          ..color = Colors.black
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawPath(base, metalPaint);
    canvas.drawPath(
        base,
        Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);

    final Rect hoopRect =
        Rect.fromCircle(center: const Offset(0, -16), radius: 14);
    canvas.drawArc(
        hoopRect,
        0,
        2 * pi,
        false,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    canvas.drawArc(
        hoopRect,
        0,
        2 * pi,
        false,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0);
    canvas.drawArc(
        hoopRect,
        0,
        2 * pi,
        false,
        Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);

    canvas.drawCircle(const Offset(0, -32), 4.0, metalPaint);
    canvas.drawCircle(
        const Offset(0, -32),
        4.0,
        Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);

    canvas.drawLine(
        const Offset(-6, -2),
        const Offset(-6, -5),
        Paint()
          ..color = Colors.black54
          ..strokeWidth = 1.5);
    canvas.drawLine(
        const Offset(6, -2),
        const Offset(6, -5),
        Paint()
          ..color = Colors.black54
          ..strokeWidth = 1.5);
    canvas.drawCircle(const Offset(0, -4), 2.5, Paint()..color = Colors.white);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CrownPainter old) => false;
}

class DynamicNeedlePainter extends CustomPainter {
  final DateTime currentTime;
  final DateTime dayStart;
  final DateTime dayEnd;
  final bool isDark;
  final DialDesign design;

  DynamicNeedlePainter(
      {required this.currentTime,
      required this.dayStart,
      required this.dayEnd,
      required this.isDark,
      required this.design});

  double get angle => timeToAngle(currentTime, dayStart, dayEnd);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    final angle = this.angle;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle + pi / 2);

    final needleLength = R * kRailwayR - 8.0;
    final needleStart = R * 0.25;

    if (design == DialDesign.minimal) {
      canvas.drawLine(
          Offset(0, -needleStart),
          Offset(0, -needleLength),
          Paint()
            ..color = const Color(0xFF007BFF)
            ..strokeWidth = 2.0
            ..strokeCap = StrokeCap.round);
      canvas.drawCircle(Offset(0, -needleLength), 4.0,
          Paint()..color = const Color(0xFF007BFF));
      canvas.restore();
      return;
    }

    final stripedPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        const Offset(8, 8),
        [
          const Color(0xFF007BFF),
          const Color(0xFF007BFF),
          const Color(0xFFFFD700),
          const Color(0xFFFFD700)
        ],
        [0.0, 0.5, 0.5, 1.0],
        TileMode.repeated,
      );

    // 🌟 تنفيذ الطلب 9: زيادة توهج العقرب وإبرازه بخط أبيض ناصع
    canvas.drawLine(
        Offset(0, -needleStart),
        Offset(0, -needleLength),
        Paint()
          ..color = const Color(0xFF007BFF).withValues(alpha: 0.8)
          ..strokeWidth = 8.0
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));

    canvas.drawLine(
        Offset(0, -needleStart),
        Offset(0, -needleLength),
        stripedPaint
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke);

    // قلب ناصع البياض للعقرب ليكون بارزاً
    canvas.drawLine(
        Offset(0, -needleStart),
        Offset(0, -needleLength),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round);

    final Path compassArrow = Path()
      ..moveTo(0, -needleLength - 8)
      ..lineTo(-5, -needleLength + 4)
      ..lineTo(5, -needleLength + 4)
      ..close();

    canvas.drawPath(compassArrow, stripedPaint..style = PaintingStyle.fill);
    canvas.drawPath(
        compassArrow,
        Paint()
          ..color = isDark ? Colors.black87 : Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DynamicNeedlePainter old) =>
      old.currentTime != currentTime || old.design != design;
}
