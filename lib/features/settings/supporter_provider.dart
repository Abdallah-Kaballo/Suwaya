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

  /// المعرفات المحتملة للمنتج في Google Play Console و RevenueCat
  List<String> get candidateProductIds {
    final id = packageId;
    return [
      id,
      '${id}_monthly',
      'suwaya_$id',
      'suwaya_${id}_monthly',
      'supporter_$id',
    ];
  }
}

class SupporterNotifier extends StateNotifier<SupporterTier> {
  bool _listenerRegistered = false;

  SupporterNotifier() : super(SupporterTier.none) {
    _loadAndSyncTier();
  }

  bool get isStoreSupported =>
      (Platform.isAndroid || Platform.isIOS) &&
      AppBootstrap.isRevenueCatConfigured;

  Future<void> _loadAndSyncTier() async {
    final prefs = await SharedPreferences.getInstance();
    final tierString = prefs.getString('supporter_tier') ?? 'none';
    state = SupporterTier.values.firstWhere(
      (e) => e.name == tierString,
      orElse: () => SupporterTier.none,
    );

    final configured = await AppBootstrap.ensureRevenueCatConfigured();
    if (configured) {
      _registerCustomerListenerIfNeeded();
      await syncWithStore();
    }
  }

  void _registerCustomerListenerIfNeeded() {
    if (_listenerRegistered) return;
    _listenerRegistered = true;
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      final updatedTier = _extractTierFromCustomerInfo(customerInfo);
      _persistTier(updatedTier);
    });
  }

  /// جلب الحزم المتاحة من المتجر وربط كل وسام بحزمته الفعلية
  Future<Map<SupporterTier, Package>> fetchAvailableTierPackages() async {
    final configured = await AppBootstrap.ensureRevenueCatConfigured();
    if (!configured) return {};
    _registerCustomerListenerIfNeeded();

    final offerings = await Purchases.getOfferings();
    final allPackages = <Package>[
      if (offerings.current != null) ...offerings.current!.availablePackages,
      for (final off in offerings.all.values) ...off.availablePackages,
    ];

    final resolved = <SupporterTier, Package>{};
    for (final tier in [
      SupporterTier.bronze,
      SupporterTier.silver,
      SupporterTier.gold,
      SupporterTier.diamond,
    ]) {
      final key = tier.packageId.toLowerCase();
      Package? match = offerings.current?.getPackage(tier.packageId);

      match ??= allPackages.where((pkg) {
        final pkgId = pkg.identifier.toLowerCase();
        final prodId = pkg.storeProduct.identifier.toLowerCase();
        return pkgId == key ||
            pkgId.contains(key) ||
            prodId == key ||
            prodId.contains(key);
      }).firstOrNull;

      if (match != null) {
        resolved[tier] = match;
      }
    }
    return resolved;
  }

  /// مزامنة الشارة مع المشتريات الفعلية في المتجر (بما في ذلك انتهاء الاشتراك أو الاسترداد)
  Future<SupporterTier> syncWithStore() async {
    final configured = await AppBootstrap.ensureRevenueCatConfigured();
    if (!configured) return state;
    try {
      await Purchases.invalidateCustomerInfoCache();
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
    if (mounted) {
      state = tier;
    }
  }

  Future<({bool success, bool userCancelled, String? errorMessage})>
      purchaseTierPackage(
    SupporterTier targetTier, {
    Package? preloadedPackage,
  }) async {
    final configured = await AppBootstrap.ensureRevenueCatConfigured();
    if (!configured) {
      return (
        success: false,
        userCancelled: false,
        errorMessage: 'Store billing is not initialized on this device.',
      );
    }
    _registerCustomerListenerIfNeeded();

    try {
      Package? packageToBuy = preloadedPackage;
      if (packageToBuy == null) {
        final packagesMap = await fetchAvailableTierPackages();
        packageToBuy = packagesMap[targetTier];
      }

      late final PurchaseResult purchaseResult;
      if (packageToBuy != null) {
        purchaseResult = await Purchases.purchase(
          PurchaseParams.package(packageToBuy),
        );
      } else {
        // مسار مباشر عبر معرّف المنتج في Google Play في حال لم يُربط داخل Offering بعد
        final products = await Purchases.getProducts(
          targetTier.candidateProductIds,
        );
        if (products.isEmpty) {
          return (
            success: false,
            userCancelled: false,
            errorMessage:
                'Product (${targetTier.packageId}) is not active in Google Play Console / RevenueCat yet.',
          );
        }
        purchaseResult = await Purchases.purchase(
          PurchaseParams.storeProduct(products.first),
        );
      }

      final verifiedTier =
          _extractTierFromCustomerInfo(purchaseResult.customerInfo);
      final effectiveTier =
          verifiedTier != SupporterTier.none ? verifiedTier : targetTier;

      await _persistTier(effectiveTier);
      return (success: true, userCancelled: false, errorMessage: null);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return (success: false, userCancelled: true, errorMessage: null);
      }
      if (errorCode == PurchasesErrorCode.productAlreadyPurchasedError) {
        // إذا كان المستخدم يمتلك هذا الاشتراك فعلاً على حسابه في Google Play، نقوم باستعادته وتفعيله فوراً
        final synced = await syncWithStore();
        if (synced != SupporterTier.none) {
          return (success: true, userCancelled: false, errorMessage: null);
        }
      }
      return (
        success: false,
        userCancelled: false,
        errorMessage: e.message,
      );
    } catch (e) {
      debugPrint('Purchase error: $e');
      return (
        success: false,
        userCancelled: false,
        errorMessage: null,
      );
    }
  }

  Future<bool> restorePurchases() async {
    final configured = await AppBootstrap.ensureRevenueCatConfigured();
    if (!configured) return false;
    _registerCustomerListenerIfNeeded();
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
