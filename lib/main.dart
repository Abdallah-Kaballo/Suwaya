import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart'; 
import 'core/astro_engine/astro_provider.dart';
import 'core/database/local_db_service.dart';
import 'core/services/geo_seed_service.dart';
import 'core/notification/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/settings_provider.dart';
import 'features/splash/splash_screen.dart';
import 'package:alarm/alarm.dart';
import 'core/services/alarm_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/theme_color_provider.dart';
import 'core/sync/sync_wrapper.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  tz.initializeTimeZones();
  await Alarm.init();
  await AlarmService.init();

  try {
    await Future.wait([
      EasyLocalization.ensureInitialized(),
      LocalDbService.init(),
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      initializeDateFormatting(), 
    ]);

    _setupErrorHandlers();
    
    // 🌟 التعديل الأول: إضافة await لضمان تهيئة Supabase قبل تشغيل الواجهة
    await _initBackgroundServices();

    runApp(
      ProviderScope(
        child: EasyLocalization(
          supportedLocales: const [
            Locale('ar'), Locale('en'), Locale('tr'), Locale('ru'), Locale('ur'),
            Locale('hi'), Locale('bn'), Locale('th'), Locale('ja'), Locale('zh'),
            Locale('ug'), Locale('pt'), Locale('ff'), Locale('az'), Locale('id'),
            Locale('ms'), Locale('da'), Locale('de'), Locale('es'), Locale('fr'),
            Locale('it'), Locale('nl'),
          ],
          path: 'assets/translations',
          fallbackLocale: const Locale('ar'),
          useOnlyLangCode: true,
          child: const SuwayaApp(),
        ),
      ),
    );
    
  } catch (e, stackTrace) {
    debugPrint('💥 فشل كارثي في التهيئة: $e\n$stackTrace');
    
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Text(
              'عذراً، حدث خطأ مفاجئ أثناء التشغيل.\nتم إرسال تقرير للمطورين. يرجى إعادة المحاولة.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

void _setupErrorHandlers() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true; 
  };
}

Future<void> _initBackgroundServices() async {
  try {
    // 🌟 تحميل ملف الأسرار
    await dotenv.load(fileName: ".env");

    await Future.wait([
      NotificationService().init(),
      Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!, 
        // 🌟 العودة إلى publishableKey للتوافق مع التحديث الأخير للحزمة
        publishableKey: dotenv.env['SUPABASE_ANON_KEY']!, 
      ),
    ]);

    GeoSeedService.seedCountries().catchError((error, stackTrace) {
      if (kReleaseMode) FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: 'فشل في زراعة قاعدة بيانات المدن');
      debugPrint('⚠️ خطأ صامت في زراعة الدول');
    });

  } catch (e, stackTrace) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'فشل في تحميل خدمات الخلفية');
    }
    debugPrint('⚠️ فشل في تحميل خدمات الخلفية: $e');
  }
}

class SuwayaApp extends ConsumerWidget {
  const SuwayaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final activeColorTheme = ref.watch(themeColorProvider);

    final bool isDayTime = ref.watch(astroProvider.select((state) {
      if (state.periods.isEmpty) {
        final hour = DateTime.now().hour;
        return hour >= 6 && hour < 18; 
      }
      final pId = state.currentPeriod.id;
      return pId >= 1 && pId <= 4; 
    }));

    // 🌟 إحاطة التطبيق بالـ GlobalSyncWrapper
    return GlobalSyncWrapper(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Suwaya',
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale, 
        
        themeMode: AppTheme.getThemeMode(settings.themeMode, isDayTime: isDayTime),
        theme: AppTheme.getLightTheme(activeColorTheme),
        darkTheme: AppTheme.getDarkTheme(activeColorTheme),
        
        home: const SplashScreen(),
      ),
    );
  }
}