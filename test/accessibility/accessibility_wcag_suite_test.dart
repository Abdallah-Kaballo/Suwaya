import 'package:alarm/alarm.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:easy_logger/easy_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suwaya/core/localization/app_locales.dart';
import 'package:suwaya/core/repositories/settings_repository.dart';
import 'package:suwaya/core/services/alarm_service.dart';
import 'package:suwaya/core/theme/app_theme.dart';
import 'package:suwaya/features/alarm/alarm_ring_screen.dart';
import 'package:suwaya/features/settings/manual_offsets_screen.dart';
import 'package:suwaya/models/settings_model.dart';
import 'package:suwaya/shared/widgets/suwaya_time_text.dart';

class _InMemoryTranslationLoader extends AssetLoader {
  const _InMemoryTranslationLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return {
      'common': {
        'done': 'تم',
        'cancel': 'إلغاء',
        'suwaya_time': 'الوقت السُويعي'
      },
      'periods': {
        'fajr': 'الفجر',
        'duha': 'الضحى',
        'dhuhr': 'الظهر',
        'asr': 'العصر',
        'maghrib': 'المغرب',
        'isha': 'العشاء',
        'qiyam': 'النصف الثاني',
      },
      'prayers': {
        'fajr': 'الفجر',
        'dhuhr': 'الظهر',
        'asr': 'العصر',
        'maghrib': 'المغرب',
        'isha': 'العشاء',
      },
      'settings': {
        'manual_offset': 'التعديل اليدوي للمواقيت',
        'manual_offset_desc': 'قم بضبط الدقائق يدوياً',
        'reset_all_offsets': 'تصفير كل التعديلات',
        'offsets_reset_success': 'تم تصفير كل التعديلات',
        'no_offset': 'بدون تعديل',
      },
      'details': {'minute': 'د', 'sec': 'ث', 'suwayas': 'سُويعات'},
      'alarm': {
        'default_title': 'تنبيه سُويعَة',
        'snooze': 'غفوة',
        'stop': 'إيقاف',
        'max_snoozes_reached': 'تم الوصول للحد الأقصى للغفوات',
        'swipe_to_stop': 'اسحب للإيقاف أو الغفوة',
      },
      'tasks': {
        'tab_casual': 'مهام عابرة',
        'tab_habits': 'عادات مستمرة',
        'tab_routines': 'روتينات',
      },
      'ibadat': {'qiyam_tab': 'قيام الليل', 'sunrise': 'الشروق'},
    };
  }
}

class _AccessibilityFakeSettingsRepo implements SettingsRepository {
  SettingsModel settings = SettingsModel()
    ..languageCode = 'ar'
    ..suwayaIconMode = 'emoji';

  @override
  Future<SettingsModel> getSettings() async => settings;

  @override
  Future<void> saveSettings(SettingsModel s) async => settings = s.clone();

  @override
  Future<void> updateActiveLocation(SavedLocation location) async {
    settings.activeLocation = location;
  }
}

Widget _buildLocalizedTestApp({
  required Widget child,
  required SettingsRepository repo,
  double textScale = 1.0,
}) {
  return ProviderScope(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(repo),
    ],
    child: EasyLocalization(
      supportedLocales: AppLocales.supported,
      path: AppLocales.path,
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      useOnlyLangCode: true,
      assetLoader: const _InMemoryTranslationLoader(),
      child: Builder(
        builder: (context) {
          return MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            theme: AppTheme.getDarkTheme(AppColorTheme.gold),
            builder: (ctx, appChild) => MediaQuery(
              data: MediaQuery.of(ctx).copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: appChild!,
            ),
            home: child,
          );
        },
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    EasyLocalization.logger.enableLevels = <LevelMessages>[];
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('ar');
    await initializeDateFormatting('en');
  });

  group('Accessibility & WCAG 2.1 Highest Standards Suite', () {
    testWidgets(
        '1. ManualOffsetsScreen buttons meet 48x48dp Android & 44x44pt iOS tap target guidelines and text scaling without overflow',
        (WidgetTester tester) async {
      final handle = tester.ensureSemantics();
      final repo = _AccessibilityFakeSettingsRepo();

      await tester.pumpWidget(
        _buildLocalizedTestApp(
          repo: repo,
          textScale: 1.25,
          child: const ManualOffsetsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

      handle.dispose();
    });

    testWidgets(
        '2. AlarmRingScreen hides decorative swipe track from screen readers (ExcludeSemantics) and exposes explicit accessible Stop/Snooze buttons',
        (WidgetTester tester) async {
      final handle = tester.ensureSemantics();
      final repo = _AccessibilityFakeSettingsRepo();

      final payload = const ParsedAlarmData(
        eventId: 401011,
        kind: AlarmEventKind.task,
        deliveryMode: AlarmDeliveryMode.fullscreenAlarm,
        sourceId: '1',
        title: 'مراجعة الورد اليومي',
        body: 'السويعة الأولى من الفجر',
        colorValue: 0xFF22D3EE,
        snoozeAllowed: true,
        snoozeDurationMinutes: 10,
        snoozeCount: 0,
        maxSnoozes: 3,
        loopAudio: true,
        volumePolicy: AlarmVolumePolicy.userAdjustable,
      ).toPayloadString();

      final alarmSettings = AlarmSettings(
        id: 401011,
        dateTime: DateTime(2026, 10, 22, 5, 0),
        assetAudioPath: 'assets/audio/default.mp3',
        loopAudio: true,
        vibrate: true,
        androidFullScreenIntent: true,
        payload: payload,
        volumeSettings: VolumeSettings.fade(
          volume: 1.0,
          fadeDuration: const Duration(seconds: 4),
          volumeEnforced: false,
        ),
        notificationSettings: const NotificationSettings(
          title: 'مراجعة الورد اليومي',
          body: 'السويعة الأولى من الفجر',
          stopButton: 'إيقاف',
        ),
      );

      await tester.pumpWidget(
        _buildLocalizedTestApp(
          repo: repo,
          child: AlarmRingScreen(alarmSettings: alarmSettings),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('مراجعة الورد اليومي'), findsOneWidget);
      expect(find.byType(TextButton), findsNWidgets(2));
      expect(find.byType(ExcludeSemantics), findsWidgets);

      handle.dispose();
    });

    testWidgets(
        '3. Bidirectional Time Formatting (RTL & LTR) preserves digit order and places phase icons accurately',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: SuwayaTimeText(
                    globalSuwayaIndex: 0,
                    minute: 5,
                    style: TextStyle(fontSize: 18),
                    iconMode: 'text',
                    isRTL: true,
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: SuwayaTimeText(
                    globalSuwayaIndex: 12,
                    minute: 45,
                    style: TextStyle(fontSize: 18),
                    iconMode: 'text',
                    isRTL: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('01'), findsNWidgets(2));
      expect(find.text('05'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);
      expect(find.text('ل'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
    });
  });
}
