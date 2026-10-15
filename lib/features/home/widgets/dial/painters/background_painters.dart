import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:suwaya/core/theme/dial_design_provider.dart';
import 'package:suwaya_time/suwaya_time.dart'; // 🌟 تمت الإضافة

import '../dial_constants.dart';
// 🌟 تمت الإضافة للوصول إلى timeToAngle

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

// 🌟 تأكد من إضافة هذا الاستيراد في أعلى الملف إذا لم يكن موجوداً:
// import 'dart:ui' as ui;

class SkyRingPainter extends CustomPainter {
  final List<AstroPeriod> periods;
  final DateTime dayStart;
  final DateTime dayEnd;
  final bool isDark;
  final DialDesign design;
  final ui.Image? dayImage;   // 🌟 استقبال صورة النهار
  final ui.Image? nightImage; // 🌟 استقبال صورة الليل

  SkyRingPainter({
    required this.periods,
    required this.dayStart,
    required this.dayEnd,
    required this.isDark,
    required this.design,
    this.dayImage,
    this.nightImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (periods.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    final innerRadius = R * kInnerR; 
    final outerRadius = R * kRailwayR;

    double nightStartAngle = 0.0;
    double nightSweep = 0.0;
    double dayStartAngle = 0.0;
    double daySweep = 0.0;

    final nightKeys = [
      PeriodKey.nightMaghribIsha,
      PeriodKey.nightIshaMidnight,
      PeriodKey.nightMidnightFajr,
      PeriodKey.nightFajrSunrise
    ];

    bool firstNightFound = false;
    bool firstDayFound = false;

    for (var period in periods) {
      final startA = timeToAngle(period.startTime, dayStart, dayEnd);
      final endA = timeToAngle(period.endTime, dayStart, dayEnd);
      double sweep = endA - startA;
      if (sweep <= 0) sweep += 2 * pi;

      if (nightKeys.contains(period.periodKey)) {
        if (!firstNightFound) {
          nightStartAngle = startA;
          firstNightFound = true;
        }
        nightSweep += sweep;
      } else {
        if (!firstDayFound) {
          dayStartAngle = startA;
          firstDayFound = true;
        }
        daySweep += sweep;
      }
    }

    Path buildAnnulusPath(double start, double sweep) {
      return Path()
        ..arcTo(Rect.fromCircle(center: center, radius: outerRadius), start, sweep, true)
        ..arcTo(Rect.fromCircle(center: center, radius: innerRadius), start + sweep, -sweep, false)
        ..close();
    }

    void drawSegment(Path path, double start, double sweep, ui.Image? img, Color fallbackTint) {
      canvas.save();
      canvas.clipPath(path);
      
      if (img != null) {
        final middleAngle = start + (sweep / 2);
        
        // تدوير الـ Canvas بحيث تكون الشمس/القمر في منتصف القوس تماماً
        canvas.translate(center.dx, center.dy);
        canvas.rotate(middleAngle + pi / 2);
        canvas.translate(-center.dx, -center.dy);
        
        final rect = Rect.fromCircle(center: center, radius: outerRadius);
        paintImage(canvas: canvas, rect: rect, image: img, fit: BoxFit.cover);
        
        // طبقة تظليل ذكية لضمان وضوح نصوص المهام (Blend Overlay)
        final tintPaint = Paint()
          ..color = isDark 
              ? Colors.black.withValues(alpha: 0.55) // يعمق سواد الليل
              : Colors.white.withValues(alpha: 0.35) // ينعم شمس النهار
          ..style = PaintingStyle.fill;
        canvas.drawRect(rect, tintPaint);
      } else {
        // إذا فشل تحميل الصور، يرسم ألوان احتياطية
        canvas.drawPath(path, Paint()..color = fallbackTint..style = PaintingStyle.fill);
      }
      canvas.restore();
    }

    if (nightSweep > 0) {
      drawSegment(buildAnnulusPath(nightStartAngle, nightSweep), nightStartAngle, nightSweep, nightImage, Colors.indigo.withValues(alpha: isDark ? 0.3 : 0.15));
    }
    if (daySweep > 0) {
      drawSegment(buildAnnulusPath(dayStartAngle, daySweep), dayStartAngle, daySweep, dayImage, Colors.orangeAccent.withValues(alpha: isDark ? 0.2 : 0.15));
    }
  }

  @override
  bool shouldRepaint(covariant SkyRingPainter old) {
    if (old.isDark != isDark || old.design != design || old.periods.length != periods.length || old.dayImage != dayImage || old.nightImage != nightImage) return true;
    for (int i = 0; i < periods.length; i++) {
      if (old.periods[i].startTime != periods[i].startTime || old.periods[i].endTime != periods[i].endTime) return true;
    }
    return false;
  }
}