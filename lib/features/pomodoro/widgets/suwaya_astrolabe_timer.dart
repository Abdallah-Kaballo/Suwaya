import 'dart:math' show pi, cos, sin;
import 'package:flutter/material.dart';

class SuwayaAstrolabeTimer extends StatelessWidget {
  final double globalProgress; 
  final double focusRatio; 
  final Color periodColor;
  final bool isBreak;
  final double size;

  const SuwayaAstrolabeTimer({
    super.key,
    required this.globalProgress,
    required this.focusRatio,
    required this.periodColor,
    required this.isBreak,
    this.size = 300.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      // 🌟 الرسوم المتحركة أصبحت أسلس وتتفاعل مع قرارات AstroEngine
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: globalProgress),
        duration: const Duration(milliseconds: 1000), // تحديث كل ثانية من الـ Provider
        curve: Curves.linear, // استخدام Linear لمنع التقطيع مع المحرك
        builder: (context, animatedProgress, child) {
          return CustomPaint(
            painter: _AstrolabePainter(
              progress: animatedProgress,
              focusRatio: focusRatio,
              periodColor: periodColor,
              isBreak: isBreak,
            ),
          );
        },
      ),
    );
  }
}

class _AstrolabePainter extends CustomPainter {
  final double progress;
  final double focusRatio;
  final Color periodColor;
  final bool isBreak;

  _AstrolabePainter({
    required this.progress,
    required this.focusRatio,
    required this.periodColor,
    required this.isBreak,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final trackRadius = radius * 0.90; 
    final mapRadius = radius * 0.78;   

    const startAngle = -pi / 2;
    const totalSweep = 2 * pi;

    final mapRect = Rect.fromCircle(center: center, radius: mapRadius);
    final focusSweep = totalSweep * focusRatio;
    final breakSweep = totalSweep * (1 - focusRatio);

    canvas.drawCircle(center, mapRadius, Paint()..color = Colors.white.withValues(alpha: 0.03)..style = PaintingStyle.stroke..strokeWidth = 10);

    canvas.drawArc(
      mapRect, startAngle, focusSweep - 0.05, false, 
      Paint()..color = periodColor.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round
    );

    if (breakSweep > 0) {
      canvas.drawArc(
        mapRect, startAngle + focusSweep + 0.05, breakSweep - 0.05, false, 
        Paint()..color = Colors.white.withValues(alpha: 0.15)..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round
      );
    }

    canvas.drawCircle(center, trackRadius, Paint()..color = Colors.white.withValues(alpha: 0.02)..style = PaintingStyle.stroke..strokeWidth = 2);
    
    for (int i = 0; i < 60; i++) {
      final angle = startAngle + (i / 60) * totalSweep;
      final isMajor = i % 5 == 0;
      final tickLength = isMajor ? 6.0 : 3.0;
      final innerP = Offset(center.dx + cos(angle) * (trackRadius - tickLength), center.dy + sin(angle) * (trackRadius - tickLength));
      final outerP = Offset(center.dx + cos(angle) * (trackRadius + tickLength), center.dy + sin(angle) * (trackRadius + tickLength));
      canvas.drawLine(innerP, outerP, Paint()..color = Colors.white.withValues(alpha: isMajor ? 0.2 : 0.05)..strokeWidth = isMajor ? 1.5 : 1.0);
    }

    final currentSweep = progress * totalSweep;
    final progressRect = Rect.fromCircle(center: center, radius: trackRadius);
    final activeColor = isBreak ? Colors.white70 : periodColor;

    canvas.drawArc(
      progressRect, startAngle, currentSweep, false, 
      Paint()..color = activeColor.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 6..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8)
    );

    canvas.drawArc(
      progressRect, startAngle, currentSweep, false, 
      Paint()..color = activeColor..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round
    );

    final orbAngle = startAngle + currentSweep;
    final orbCenter = Offset(center.dx + cos(orbAngle) * trackRadius, center.dy + sin(orbAngle) * trackRadius);

    canvas.drawCircle(orbCenter, 12, Paint()..color = activeColor.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(orbCenter, 5, Paint()..color = Colors.white);
    canvas.drawCircle(orbCenter, 5, Paint()..color = activeColor..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _AstrolabePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isBreak != isBreak || oldDelegate.periodColor != periodColor;
  }
}