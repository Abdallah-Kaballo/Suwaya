import 'dart:math';
import 'package:flutter/material.dart';
import 'package:suwaya/core/theme/dial_design_provider.dart';

import '../dial_constants.dart';

class BackgroundPainter extends CustomPainter {
  final bool isDark;
  final DialDesign design;
  BackgroundPainter({required this.isDark, required this.design});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    
    if (design == DialDesign.minimal) {
      canvas.drawCircle(center, R, Paint()..color = isDark ? const Color(0xFF13131A) : const Color(0xFFF8F9FA));
      return;
    }
    
    final bgPaint = Paint()..shader = RadialGradient(colors: isDark ? [const Color(0xFF13131A), const Color(0xFF030305)] : [const Color(0xFFF8F9FA), const Color(0xFFE2E8F0)]).createShader(Rect.fromCircle(center: center, radius: R));
    canvas.drawCircle(center, R, bgPaint);
    
    if (!isDark) return; 
    
    if (design == DialDesign.classic) {
      final rand = Random(42); 
      final paint = Paint();
      for (int i = 0; i < 90; i++) {
        final x = rand.nextDouble() * size.width;
        final y = rand.nextDouble() * size.height;
        final s = rand.nextDouble() * 2.0 + 1.0;
        paint.color = Colors.white.withValues(alpha: rand.nextDouble() * 0.5 + 0.1);
        Path starPath = Path()..moveTo(x, y - s)..quadraticBezierTo(x, y, x + s, y)..quadraticBezierTo(x, y, x, y + s)..quadraticBezierTo(x, y, x - s, y)..quadraticBezierTo(x, y, x, y - s);
        canvas.drawPath(starPath, paint);
      }
    }
  }
  @override bool shouldRepaint(covariant BackgroundPainter old) => old.isDark != isDark || old.design != design;
}

class IslamicRetePainter extends CustomPainter {
  final bool isDark;
  IslamicRetePainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    final rRete = R * kInnerR; 

    canvas.save();
    canvas.translate(center.dx, center.dy);
    final paint = Paint()..color = goldBase.withValues(alpha: 0.15)..style = PaintingStyle.stroke..strokeWidth = 1.0;
    
    final path1 = Path()..addPolygon([Offset(0, -rRete), Offset(rRete, 0), Offset(0, rRete), Offset(-rRete, 0)], true);
    canvas.drawPath(path1, paint);
    final d = rRete * 0.7071; 
    final path2 = Path()..addPolygon([Offset(d, -d), Offset(d, d), Offset(-d, d), Offset(-d, -d)], true);
    canvas.drawPath(path2, paint);
    canvas.drawCircle(Offset.zero, rRete * 0.8, paint);
    canvas.drawCircle(Offset.zero, rRete * 0.6, paint);
    canvas.restore();
  }
  @override bool shouldRepaint(covariant IslamicRetePainter old) => old.isDark != isDark;
}

class GeometricRetePainter extends CustomPainter {
  final bool isDark;
  GeometricRetePainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    final rRete = R * kInnerR; 

    canvas.save();
    canvas.translate(center.dx, center.dy);
    final paint = Paint()..color = goldBase.withValues(alpha: 0.2)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    
    final rectPath = Path()..addRect(Rect.fromCircle(center: Offset.zero, radius: rRete * 0.8));
    canvas.drawPath(rectPath, paint);
    canvas.rotate(pi / 4);
    canvas.drawPath(rectPath, paint);
    canvas.restore();
  }
  @override bool shouldRepaint(covariant GeometricRetePainter old) => old.isDark != isDark;
}