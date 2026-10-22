import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/bootstrap/app_bootstrap.dart';

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

  bool get _isStoreSupported =>
      (Platform.isAndroid || Platform.isIOS) &&
      AppBootstrap.isRevenueCatConfigured;

  Future<void> _loadAndSyncTier() async {
    final prefs = await SharedPreferences.getInstance();
    final tierString = prefs.getString('supporter_tier') ?? 'none';
    state = SupporterTier.values.firstWhere(
      (e) => e.name == tierString,
      orElse: () => SupporterTier.none,
    );

    if (_isStoreSupported) {
      await syncWithStore();
    }
  }

  /// مزامنة الشارة مع المشتريات الفعلية في المتجر (دعم الاشتراكات والمشتريات غير المتجددة)
  Future<SupporterTier> syncWithStore() async {
    if (!_isStoreSupported) return state;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final detected = _extractTierFromCustomerInfo(customerInfo);
      // لا نستبدل الشارة المحفوظة محلياً بـ none إذا كانت المعاملة استهلاكية سبق توثيقها
      if (detected != SupporterTier.none) {
        await _persistTier(detected);
        return detected;
      }
      return state;
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
      ...info.nonSubscriptionTransactions
          .map((t) => t.productIdentifier.toLowerCase()),
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

  Future<({bool success, bool userCancelled, String? errorMessage})>
      purchaseTierPackage(SupporterTier targetTier) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return (
        success: false,
        userCancelled: false,
        errorMessage: 'In-app purchases are only supported on Android and iOS.',
      );
    }

    if (!AppBootstrap.isRevenueCatConfigured) {
      return (
        success: false,
        userCancelled: false,
        errorMessage:
            'Store billing is not configured for this build (--dart-define API key missing).',
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

      final package = currentOffering.getPackage(targetTier.packageId);
      if (package == null) {
        return (
          success: false,
          userCancelled: false,
          errorMessage: 'Package "${targetTier.packageId}" is not available.',
        );
      }

      await Purchases.purchase(PurchaseParams.package(package));

      final customerInfo = await Purchases.getCustomerInfo();
      final verifiedTier = _extractTierFromCustomerInfo(customerInfo);

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

  Future<bool> restorePurchases() async {
    if (!_isStoreSupported) return false;
    try {
      final customerInfo = await Purchases.restorePurchases();
      final restoredTier = _extractTierFromCustomerInfo(customerInfo);
      if (restoredTier != SupporterTier.none) {
        await _persistTier(restoredTier);
        return true;
      }
      return false;
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