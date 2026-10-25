import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:alarm/alarm.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../notification/notification_service.dart';

class AppBootstrap {
  static const String revenueCatGoogleApiKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_API_KEY',
    defaultValue: 'goog_JcnVefJVnUvvVCneWsmfNfOsMcL',
  );
  static const String revenueCatAppleApiKey = String.fromEnvironment(
    'REVENUECAT_APPLE_API_KEY',
    defaultValue: '',
  );

  static bool isRevenueCatConfigured = false;

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
    await ensureRevenueCatConfigured();
  }

  static Future<bool> ensureRevenueCatConfigured() async {
    if (isRevenueCatConfigured) return true;
    if (!Platform.isAndroid && !Platform.isIOS) return false;

    final String activeApiKey = Platform.isAndroid
        ? revenueCatGoogleApiKey.trim()
        : revenueCatAppleApiKey.trim();

    if (activeApiKey.isEmpty || activeApiKey.contains('xxxxxxxx')) {
      return false;
    }

    try {
      if (await Purchases.isConfigured) {
        isRevenueCatConfigured = true;
        return true;
      }
      await Purchases.configure(PurchasesConfiguration(activeApiKey));
      isRevenueCatConfigured = true;
      return true;
    } catch (e) {
      debugPrint('⚠️ RevenueCat init warning: $e');
      isRevenueCatConfigured = false;
      return false;
    }
  }
}
