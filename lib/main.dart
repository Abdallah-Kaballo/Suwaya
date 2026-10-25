import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
// 🌟 تم إضافة هذا الاستيراد لتعريف أزرار الصوت (HardwareKeyboard)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/services.dart';

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
import 'features/routines/routines_provider.dart';
import 'features/tasks/tasks_provider.dart';
import 'core/notification/scheduler_service.dart';
import 'core/services/alarm_service.dart';

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
        overrides: [isarProvider.overrideWithValue(isar)],
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
      runApp(
        BootstrapFailureScreen(error: e.toString(), onRetry: _loadDatabase),
      );
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
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    errorTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      error,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        runApp(
                          const MaterialApp(
                            debugShowCheckedModeBanner: false,
                            home: Scaffold(
                              backgroundColor: Color(0xFF13131A),
                              body: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          ),
                        );
                        onRetry();
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        retryText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
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

// استبدل الكلاس _SuwayaAppState في lib/main.dart بالكامل بما يلي:

class _SuwayaAppState extends ConsumerState<SuwayaApp>
    with WidgetsBindingObserver {
  StreamSubscription<AlarmSet>? _alarmSubscription;
  StreamSubscription<void>? _hardwareVolumeSub;
  int? _pushedFullScreenAlarmId;
  AlarmSettings? _activeBannerAlarm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hardwareVolumeSub = AlarmService.onHardwareVolumeAction.listen((_) {
      _handleBannerHardwareVolumeAction();
    });
    HardwareKeyboard.instance.addHandler(_handleGlobalHardwareKey);

    _alarmSubscription = Alarm.ringing.listen((AlarmSet alarmSet) async {
      final hasRinging = alarmSet.alarms.isNotEmpty;
      try {
        await AlarmService.lockscreenChannel.invokeMethod(
          'setAlarmRingingState',
          {'ringing': hasRinging},
        );
      } catch (_) {}

      if (!hasRinging) {
        _pushedFullScreenAlarmId = null;
        if (_activeBannerAlarm != null && mounted) {
          setState(() => _activeBannerAlarm = null);
        }
        return;
      }

      final ringingAlarm = alarmSet.alarms.first;
      bool isLocked = false;
      try {
        isLocked =
            await AlarmService.lockscreenChannel.invokeMethod<bool>(
              'isDeviceLocked',
            ) ??
            false;
      } catch (_) {}

      if (isLocked) {
        if (mounted && _activeBannerAlarm != null) {
          setState(() => _activeBannerAlarm = null);
        }
        _openFullScreenAlarm(ringingAlarm);
      } else {
        if (_pushedFullScreenAlarmId != ringingAlarm.id && mounted) {
          setState(() => _activeBannerAlarm = ringingAlarm);
        }
      }
    });
  }

  Future<void> _handleBannerHardwareVolumeAction() async {
    // إذا كانت شاشة الرنين الكاملة مفتوحة، فهي التي تتولى معالجة الغفوة أو الإيقاف
    if (_pushedFullScreenAlarmId != null) return;
    final bannerAlarm = _activeBannerAlarm;
    if (bannerAlarm == null) return;

    final settings = ref.read(settingsProvider);
    final parsed = AlarmService.parseAlarmSettings(bannerAlarm);
    final maxSnoozes = settings.maxSnoozeCount > 0
        ? settings.maxSnoozeCount
        : parsed.maxSnoozes;
    final canSnooze =
        parsed.kind != AlarmEventKind.prayer &&
        parsed.snoozeAllowed &&
        parsed.snoozeCount < maxSnoozes;

    if (canSnooze) {
      await _snoozeBannerAlarm(bannerAlarm);
    } else {
      await _stopAllActiveAlarms();
    }
  }

  bool _handleGlobalHardwareKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        _pushedFullScreenAlarmId == null &&
        _activeBannerAlarm != null &&
        (event.logicalKey == LogicalKeyboardKey.audioVolumeDown ||
            event.logicalKey == LogicalKeyboardKey.audioVolumeUp)) {
      _handleBannerHardwareVolumeAction();
      return true;
    }
    return false;
  }

  Future<void> _stopAllActiveAlarms() async {
    final bannerId = _activeBannerAlarm?.id;
    final fullScreenId = _pushedFullScreenAlarmId;
    if (bannerId != null) {
      await Alarm.stop(bannerId);
    }
    if (fullScreenId != null && fullScreenId != bannerId) {
      await Alarm.stop(fullScreenId);
    }
    if (mounted && _activeBannerAlarm != null) {
      setState(() => _activeBannerAlarm = null);
    }
  }

  Future<void> _snoozeBannerAlarm(AlarmSettings alarmSettings) async {
    final settings = ref.read(settingsProvider);
    final parsed = AlarmService.parseAlarmSettings(alarmSettings);
    final snoozeMins = settings.snoozeDurationMinutes > 0
        ? settings.snoozeDurationMinutes
        : parsed.snoozeDurationMinutes;
    final maxSnoozes = settings.maxSnoozeCount > 0
        ? settings.maxSnoozeCount
        : parsed.maxSnoozes;

    final res = await AlarmService.snooze(
      alarmSettings,
      snoozeMinutesOverride: snoozeMins,
      maxSnoozesOverride: maxSnoozes,
    );
    if (res.success && mounted) {
      setState(() => _activeBannerAlarm = null);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final settings = ref.read(settingsProvider);
      final tasks = ref.read(tasksProvider).allTasks;
      final routines = ref.read(routinesProvider);
      ref
          .read(notificationSchedulerProvider)
          .scheduleAhead(settings, tasks, routines);
    }
  }

  Future<void> _openFullScreenAlarm(AlarmSettings alarmSettings) async {
    if (_pushedFullScreenAlarmId == alarmSettings.id) return;
    _pushedFullScreenAlarmId = alarmSettings.id;

    try {
      await AlarmService.lockscreenChannel.invokeMethod('showOnLockScreen');
    } catch (_) {}

    Future<void> pushRoute(NavigatorState navState) async {
      WidgetsBinding.instance.scheduleFrame();
      await navState.push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => AlarmRingScreen(alarmSettings: alarmSettings),
        ),
      );
      _pushedFullScreenAlarmId = null;
    }

    final navState = rootNavigatorKey.currentState;
    if (navState != null) {
      await pushRoute(navState);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final deferredNav = rootNavigatorKey.currentState;
        if (deferredNav != null) {
          await pushRoute(deferredNav);
        } else {
          _pushedFullScreenAlarmId = null;
        }
      });
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalHardwareKey);
    _hardwareVolumeSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _alarmSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final activeColorTheme = ref.watch(themeColorProvider);
    final goRouter = ref.watch(routerProvider);

    final bool isDayTime = ref.watch(
      astroProvider.select((state) {
        if (state.periods.isEmpty) {
          final hour = DateTime.now().hour;
          return hour >= 6 && hour < 18;
        }
        return state.currentSuwayaTime.phase.isDay;
      }),
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Suwaya',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      themeMode: AppTheme.getThemeMode(
        settings.themeMode,
        isDayTime: isDayTime,
      ),
      theme: AppTheme.getLightTheme(activeColorTheme),
      darkTheme: AppTheme.getDarkTheme(activeColorTheme),
      routerConfig: goRouter,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final safeMediaQuery = mediaQuery.copyWith(
          textScaler: mediaQuery.textScaler.clamp(
            minScaleFactor: 0.85,
            maxScaleFactor: 1.25,
          ),
        );
        final bannerAlarm = _activeBannerAlarm;
        final appContent = MediaQuery(
          data: safeMediaQuery,
          child: child ?? const SizedBox.shrink(),
        );
        if (bannerAlarm == null) return appContent;

        final parsed = AlarmService.parseAlarmSettings(bannerAlarm);
        final maxSnoozes = settings.maxSnoozeCount > 0
            ? settings.maxSnoozeCount
            : parsed.maxSnoozes;
        final canSnooze =
            parsed.kind != AlarmEventKind.prayer &&
            parsed.snoozeAllowed &&
            parsed.snoozeCount < maxSnoozes;
        final accentColor = Color(parsed.colorValue);

        return Stack(
          children: [
            appContent,
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Material(
                    elevation: 12,
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFF161922),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() => _activeBannerAlarm = null);
                        _openFullScreenAlarm(bannerAlarm);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accentColor, width: 1.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.notifications_active_rounded,
                                  color: accentColor,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        parsed.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (parsed.body.isNotEmpty)
                                        Text(
                                          parsed.body,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (canSnooze) ...[
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.amber.withValues(
                                        alpha: 0.16,
                                      ),
                                      foregroundColor: Colors.amber,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () =>
                                        _snoozeBannerAlarm(bannerAlarm),
                                    icon: const Icon(Icons.snooze, size: 17),
                                    label: Text('alarm.snooze'.tr()),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.redAccent
                                        .withValues(alpha: 0.2),
                                    foregroundColor: Colors.redAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () async {
                                    await Alarm.stop(bannerAlarm.id);
                                    if (mounted) {
                                      setState(() => _activeBannerAlarm = null);
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.stop_circle_outlined,
                                    size: 18,
                                  ),
                                  label: Text('alarm.stop'.tr()),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
