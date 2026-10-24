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
    defaultValue: '',
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

    final String activeApiKey = Platform.isAndroid
        ? revenueCatGoogleApiKey
        : (Platform.isIOS ? revenueCatAppleApiKey : '');

    if (activeApiKey.isNotEmpty) {
      try {
        await Purchases.configure(PurchasesConfiguration(activeApiKey));
        isRevenueCatConfigured = true;
      } catch (e) {
        debugPrint('⚠️ RevenueCat init warning: $e');
        isRevenueCatConfigured = false;
      }
    }
  }
}
