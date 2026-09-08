import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:isar_community/isar.dart';
import 'package:alarm/alarm.dart';
import '../database/database_service.dart';
import '../notification/notification_service.dart';

// 🌟 TODO: عندما تقوم بتثبيت حزمة firebase_crashlytics مستقبلاً، قم بإلغاء التعليق عن هذه الأسطر
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';

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
      
      // 🌟 إرجاع false يسمح للنظام بمعرفة أن هناك انهياراً (Crash) بدلاً من تجميد التطبيق صمتاً
      return false; 
    };

    await NotificationService().init();
    await Alarm.init();

    final isar = await DatabaseService.init();

    bool isEnvLoaded = false;
    try {
      await dotenv.load(fileName: ".env");
      isEnvLoaded = true;
      debugPrint('✅ تم تحميل ملف .env بنجاح');
    } catch (e) {
      debugPrint('⚠️ [وضع الأوفلاين]: لم يتم العثور على ملف .env. سيعمل التطبيق محلياً فقط.');
    }

    if (isEnvLoaded) {
      try {
        final supabaseUrl = dotenv.env['SUPABASE_URL'];
        final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
        
        if (supabaseUrl != null && supabaseAnonKey != null && supabaseUrl.isNotEmpty) {
          await Supabase.initialize(
            url: supabaseUrl,
            publishableKey: supabaseAnonKey,
          );
          debugPrint('✅ تم الاتصال بخوادم Supabase بنجاح');
        } else {
          debugPrint('⚠️ [المزامنة معطلة]: مفاتيح Supabase غير مكتملة في ملف .env');
        }
      } catch (e) {
        // 🌟 تمرير أخطاء السحابة لخدمة التتبع وعدم إيقاف التطبيق بالكامل
        debugPrint('⚠️ [فشل سحابي]: تعذر الاتصال بـ Supabase، سيستمر التطبيق محلياً. السبب: $e');
        // FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Supabase Initialization Failed');
      }
    }
    
    return isar;
  }
}