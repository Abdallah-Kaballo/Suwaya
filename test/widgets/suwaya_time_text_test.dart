import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:suwaya/core/utils/time_formatters.dart';
import 'package:suwaya/shared/widgets/suwaya_time_text.dart';

void main() {
  group('formatSuwayaTime', () {
    test('pads both components and accepts a custom text separator', () {
      expect(formatSuwayaTime(3, 7), '03:07');
      expect(formatSuwayaTime(3, 7, separator: '|'), '03|07');
    });

    test('carries a full virtual half-hour into the next Suwaya', () {
      expect(formatSuwayaTime(3, 30, separator: '|'), '04|00');
    });
  });

  testWidgets('civil clocks support explicit 12 and 24 hour styles',
      (tester) async {
    await initializeDateFormatting('en');
    final civilTime = DateTime(2026, 10, 4, 16, 5);
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            ClockTimeText.civil(
              civilTime: civilTime,
              civilTimeFormat: civilTimeFormat12Hour,
              locale: 'en',
              style: const TextStyle(fontSize: 16),
            ),
            ClockTimeText.civil(
              civilTime: civilTime,
              civilTimeFormat: civilTimeFormat24Hour,
              locale: 'en',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );

    expect(find.text('4:05 PM'), findsOneWidget);
    expect(find.text('16:05'), findsOneWidget);
  });

  testWidgets('system civil format follows the device 24-hour preference',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(alwaysUse24HourFormat: true),
          child: ClockTimeText.civil(
            civilTime: DateTime(2026, 10, 4, 16, 5),
            civilTimeFormat: civilTimeFormatSystem,
            locale: 'en',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );

    expect(find.text('16:05'), findsOneWidget);
  });

  testWidgets('SuwayaTimeText uses LTR direction and draws a short separator',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: SuwayaTimeText(
            globalSuwayaIndex: 3,
            minute: 7,
            style: TextStyle(fontSize: 20, color: Color(0xFFF2C94C)),
          ),
        ),
      ),
    );

    final richText = tester.widget<RichText>(find.byType(RichText));
    expect(richText.text.toPlainText(includePlaceholders: false), '0307');
    final textSpan = richText.text as TextSpan;
    expect(textSpan.children, hasLength(3));
    expect(textSpan.children![1], isA<WidgetSpan>());
    final directionality = tester.widget<Directionality>(find
        .ancestor(
            of: find.byType(RichText), matching: find.byType(Directionality))
        .first);
    expect(directionality.textDirection, TextDirection.ltr);
    expect(find.byType(Container), findsOneWidget);
    expect(tester.getSize(find.byType(Container)).height, closeTo(9.6, 0.1));
    final separator = tester.widget<Container>(find.byType(Container));
    expect((separator.decoration! as BoxDecoration).color, Colors.white);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == '03|07',
      ),
      findsOneWidget,
    );
  });
}
