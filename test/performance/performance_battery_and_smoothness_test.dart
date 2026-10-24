import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:easy_logger/easy_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suwaya/core/astro_engine/astro_provider.dart';
import 'package:suwaya/core/localization/app_locales.dart';
import 'package:suwaya/core/repositories/routine_repository.dart';
import 'package:suwaya/core/repositories/settings_repository.dart';
import 'package:suwaya/core/repositories/task_repository.dart';
import 'package:suwaya/core/theme/dial_design_provider.dart';
import 'package:suwaya/features/home/widgets/dial/painters/dynamic_elements_painters.dart';
import 'package:suwaya/features/home/widgets/dial/painters/rings_painters.dart';
import 'package:suwaya/features/home/widgets/premium_astro_dial.dart';
import 'package:suwaya/features/routines/routines_provider.dart';
import 'package:suwaya/features/settings/settings_provider.dart';
import 'package:suwaya/models/routine_model.dart';
import 'package:suwaya/models/settings_model.dart';
import 'package:suwaya/models/task_model.dart';
import 'package:suwaya_time/suwaya_time.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;

class _PerfTranslationLoader extends AssetLoader {
  const _PerfTranslationLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return {
      'periods': {
        'maghrib': 'المغرب',
        'isha': 'العشاء',
        'qiyam': 'النصف الثاني',
        'fajr': 'الفجر',
        'duha': 'الضحى',
        'dhuhr': 'الظهر',
        'asr': 'العصر',
      },
      'prayers': {
        'fajr': 'الفجر',
        'dhuhr': 'الظهر',
        'asr': 'العصر',
        'maghrib': 'المغرب',
        'isha': 'العشاء',
      },
      'night_parts': {
        'half_2': 'النصف الأخير',
        'third_3': 'الثلث الأخير',
        'sixth_4': 'السدس الرابع',
        'sixth_5': 'السدس الخامس',
        'sixth_6': 'السدس السادس',
      },
      'ibadat': {'sunrise': 'الشروق'},
    };
  }
}

class _PerfSettingsRepo implements SettingsRepository {
  SettingsModel settings = SettingsModel()
    ..activeLocation = (SavedLocation()
      ..name = 'Makkah'
      ..latitude = 21.4225
      ..longitude = 39.8262
      ..timezone = 'Asia/Riyadh');

  @override
  Future<SettingsModel> getSettings() async => settings;
  @override
  Future<void> saveSettings(SettingsModel s) async => settings = s.clone();
  @override
  Future<void> updateActiveLocation(SavedLocation loc) async =>
      settings.activeLocation = loc;
}

class _PerfTaskRepo implements TaskRepository {
  final List<TaskModel> tasks = [];
  @override
  Future<List<TaskModel>> getActiveTasks() async => tasks;
  @override
  Future<List<TaskModel>> getAllTasks() async => tasks;
  @override
  Future<void> saveTask(TaskModel task) async {
    tasks.removeWhere((t) => t.id == task.id);
    tasks.add(task);
  }

  @override
  Future<void> deleteTask(int id) async => tasks.removeWhere((t) => t.id == id);
  @override
  Future<void> deleteTasks(List<int> ids) async =>
      tasks.removeWhere((t) => ids.contains(t.id));
  @override
  Future<List<TaskModel>> getRecentCompletedTasks(DateTime since) async => [];
  @override
  Future<TaskModel?> getTaskById(int id) async =>
      tasks.where((t) => t.id == id).firstOrNull;
}

class _PerfRoutineRepo implements RoutineRepository {
  @override
  Future<List<RoutineModel>> getAllRoutines() async => [];
  @override
  Future<void> saveRoutine(RoutineModel routine) async {}
  @override
  Future<void> deleteRoutine(int id) async {}
}

void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    SharedPreferences.setMockInitialValues({});
    EasyLocalization.logger.enableLevels = <LevelMessages>[];
    await EasyLocalization.ensureInitialized();
  });

  group('1. Battery & Lifecycle Optimization Tests', () {
    testWidgets(
        'AstroNotifier suspends all periodic timers when app is paused/hidden and resumes cleanly on resume',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(_PerfSettingsRepo()),
          taskRepositoryProvider.overrideWithValue(_PerfTaskRepo()),
          routineRepositoryProvider.overrideWithValue(_PerfRoutineRepo()),
        ],
      );

      await container.read(settingsProvider.notifier).initialized;
      await tester.pump();

      final initialState = container.read(astroProvider);
      expect(initialState.periods.length, 7);

      // 1. محاكاة انتقال التطبيق إلى الخلفية (Pause)
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      int notificationsWhilePaused = 0;
      void listener() => notificationsWhilePaused++;
      virtualDateTimeNotifier.addListener(listener);

      // مرور 5 ثوانٍ في الخلفية: يجب ألا يعمل أي مؤقت (0% استهلاك بطارية)
      await tester.pump(const Duration(seconds: 5));
      expect(
        notificationsWhilePaused,
        equals(0),
        reason:
            'UI Timer continued ticking while app was paused in background!',
      );

      virtualDateTimeNotifier.removeListener(listener);

      // 2. محاكاة عودة التطبيق للواجهة (Resume)
      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.hidden,
      );

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.inactive,
      );

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pump(const Duration(seconds: 2));

      expect(container.read(astroProvider).periods.length, 7);

      // 🌟 إغلاق الحاوية صراحةً قبل نهاية testWidgets لإلغاء المؤقتات النشطة (_stateTimer و _uiTimer)
      container.dispose();
      await tester.pump();
    });
  });

  group('2. CustomPainter Repaint Guard & 60/120fps Smoothness Tests', () {
    test(
        'PeriodRingPainter, OuterRingPainter, RailwayRingPainter, and RoutinesRingPainter return shouldRepaint == false when inputs are unchanged',
        () {
      final day = SuwayaTimeEngine.generateDay(
        21.4225,
        39.8262,
        DateTime.utc(2026, 10, 22),
        CalculationMethodType.ummAlQura,
        MadhabType.shafi,
        HighLatitudeRuleType.middleOfTheNight,
        18.5,
        18.0,
        const Duration(hours: 3),
      );

      final dayStart = day.periods.first.startTime;
      final dayEnd = day.periods.last.endTime;

      final p1 = PeriodRingPainter(
        periods: day.periods,
        currentPeriod: day.periods.first,
        dayStart: dayStart,
        dayEnd: dayEnd,
        isDark: true,
        langCode: 'ar',
        design: DialDesign.classic,
        totalRotation: 0.0,
      );
      final p2 = PeriodRingPainter(
        periods: day.periods,
        currentPeriod: day.periods.first,
        dayStart: dayStart,
        dayEnd: dayEnd,
        isDark: true,
        langCode: 'ar',
        design: DialDesign.classic,
        totalRotation: 0.001,
      );
      expect(p2.shouldRepaint(p1), isFalse);

      final o1 = OuterRingPainter(
        periods: day.periods,
        dayStart: dayStart,
        dayEnd: dayEnd,
        isDark: true,
        design: DialDesign.classic,
        pinMode: 'suwaya24',
        totalRotation: 0.0,
      );
      final o2 = OuterRingPainter(
        periods: day.periods,
        dayStart: dayStart,
        dayEnd: dayEnd,
        isDark: true,
        design: DialDesign.classic,
        pinMode: 'suwaya24',
        totalRotation: 0.001,
      );
      expect(o2.shouldRepaint(o1), isFalse);

      final r1 = RailwayRingPainter(
        ibadat: day.ibadatTimings,
        nightMarkers: const [],
        tasks: const [],
        periods: day.periods,
        dayStart: dayStart,
        dayEnd: dayEnd,
        isDark: true,
        langCode: 'ar',
        design: DialDesign.classic,
        totalRotation: 0.0,
      );
      final r2 = RailwayRingPainter(
        ibadat: day.ibadatTimings,
        nightMarkers: const [],
        tasks: const [],
        periods: day.periods,
        dayStart: dayStart,
        dayEnd: dayEnd,
        isDark: true,
        langCode: 'ar',
        design: DialDesign.classic,
        totalRotation: 0.001,
      );
      expect(r2.shouldRepaint(r1), isFalse);

      final arc = RoutineArcData(
        id: 1,
        color: Colors.cyan,
        startAngle: 0,
        sweepAngle: math.pi / 3,
        startTime: dayStart,
        endTime: dayStart.add(const Duration(hours: 2)),
      );
      final rr1 = RoutinesRingPainter(
        routineArcs: [arc],
        isDark: true,
        design: DialDesign.classic,
      );
      final rr2 = RoutinesRingPainter(
        routineArcs: [arc],
        isDark: true,
        design: DialDesign.classic,
      );
      expect(rr2.shouldRepaint(rr1), isFalse);
    });

    testWidgets(
        'PremiumAstroDial handles interactive touch pan rotation and elastic snap-back smoothly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(_PerfSettingsRepo()),
            taskRepositoryProvider.overrideWithValue(_PerfTaskRepo()),
            routineRepositoryProvider.overrideWithValue(_PerfRoutineRepo()),
          ],
          child: EasyLocalization(
            supportedLocales: AppLocales.supported,
            path: AppLocales.path,
            fallbackLocale: const Locale('ar'),
            startLocale: const Locale('ar'),
            useOnlyLangCode: true,
            assetLoader: const _PerfTranslationLoader(),
            child: Builder(
              builder: (context) => MaterialApp(
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                home: const Scaffold(
                  body: Center(
                    child: PremiumAstroDial(
                      size: 360,
                      routineArcs: [],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final dialFinder = find.byType(PremiumAstroDial);
      expect(dialFinder, findsOneWidget);

      // محاكاة سحب القرص الفلكي وإفلاته
      final gesture = await tester.startGesture(const Offset(250, 180));
      for (int i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(-5, 8));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 1100));
      expect(tester.takeException(), isNull);

      // 🌟 تفكيك الشجرة قبل انتهاء الاختبار لإيقاف مؤقتات astroProvider النشطة
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}
