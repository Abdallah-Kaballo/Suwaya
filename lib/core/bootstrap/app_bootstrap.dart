import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:isar_community/isar.dart';
import 'package:alarm/alarm.dart';
import '../database/database_service.dart';
import '../notification/notification_service.dart';

class AppBootstrap {
  static Future<Isar> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();

    // 🌟 1. التقاط الأخطاء داخل إطار عمل Flutter (أخطاء الواجهة والودجات)
    FlutterError.onError = (errorDetails) {
      debugPrint('💥 [Flutter Error]: ${errorDetails.exceptionAsString()}');
      // FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // 🌟 2. التقاط الأخطاء غير المعالجة خارج Flutter (أخطاء Isar أو Native)
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('💥 [Unhandled Exception]: $error\n$stack');
      // FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return false; 
    };

    await NotificationService().init();
    await Alarm.init();

    final isar = await DatabaseService.init();
    debugPrint('✅ تم تهيئة التطبيق للعمل محلياً بنجاح (Offline Mode)');
    
    return isar;
  }
}