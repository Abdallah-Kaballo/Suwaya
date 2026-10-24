import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../core/bootstrap/app_bootstrap.dart';
import 'supporter_provider.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  Map<String, Package> _storePackages = {};
  bool _isLoadingOfferings = true;

  @override
  void initState() {
    super.initState();
    _fetchStoreOfferings();
  }

  Future<void> _fetchStoreOfferings() async {
    if (!AppBootstrap.isRevenueCatConfigured) {
      if (mounted) {
        setState(() => _isLoadingOfferings = false);
      }
      return;
    }

    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        final current = offerings.current!;
        final map = <String, Package>{};

        final bronzePkg = current.getPackage('bronze');
        final silverPkg = current.getPackage('silver');
        final goldPkg = current.getPackage('gold');
        final diamondPkg = current.getPackage('diamond');

        if (bronzePkg != null) map['bronze'] = bronzePkg;
        if (silverPkg != null) map['silver'] = silverPkg;
        if (goldPkg != null) map['gold'] = goldPkg;
        if (diamondPkg != null) map['diamond'] = diamondPkg;

        if (mounted) {
          setState(() {
            _storePackages = map;
            _isLoadingOfferings = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('Error loading RevenueCat offerings: $e');
    }
    if (mounted) {
      setState(() => _isLoadingOfferings = false);
    }
  }

  String _getPriceLabel(SupporterTier tier, String fallbackPrice) {
    final pkg = _storePackages[tier.packageId];
    if (pkg != null && pkg.storeProduct.priceString.isNotEmpty) {
      return '${pkg.storeProduct.priceString} / ${context.locale.languageCode == 'ar' ? 'شهرياً' : 'month'}';
    }
    return 'support.price_monthly'.tr(namedArgs: {'price': fallbackPrice});
  }

  /// 🌟 تنفيذ عملية الدفع الحقيقية عبر Google Play / RevenueCat
  Future<void> _processStorePurchase(SupporterTier tier) async {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final result =
        await ref.read(supporterProvider.notifier).purchaseTierPackage(tier);

    if (!mounted) return;
    Navigator.pop(context); // إغلاق مؤشر التحميل

    if (result.success) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('support.success_msg'.tr()),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } else if (!result.userCancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ??
                (context.locale.languageCode == 'ar'
                    ? 'تعذر إتمام عملية الدفع من المتجر حالياً.'
                    : 'Could not complete store purchase at this time.'),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleRestorePurchases() async {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('support.restoring_msg'.tr())),
    );

    final restored =
        await ref.read(supporterProvider.notifier).restorePurchases();

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored
              ? 'support.success_msg'.tr()
              : (context.locale.languageCode == 'ar'
                  ? 'لم يتم العثور على اشتراكات فعالة سابقة.'
                  : 'No active previous subscriptions found.'),
        ),
        backgroundColor: restored ? Colors.green.shade700 : Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final currentTier = ref.watch(supporterProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            context.locale.languageCode == 'ar'
                ? LucideIcons.arrow_right
                : LucideIcons.arrow_left,
            color: textColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'support.title'.tr(),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  LucideIcons.heart_handshake,
                  size: 48,
                  color: Color(0xFFFFD700),
                ),
                const SizedBox(height: 16),
                Text(
                  'support.philosophy_msg'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.8),
                    height: 1.8,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'support.badges_title'.tr(),
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isLoadingOfferings)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTierCard(
            context: context,
            title: 'support.bronze_title'.tr(),
            price: _getPriceLabel(SupporterTier.bronze, '1.00'),
            icon: LucideIcons.medal,
            color: const Color(0xFFCD7F32),
            features: [
              'support.feature_bronze'.tr(),
              'support.feature_support'.tr(),
            ],
            isCurrent: currentTier == SupporterTier.bronze,
            onTap: () => _processStorePurchase(SupporterTier.bronze),
          ),
          _buildTierCard(
            context: context,
            title: 'support.silver_title'.tr(),
            price: _getPriceLabel(SupporterTier.silver, '2.00'),
            icon: LucideIcons.award,
            color: const Color(0xFFC0C0C0),
            features: [
              'support.feature_silver'.tr(),
              'support.feature_support'.tr(),
            ],
            isCurrent: currentTier == SupporterTier.silver,
            onTap: () => _processStorePurchase(SupporterTier.silver),
          ),
          _buildTierCard(
            context: context,
            title: 'support.gold_title'.tr(),
            price: _getPriceLabel(SupporterTier.gold, '5.00'),
            icon: LucideIcons.crown,
            color: const Color(0xFFFFD700),
            features: [
              'support.feature_gold'.tr(),
              'support.feature_support'.tr(),
            ],
            isCurrent: currentTier == SupporterTier.gold,
            onTap: () => _processStorePurchase(SupporterTier.gold),
          ),
          _buildTierCard(
            context: context,
            title: 'support.diamond_title'.tr(),
            price: _getPriceLabel(SupporterTier.diamond, '10.00'),
            icon: LucideIcons.gem,
            color: const Color(0xFF00E5FF),
            features: [
              'support.feature_diamond'.tr(),
              'support.feature_support'.tr(),
            ],
            isCurrent: currentTier == SupporterTier.diamond,
            onTap: () => _processStorePurchase(SupporterTier.diamond),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _handleRestorePurchases,
            child: Text(
              'support.restore_purchases'.tr(),
              style: TextStyle(
                color: textColor.withValues(alpha: 0.6),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTierCard({
    required BuildContext context,
    required String title,
    required String price,
    required IconData icon,
    required Color color,
    required List<String> features,
    required bool isCurrent,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isCurrent
            ? color.withValues(alpha: 0.1)
            : (isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? color : (isDark ? Colors.white12 : Colors.black12),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isCurrent ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            price,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'support.active'.tr(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                ...features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.check,
                          size: 16,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
