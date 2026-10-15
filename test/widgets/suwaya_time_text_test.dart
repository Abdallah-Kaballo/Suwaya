import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya/shared/widgets/suwaya_time_text.dart';

void main() {
  testWidgets('SuwayaTimeText renders correctly with required parameters', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SuwayaTimeText(
              globalSuwayaIndex: 5,
              minute: 30,
              style: TextStyle(fontSize: 16),
              iconMode: 'emoji', // 🌟 تمت إضافة المعامل المطلوب
              isRTL: false,      // 🌟 تمت إضافة المعامل المطلوب
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SuwayaTimeText), findsOneWidget);
  });

  testWidgets('ClockTimeText renders suwaya time correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ClockTimeText.suwaya(
              globalSuwayaIndex: 5,
              virtualMinute: 30,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ClockTimeText), findsOneWidget);
  });
}