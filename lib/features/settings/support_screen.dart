import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'supporter_provider.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  // دالة وهمية لمحاكاة عملية الدفع (سنستبدلها لاحقاً بكود RevenueCat)
  Future<void> _processMockPayment(SupporterTier tier) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    Navigator.pop(context); 
    
    ref.read(supporterProvider.notifier).setTier(tier);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('support.success_msg'.tr()), // 🌟 مفتاح الترجمة
        backgroundColor: Colors.green,
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
          icon: Icon(context.locale.languageCode == 'ar' ? LucideIcons.arrow_right : LucideIcons.arrow_left, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'support.title'.tr(), // 🌟 مفتاح الترجمة
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
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
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.heart_handshake, size: 48, color: Color(0xFFFFD700)),
                const SizedBox(height: 16),
                Text(
                  'support.philosophy_msg'.tr(), // 🌟 مفتاح الترجمة
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textColor.withValues(alpha: 0.8), height: 1.8, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          Text('support.badges_title'.tr(), style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          _buildTierCard(
            context: context,
            title: 'support.bronze_title'.tr(),
            price: 'support.price_monthly'.tr(namedArgs: {'price': '1.00'}),
            icon: LucideIcons.medal,
            color: const Color(0xFFCD7F32), 
            features: ['support.feature_bronze'.tr(), 'support.feature_support'.tr()],
            isCurrent: currentTier == SupporterTier.bronze,
            onTap: () => _processMockPayment(SupporterTier.bronze),
          ),

          _buildTierCard(
            context: context,
            title: 'support.silver_title'.tr(),
            price: 'support.price_monthly'.tr(namedArgs: {'price': '2.00'}),
            icon: LucideIcons.award,
            color: const Color(0xFFC0C0C0), 
            features: ['support.feature_silver'.tr(), 'support.feature_support'.tr()],
            isCurrent: currentTier == SupporterTier.silver,
            onTap: () => _processMockPayment(SupporterTier.silver),
          ),

          _buildTierCard(
            context: context,
            title: 'support.gold_title'.tr(),
            price: 'support.price_monthly'.tr(namedArgs: {'price': '5.00'}),
            icon: LucideIcons.crown,
            color: const Color(0xFFFFD700), 
            features: ['support.feature_gold'.tr(), 'support.feature_support'.tr()],
            isCurrent: currentTier == SupporterTier.gold,
            onTap: () => _processMockPayment(SupporterTier.gold),
          ),

          _buildTierCard(
            context: context,
            title: 'support.diamond_title'.tr(),
            price: 'support.price_monthly'.tr(namedArgs: {'price': '10.00'}),
            icon: LucideIcons.gem,
            color: const Color(0xFF00E5FF), 
            features: ['support.feature_diamond'.tr(), 'support.feature_support'.tr()],
            isCurrent: currentTier == SupporterTier.diamond,
            onTap: () => _processMockPayment(SupporterTier.diamond),
          ),

          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.info, color: Colors.blueAccent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'support.auto_renew_note'.tr(), // 🌟 مفتاح الترجمة
                    style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('support.restoring_msg'.tr())), // 🌟 مفتاح الترجمة
              );
            },
            child: Text(
              'support.restore_purchases'.tr(), // 🌟 مفتاح الترجمة
              style: TextStyle(color: textColor.withValues(alpha: 0.6), decoration: TextDecoration.underline),
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
            : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
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
                          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                          const SizedBox(height: 4),
                          Text(price, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
                        ],
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                        child: Text('support.active'.tr(), style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(LucideIcons.check, size: 16, color: isDark ? Colors.white54 : Colors.black54),
                      const SizedBox(width: 8),
                      Expanded(child: Text(f, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87))),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}