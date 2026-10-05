import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// 🌟 نموذج بيانات السؤال والجواب
class FaqItem {
  final String question;
  final String answer;

  FaqItem({required this.question, required this.answer});

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      question: json['q'] ?? '',
      answer: json['a'] ?? '',
    );
  }
}

// 🌟 مزود يجلب البيانات من GitHub مع دعم الـ Cache المحلي
final faqProvider = FutureProvider.family.autoDispose<List<FaqItem>, String>((ref, langCode) async {
  final prefs = await SharedPreferences.getInstance();
  final cacheKey = 'suwaya_faq_cache_$langCode';
  
  // تأكد من أن 'main' هو اسم الفرع الافتراضي في مستودعك، إذا كان 'master' قم بتغييره هنا
  final url = 'https://raw.githubusercontent.com/Abdallah-Kaballo/Suwaya/main/docs/faq/faq_$langCode.json';

  try {
    // محاولة جلب البيانات من الإنترنت بمهلة زمنية (Timeout) لعدم تجميد التطبيق
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
    
    if (response.statusCode == 200) {
      // حفظ النسخة الجديدة في التخزين المحلي
      await prefs.setString(cacheKey, response.body);
      
      final List<dynamic> decodedData = jsonDecode(response.body);
      return decodedData.map((e) => FaqItem.fromJson(e)).toList();
    }
  } catch (e) {
    debugPrint('فشل جلب FAQ من الإنترنت، جاري محاولة فتح النسخة المخبأة: $e');
  }

  // في حال انقطاع الإنترنت أو الفشل، نقرأ من الـ Cache
  final cachedData = prefs.getString(cacheKey);
  if (cachedData != null) {
    final List<dynamic> decodedData = jsonDecode(cachedData);
    return decodedData.map((e) => FaqItem.fromJson(e)).toList();
  }

  // إذا لم يكن هناك إنترنت ولم يسبق التخزين، نرجع قائمة فارغة
  return [];
});