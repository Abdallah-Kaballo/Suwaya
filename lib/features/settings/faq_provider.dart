
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FaqItem {
  final String question;
  final String answer;

  const FaqItem({required this.question, required this.answer});

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      question: (json['q'] as String?) ?? '',
      answer: (json['a'] as String?) ?? '',
    );
  }
}

List<FaqItem> _parseFaqJson(String rawJson) {
  final List<dynamic> decoded = jsonDecode(rawJson) as List<dynamic>;
  return decoded
      .map((e) => FaqItem.fromJson(e as Map<String, dynamic>))
      .where((item) => item.question.isNotEmpty && item.answer.isNotEmpty)
      .toList();
}

Future<List<FaqItem>> _loadBundledFaq(String langCode) async {
  for (final code in [langCode, 'en', 'ar']) {
    try {
      final raw = await rootBundle.loadString('docs/faq/faq_$code.json');
      final items = _parseFaqJson(raw);
      if (items.isNotEmpty) return items;
    } catch (_) {}
  }
  return const [];
}

final faqProvider =
    FutureProvider.family.autoDispose<List<FaqItem>, String>((ref, langCode) async {
  final prefs = await SharedPreferences.getInstance();
  final cacheKey = 'suwaya_faq_cache_$langCode';
  final url =
      'https://raw.githubusercontent.com/Abdallah-Kaballo/Suwaya/main/docs/faq/faq_$langCode.json';

  // 1. محاولة القراءة الفورية من الذاكرة المخبأة أو الأصول المدمجة (Offline-First)
  List<FaqItem> initialItems = const [];
  final cachedData = prefs.getString(cacheKey);
  if (cachedData != null && cachedData.isNotEmpty) {
    try {
      initialItems = _parseFaqJson(cachedData);
    } catch (_) {}
  }

  if (initialItems.isEmpty) {
    initialItems = await _loadBundledFaq(langCode);
  }

  // 2. إذا توفرت نسخة محلية أو مدمجة، نعرضها فوراً ونحدث الـ Cache في الخلفية دون حجب الشاشة
  if (initialItems.isNotEmpty) {
    unawaited(() async {
      try {
        final response =
            await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200 && response.body != cachedData) {
          final parsed = _parseFaqJson(response.body);
          if (parsed.isNotEmpty) {
            await prefs.setString(cacheKey, response.body);
          }
        }
      } catch (e) {
        debugPrint('FAQ background refresh skipped: $e');
      }
    }());
    return initialItems;
  }

  // 3. مسار احتياطي أخير عبر الشبكة فقط إذا لم توجد أصول مدمجة ولا ذاكرة مخبأة
  try {
    final response =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      await prefs.setString(cacheKey, response.body);
      return _parseFaqJson(response.body);
    }
  } catch (e) {
    debugPrint('FAQ network fallback error: $e');
  }

  return const [];
});