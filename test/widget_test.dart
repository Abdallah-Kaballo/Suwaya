import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya/main.dart';

void main() {
  group('اختبارات واجهة التطبيق (Widget Tests)', () {
    testWidgets(
      'اختبار عمل شاشة الإقلاع البديلة بنجاح (Bootstrap Failure Screen)',
      (WidgetTester tester) async {
        bool retried = false;

        await tester.pumpWidget(
          BootstrapFailureScreen(
            error: 'خطأ تجريبي لاختبار الواجهة',
            onRetry: () {
              retried = true;
            },
          ),
        );

        // التحقق من ظهور رسالة الخطأ التقني التي مررناها
        expect(find.text('خطأ تجريبي لاختبار الواجهة'), findsOneWidget);

        // التحقق من وجود أيقونة التحذير وزر إعادة المحاولة
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
        expect(retried, isFalse);
      },
    );
  });
}
