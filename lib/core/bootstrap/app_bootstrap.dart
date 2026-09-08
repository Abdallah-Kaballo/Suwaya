import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:isar_community/isar.dart';
import '../database/database_service.dart';

class AppBootstrap {
  static Future<Isar> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('💥 [خطأ حرج غير معالج]: $error\n$stack');
      return true; 
    };

    // 🌟 جلب كائن isar من قاعدة البيانات
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
        debugPrint('⚠️ [فشل سحابي]: تعذر الاتصال بـ Supabase، سيستمر التطبيق محلياً. السبب: $e');
      }
    }
    
    // 🌟 إرجاع الكائن لكي يستلمه ملف main.dart
    return isar;
  }
}