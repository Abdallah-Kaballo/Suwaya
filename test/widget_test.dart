import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya/main.dart'; 

void main() {
  group('اختبارات واجهة التطبيق (Widget Tests)', () {
    testWidgets('اختبار عمل شاشة الإقلاع البديلة بنجاح (Bootstrap Failure Screen)', (WidgetTester tester) async {
      
      // 1. بناء الشاشة مع تمرير المعاملات الجديدة
      await tester.pumpWidget(
        BootstrapFailureScreen(
          error: 'خطأ تجريبي لاختبار الواجهة',
          onRetry: () {},
        ),
      );

      // 2. التحقق من وجود العنوان الجديد
      expect(find.text('عذراً، حدث خطأ أثناء بدء التشغيل'), findsOneWidget);
      
      // 3. التحقق من ظهور رسالة الخطأ التقني التي مررناها
      expect(find.text('خطأ تجريبي لاختبار الواجهة'), findsOneWidget);
      
      // 4. التحقق من وجود زر إعادة المحاولة
      expect(find.text('إعادة المحاولة'), findsOneWidget);
    });
  });
}