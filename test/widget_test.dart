import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya/main.dart'; // تأكد من مسار ملف main لديك

void main() {
  group('اختبارات واجهة التطبيق (Widget Tests)', () {
    
    testWidgets('اختبار عمل شاشة الإقلاع البديلة بنجاح (Bootstrap Failure Screen)', (WidgetTester tester) async {
      // 1. بناء شاشة الفشل الوهمية التي تعمل عند تعذر تشغيل قواعد البيانات في بيئة الاختبار
      await tester.pumpWidget(const BootstrapFailureScreen());

      // 2. التحقق من أن واجهة Flutter قادرة على الرسم وعرض النصوص بشكل صحيح
      expect(find.text('حدث خطأ أثناء التشغيل. يرجى إعادة المحاولة.'), findsOneWidget);
      
      // 3. التحقق من الهيكلية (وجود Scaffold)
      expect(find.byType(Scaffold), findsOneWidget);
    });

  });
}