import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';

import 'core/bootstrap/app_bootstrap.dart';
import 'core/database/database_provider.dart';
import 'core/database/database_service.dart';
import 'core/localization/app_locales.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_color_provider.dart';
import 'core/astro_engine/astro_provider.dart';
import 'features/settings/settings_provider.dart';
import 'core/router/app_router.dart';

// 🌟 استيراد خدمة الترحيل وشاشة رنين المنبه الموحدة
import 'core/services/migration_service.dart';
import 'features/alarm/alarm_ring_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppBootstrap.initialize();
  runApp(const LoadingBootstrapScreen());
}

class LoadingBootstrapScreen extends StatefulWidget {
  const LoadingBootstrapScreen({super.key});
  @override
  State<LoadingBootstrapScreen> createState() => _LoadingBootstrapScreenState();
}

class _LoadingBootstrapScreenState extends State<LoadingBootstrapScreen> {
  @override
  void initState() {
    super.initState();
    _loadDatabase();
  }

  Future<void> _loadDatabase() async {
    try {
      final isar = await DatabaseService.init();

      // 🌟 1. إنشاء الحاوية (Container) مع تمرير قاعدة البيانات (Isar)
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWithValue(isar),
        ],
      );

      // 🌟 2. تشغيل خدمة الترحيل الآن بأمان لأن قاعدة البيانات تعمل
      await container.read(migrationServiceProvider).runMigrationsIfNeeded();

      if (!mounted) return;

      // 🌟 3. استخدام الحاوية التي أنشأناها لتشغيل التطبيق
      runApp(
        UncontrolledProviderScope(
          container: container,
          child: EasyLocalization(
            supportedLocales: AppLocales.supported,
            path: AppLocales.path,
            fallbackLocale: AppLocales.fallback,
            useOnlyLangCode: true,
            child: const SuwayaApp(),
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('💥 Failure in initialization: $e\n$stackTrace');
      if (!mounted) return;
      runApp(BootstrapFailureScreen(error: e.toString(), onRetry: _loadDatabase));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF13131A),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      ),
    );
  }
}

class BootstrapFailureScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const BootstrapFailureScreen({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = ui.PlatformDispatcher.instance.locale.languageCode == 'ar';
    final errorTitle = isAr
        ? 'عذراً، حدث خطأ أثناء بدء التشغيل'
        : 'Sorry, a startup error occurred';
    final retryText = isAr ? 'إعادة المحاولة' : 'Retry';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: const Color(0xFF13131A),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.amber, size: 64),
                  const SizedBox(height: 24),
                  Text(errorTitle,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(error,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 12),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
                      onPressed: () {
                        runApp(const MaterialApp(
                            debugShowCheckedModeBanner: false,
                            home: Scaffold(
                                backgroundColor: Color(0xFF13131A),
                                body: Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.amber)))));
                        onRetry();
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(retryText,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SuwayaApp extends ConsumerStatefulWidget {
  const SuwayaApp({super.key});

  @override
  ConsumerState<SuwayaApp> createState() => _SuwayaAppState();
}

class _SuwayaAppState extends ConsumerState<SuwayaApp> {
  StreamSubscription<AlarmSet>? _alarmSubscription;
  int? _activeRingingAlarmId;

  @override
  void initState() {
    super.initState();
    // 🌟 استخدام التدفق الحديث Alarm.ringing بدلاً من ringStream المهمل
    _alarmSubscription = Alarm.ringing.listen((AlarmSet alarmSet) {
      if (alarmSet.alarms.isNotEmpty) {
        _onAlarmRinging(alarmSet.alarms.first);
      }
    });
  }

  Future<void> _onAlarmRinging(AlarmSettings alarmSettings) async {
    if (_activeRingingAlarmId == alarmSettings.id) return;
    _activeRingingAlarmId = alarmSettings.id;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final navState = rootNavigatorKey.currentState;
      if (navState != null) {
        await navState.push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => AlarmRingScreen(alarmSettings: alarmSettings),
          ),
        );
      }
      _activeRingingAlarmId = null;
    });
  }

  @override
  void dispose() {
    _alarmSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final activeColorTheme = ref.watch(themeColorProvider);
    final goRouter = ref.watch(routerProvider);

    final bool isDayTime = ref.watch(astroProvider.select((state) {
      if (state.periods.isEmpty) {
        final hour = DateTime.now().hour;
        return hour >= 6 && hour < 18;
      }
      return state.currentSuwayaTime.phase.isDay;
    }));

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Suwaya',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      themeMode: AppTheme.getThemeMode(settings.themeMode, isDayTime: isDayTime),
      theme: AppTheme.getLightTheme(activeColorTheme),
      darkTheme: AppTheme.getDarkTheme(activeColorTheme),
      routerConfig: goRouter,
    );
  }
}