import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// أنواع الشارات المتاحة
enum SupporterTier { none, bronze, silver, gold, diamond }

class SupporterNotifier extends StateNotifier<SupporterTier> {
  SupporterNotifier() : super(SupporterTier.none) {
    _loadTier();
  }

  Future<void> _loadTier() async {
    final prefs = await SharedPreferences.getInstance();
    final tierString = prefs.getString('supporter_tier') ?? 'none';
    state = SupporterTier.values.firstWhere(
      (e) => e.toString().split('.').last == tierString,
      orElse: () => SupporterTier.none,
    );
  }

  // هذه الدالة سنستدعيها عند نجاح الدفع
  Future<void> setTier(SupporterTier tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('supporter_tier', tier.toString().split('.').last);
    state = tier;
  }
}

final supporterProvider = StateNotifierProvider<SupporterNotifier, SupporterTier>((ref) {
  return SupporterNotifier();
});