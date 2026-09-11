import 'package:flutter/material.dart';

class PatternPreviewPainter extends CustomPainter {
  final String pattern;
  final Color color;
  
  PatternPreviewPainter(this.pattern, this.color);
  
  @override 
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    canvas.drawRRect(rRect, Paint()..color = color.withValues(alpha: 0.2)..style = PaintingStyle.fill);
    canvas.drawRRect(rRect, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2);
    
    final p = Paint()..color = color..strokeWidth = 2;
    if (pattern == 'linear') {
      canvas.drawLine(const Offset(0, 10), const Offset(30, 10), p);
      canvas.drawLine(const Offset(0, 20), const Offset(30, 20), p);
    } else if (pattern == 'hexagon') {
      canvas.drawLine(const Offset(0, 0), const Offset(30, 30), p);
      canvas.drawLine(const Offset(30, 0), const Offset(0, 30), p);
    } else if (pattern == 'stone') {
      canvas.drawCircle(const Offset(10, 10), 3, p);
      canvas.drawCircle(const Offset(20, 20), 3, p);
    } else {
      canvas.drawLine(const Offset(15, 0), const Offset(15, 30), p);
      canvas.drawLine(const Offset(0, 15), const Offset(30, 15), p);
    }
  }

  @override 
  bool shouldRepaint(covariant CustomPainter old) => true;
}