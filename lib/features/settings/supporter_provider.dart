import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SupporterTier { none, bronze, silver, gold, diamond }

extension SupporterTierId on SupporterTier {
  String get packageId {
    switch (this) {
      case SupporterTier.bronze:
        return 'bronze';
      case SupporterTier.silver:
        return 'silver';
      case SupporterTier.gold:
        return 'gold';
      case SupporterTier.diamond:
        return 'diamond';
      case SupporterTier.none:
        return 'none';
    }
  }
}

class SupporterNotifier extends StateNotifier<SupporterTier> {
  SupporterNotifier() : super(SupporterTier.none) {
    _loadAndSyncTier();
  }

  Future<void> _loadAndSyncTier() async {
    final prefs = await SharedPreferences.getInstance();
    final tierString = prefs.getString('supporter_tier') ?? 'none';
    state = SupporterTier.values.firstWhere(
      (e) => e.name == tierString,
      orElse: () => SupporterTier.none,
    );

    if (Platform.isAndroid) {
      await syncWithStore();
    }
  }

  /// 🌟 مزامنة الشارة مع المشتريات الفعلية النشطة في حساب المستخدم على Google Play
  Future<SupporterTier> syncWithStore() async {
    if (!Platform.isAndroid) return state;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final detected = _extractTierFromCustomerInfo(customerInfo);
      await _persistTier(detected);
      return detected;
    } catch (e) {
      debugPrint('RevenueCat sync error: $e');
      return state;
    }
  }

  SupporterTier _extractTierFromCustomerInfo(CustomerInfo info) {
    final allActiveIds = <String>{
      ...info.entitlements.active.keys.map((e) => e.toLowerCase()),
      ...info.entitlements.active.values
          .map((e) => e.productIdentifier.toLowerCase()),
      ...info.activeSubscriptions.map((s) => s.toLowerCase()),
    };

    if (allActiveIds.any((id) => id.contains('diamond'))) {
      return SupporterTier.diamond;
    }
    if (allActiveIds.any((id) => id.contains('gold'))) {
      return SupporterTier.gold;
    }
    if (allActiveIds.any((id) => id.contains('silver'))) {
      return SupporterTier.silver;
    }
    if (allActiveIds.any((id) => id.contains('bronze'))) {
      return SupporterTier.bronze;
    }
    return SupporterTier.none;
  }

  Future<void> _persistTier(SupporterTier tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('supporter_tier', tier.name);
    state = tier;
  }

  /// 🌟 شراء حزمة فعلية من متجر Google Play (لا يمنح الشارة إلا إذا نجحت عملية الدفع فعلياً)
  Future<({bool success, bool userCancelled, String? errorMessage})>
      purchaseTierPackage(SupporterTier targetTier) async {
    if (!Platform.isAndroid) {
      return (
        success: false,
        userCancelled: false,
        errorMessage: 'In-app purchases are only supported on Android/iOS.',
      );
    }

    try {
      final offerings = await Purchases.getOfferings();
      final currentOffering = offerings.current;
      if (currentOffering == null) {
        return (
          success: false,
          userCancelled: false,
          errorMessage: 'No active store offerings found.',
        );
      }

      // الوصول للحزم الأربع: bronze, silver, gold, diamond
      final package = currentOffering.getPackage(targetTier.packageId);
      if (package == null) {
        return (
          success: false,
          userCancelled: false,
          errorMessage: 'Package "${targetTier.packageId}" is not available.',
        );
      }

      // فتح نافذة الدفع الحقيقية لمتجر Google Play
      await Purchases.purchase(PurchaseParams.package(package));

      // التحقق من حالة العميل بعد إتمام العملية
      final customerInfo = await Purchases.getCustomerInfo();
      final verifiedTier = _extractTierFromCustomerInfo(customerInfo);

      // إذا تمت عملية الشراء بنجاح بدون استثناء، نحفظ الشارة المشتراة
      final finalTier =
          verifiedTier != SupporterTier.none ? verifiedTier : targetTier;
      await _persistTier(finalTier);

      return (success: true, userCancelled: false, errorMessage: null);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return (success: false, userCancelled: true, errorMessage: null);
      }
      return (
        success: false,
        userCancelled: false,
        errorMessage: e.message ?? 'Purchase failed.',
      );
    } catch (e) {
      return (
        success: false,
        userCancelled: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 🌟 استعادة المشتريات الفعلية من المتجر
  Future<bool> restorePurchases() async {
    if (!Platform.isAndroid) return false;
    try {
      final customerInfo = await Purchases.restorePurchases();
      final restoredTier = _extractTierFromCustomerInfo(customerInfo);
      await _persistTier(restoredTier);
      return restoredTier != SupporterTier.none;
    } catch (e) {
      debugPrint('Restore purchases error: $e');
      return false;
    }
  }
}

final supporterProvider =
    StateNotifierProvider<SupporterNotifier, SupporterTier>((ref) {
  return SupporterNotifier();
});