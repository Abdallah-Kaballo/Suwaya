import 'dart:math';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import '../../../core/astro_engine/astro_models.dart';

class MiniAstroDial extends StatelessWidget {
  final List<AstroPeriod> periods;
  final bool isDark;

  const MiniAstroDial({super.key, required this.periods, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (periods.isEmpty) return const SizedBox.shrink();
    final currentLang = context.locale.languageCode;
    
    return RepaintBoundary(
      child: SizedBox(
        width: 130, height: 130, 
        child: CustomPaint(
          isComplex: true, 
          willChange: false, 
          painter: _MiniDialPainter(periods: periods, isDark: isDark, langCode: currentLang),
        ),
      ),
    );
  }
}

class _MiniDialPainter extends CustomPainter {
  final List<AstroPeriod> periods;
  final bool isDark;
  final String langCode;

  _MiniDialPainter({required this.periods, required this.isDark, required this.langCode});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.30; 
    final textPainter = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.center);

    double currentAngle = -pi / 2; 

    for (var period in periods) {
      final sweepAngle = (period.suwayasCount / 48) * 2 * pi;
      
      final paint = Paint()
        ..color = period.color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), currentAngle, sweepAngle, true, paint);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), currentAngle, sweepAngle, true, Paint()..color = period.color..style = PaintingStyle.stroke..strokeWidth = 1.5);

      final middleAngle = currentAngle + (sweepAngle / 2);

      final innerTextR = radius * 0.6;
      final innerP = Offset(center.dx + innerTextR * cos(middleAngle), center.dy + innerTextR * sin(middleAngle));
      
      // 🌟 التعديل هنا: الخط الفلكي (Playfair Display) لأرقام السويعات على القرص
      textPainter.text = TextSpan(text: period.suwayasCount.toString(), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'Playfair Display', letterSpacing: 0.5));
      textPainter.layout();
      textPainter.paint(canvas, innerP - Offset(textPainter.width / 2, textPainter.height / 2));

      String pName = '';
      switch(period.id) {
        case 1: pName = 'periods.fajr'.tr(); break;
        case 2: pName = 'periods.duha'.tr(); break;
        case 3: pName = 'periods.dhuhr'.tr(); break;
        case 4: pName = 'periods.asr'.tr(); break;
        case 5: pName = 'periods.maghrib'.tr(); break;
        case 6: pName = 'periods.middle_third'.tr(); break;
        case 7: pName = 'periods.last_third'.tr(); break;
      }

      String outerText = pName.isNotEmpty ? '${period.id}\n($pName)' : period.id.toString();

      final outerTextR = radius + 15;
      final outerP = Offset(center.dx + outerTextR * cos(middleAngle), center.dy + outerTextR * sin(middleAngle));
      
      textPainter.text = TextSpan(text: outerText, style: TextStyle(color: period.color, fontSize: 9, fontWeight: FontWeight.bold, height: 1.2));
      textPainter.layout();
      textPainter.paint(canvas, outerP - Offset(textPainter.width / 2, textPainter.height / 2));

      currentAngle += sweepAngle;
    }
  }

  @override bool shouldRepaint(covariant _MiniDialPainter old) => old.periods != periods || old.isDark != isDark || old.langCode != langCode;
}