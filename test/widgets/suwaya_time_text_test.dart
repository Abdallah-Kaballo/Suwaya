import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:suwaya/core/repositories/settings_repository.dart';
import 'package:suwaya/models/settings_model.dart';
import 'package:suwaya/shared/widgets/suwaya_time_text.dart';

class _FakeSettingsRepository implements SettingsRepository {
  SettingsModel _settings;
  _FakeSettingsRepository([SettingsModel? initial])
    : _settings = initial ?? SettingsModel();

  @override
  Future<SettingsModel> getSettings() async => _settings;

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    _settings = settings.clone();
  }

  @override
  Future<void> updateActiveLocation(SavedLocation location) async {
    _settings.activeLocation = location;
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  testWidgets(
    'SuwayaTimeText renders correctly in image badge and text modes (RTL & LTR)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  SuwayaTimeText(
                    globalSuwayaIndex: 5, // السويعة 06 ليلاً
                    minute: 30,
                    style: TextStyle(fontSize: 16),
                    iconMode: 'emoji',
                    isRTL: false,
                  ),
                  SuwayaTimeText(
                    globalSuwayaIndex: 14, // السويعة 03 نهاراً
                    minute: 15,
                    style: TextStyle(fontSize: 16),
                    iconMode: 'text',
                    isRTL: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SuwayaTimeText), findsNWidgets(2));
      expect(find.byType(SuwayaPhaseBadge), findsNWidgets(2));
      expect(find.text('06'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      // التحقق من عرض صورة القمر المضغوطة بدلاً من الإيموجي النصي القديم
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('03'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('ن'), findsOneWidget);
    },
  );

  testWidgets(
    'ClockTimeText renders suwaya and civil time correctly with overridden repository',
    (WidgetTester tester) async {
      final fakeRepo = _FakeSettingsRepository(
        SettingsModel()..suwayaIconMode = 'emoji',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [settingsRepositoryProvider.overrideWithValue(fakeRepo)],
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const ClockTimeText.suwaya(
                    globalSuwayaIndex: 5,
                    virtualMinute: 30,
                    style: TextStyle(fontSize: 16),
                  ),
                  ClockTimeText.civil(
                    civilTime: DateTime(2026, 10, 22, 14, 45),
                    civilTimeFormat: '24-hour',
                    locale: 'en',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(ClockTimeText), findsNWidgets(2));
      expect(find.text('06'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
    },
  );
}
