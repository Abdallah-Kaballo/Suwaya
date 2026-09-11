import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:alarm/alarm.dart';
import '../notification/notification_service.dart';

class AppBootstrap {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();

    FlutterError.onError = (errorDetails) {
      debugPrint('💥 [Flutter Error]: ${errorDetails.exceptionAsString()}');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('💥 [Unhandled Exception]: $error\n$stack');
      return false; 
    };

    // 🌟 تهيئة سريعة وخفيفة جداً فقط للخدمات الأساسية
    await NotificationService().init();
    await Alarm.init();
    
    // 🌟 قاعدة البيانات Isar سيتم تحميلها لاحقاً لعدم تجميد واجهة التطبيق
  }
}