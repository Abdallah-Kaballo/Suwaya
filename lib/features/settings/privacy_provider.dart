import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// نموذج يمثل قسم واحد من سياسة الخصوصية
class PrivacySection {
  final String title;
  final String content;

  PrivacySection({required this.title, required this.content});

  factory PrivacySection.fromJson(Map<String, dynamic> json) {
    return PrivacySection(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
    );
  }
}

// مزود جلب سياسة الخصوصية
final privacyProvider = FutureProvider.family.autoDispose<List<PrivacySection>, String>((ref, langCode) async {
  final prefs = await SharedPreferences.getInstance();
  final cacheKey = 'suwaya_privacy_cache_$langCode';
  
  // 🌟 الرابط المباشر لملف الخصوصية على GitHub
  final url = 'https://raw.githubusercontent.com/Abdallah-Kaballo/Suwaya/main/docs/privacy/privacy_$langCode.json';

  try {
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      await prefs.setString(cacheKey, response.body);
      final List<dynamic> decodedData = jsonDecode(response.body);
      return decodedData.map((e) => PrivacySection.fromJson(e)).toList();
    }
  } catch (e) {
    debugPrint('فشل جلب Privacy Policy، جاري محاولة فتح النسخة المخبأة: $e');
  }

  // قراءة النسخة المخبأة في حال عدم وجود إنترنت
  final cachedData = prefs.getString(cacheKey);
  if (cachedData != null) {
    final List<dynamic> decodedData = jsonDecode(cachedData);
    return decodedData.map((e) => PrivacySection.fromJson(e)).toList();
  }

  return [];
});