import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:isar_community/isar.dart';
import 'package:alarm/alarm.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/date_symbol_data_local.dart';

import '../database/database_service.dart';
import '../location/geo_database_service.dart';
import '../notification/notification_service.dart';
import '../services/alarm_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppBootstrap {
  static Future<Isar> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    tz.initializeTimeZones();
    _setupErrorHandlers();
    
    // تحميل ملف البيئة
await dotenv.load(fileName: ".env");

// تهيئة Supabase
await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );

    await Alarm.init();
    await AlarmService.init();

    final results = await Future.wait([
      DatabaseService.init(),
      EasyLocalization.ensureInitialized(),
      initializeDateFormatting(),
    ]);

    final isarInstance = results[0] as Isar;

    await _initBackgroundServices(isarInstance);

    return isarInstance;
  }

  static void _setupErrorHandlers() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('🚨 خطأ صامت: $error');
      return true;
    };
  }

  static Future<void> _initBackgroundServices(Isar isar) async {
    try {
      await NotificationService().init();

      GeoDatabaseService.seedCountries(isar).catchError((error, stackTrace) {
        debugPrint('⚠️ خطأ صامت في زراعة الدول: $error');
      });
    } catch (e) {
      debugPrint('⚠️ فشل في تحميل خدمات الخلفية: $e');
    }
  }
}