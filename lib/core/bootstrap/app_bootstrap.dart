import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:alarm/alarm.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../notification/notification_service.dart';

class AppBootstrap {
  static const String revenueCatGoogleApiKey =
      'goog_JcnVefJVnUvvVCneWsmfNfOsMcL';

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

    await NotificationService().init();
    await Alarm.init();

    // 🌟 تهيئة RevenueCat لمتجر Google Play
    if (Platform.isAndroid) {
      try {
        await Purchases.configure(
          PurchasesConfiguration(revenueCatGoogleApiKey),
        );
      } catch (e) {
        debugPrint('⚠️ RevenueCat init warning: $e');
      }
    }
  }
}