import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;

// نموذج يمثل قسم واحد من سياسة الخصوصية
class PrivacySection {
  final String title;
  final String content;

  PrivacySection({required this.title, required this.content});

  factory PrivacySection.fromJson(Map<String, dynamic> json) {
    return PrivacySection(
      title: (json['title'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
    );
  }
}

List<PrivacySection> _parsePrivacyJson(String rawJson) {
  final List<dynamic> decoded = jsonDecode(rawJson) as List<dynamic>;
  return decoded
      .map((e) => PrivacySection.fromJson(e as Map<String, dynamic>))
      .where((s) => s.title.isNotEmpty && s.content.isNotEmpty)
      .toList();
}

final privacyProvider = FutureProvider.family
    .autoDispose<List<PrivacySection>, String>((ref, langCode) async {
  final targetLang = (langCode == 'ar') ? 'ar' : 'en';
  final prefs = await SharedPreferences.getInstance();
  final cacheKey = 'suwaya_privacy_cache_$targetLang';
  final url =
      'https://raw.githubusercontent.com/Abdallah-Kaballo/Suwaya/main/docs/privacy/privacy_$targetLang.json';

  List<PrivacySection> localSections = const [];

  final cachedData = prefs.getString(cacheKey);
  if (cachedData != null && cachedData.isNotEmpty) {
    try {
      localSections = _parsePrivacyJson(cachedData);
    } catch (_) {}
  }

  if (localSections.isEmpty) {
    try {
      final bundled =
          await rootBundle.loadString('docs/privacy/privacy_$targetLang.json');
      localSections = _parsePrivacyJson(bundled);
    } catch (_) {}
  }

  if (localSections.isEmpty) {
    localSections = _defaultPrivacySections(targetLang);
  }

  // تحديث صامت في الخلفية دون تعطيل عرض الصفحة للمستخدم
  unawaited(() async {
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200 && response.body != cachedData) {
        final parsed = _parsePrivacyJson(response.body);
        if (parsed.isNotEmpty) {
          await prefs.setString(cacheKey, response.body);
        }
      }
    } catch (e) {
      debugPrint('Privacy background refresh skipped: $e');
    }
  }());

  return localSections;
});

List<PrivacySection> _defaultPrivacySections(String lang) {
  if (lang == 'ar') {
    return [
      PrivacySection(
        title: '1. التخزين المحلي والخصوصية أولاً',
        content:
            'تُحفظ جميع مهامك، عاداتك، روتينك، وإعداداتك محلياً على جهازك فقط داخل قاعدة بيانات محلية (Isar)، ولا يمتلك تطبيق سُويعة خوادم سحابية لجمع أو مزامنة أنشطتك اليومية.',
      ),
      PrivacySection(
        title: '2. بيانات الموقع الجغرافي',
        content:
            'يُستخدم موقعك الجغرافي حصرياً داخل الجهاز لحساب مواقيت الصلاة والدورات الفلكية وتحديد أقرب مدينة عبر قاعدة البيانات المدمجة دون إرسال إحداثياتك إلى أي خادم خارجي.',
      ),
      PrivacySection(
        title: '3. المشتريات داخل التطبيق (Google Play و RevenueCat)',
        content:
            'عند اختيارك دعم التطبيق أو استعادة حالة الداعم، يستخدم التطبيق خدمات فوترة Google Play وحزمة RevenueCat لإدارة حالة الاستحقاق (Supporter Badges). يعالج هذا التكامل معرّف مستخدم مجهول (Anonymous App User ID) وحالة الاشتراك للتحقق من شارتك، بينما تتم معالجة بيانات الدفع الحساسة بالكامل عبر متجر Google Play ولا يطّلع عليها التطبيق.',
      ),
      PrivacySection(
        title: '4. الصلاحيات والاتصال بالشبكة',
        content:
            'تُستخدم صلاحيات المنبهات الدقيقة والإشعارات لتشغيل تنبيهات الصلوات والمهام في أوقاتها، ويُقتصر استخدام الإنترنت على تحديث صفحات الأسئلة الشائعة وسياسة الخصوصية أو التحقق من المشتريات وتحديثات المتجر.',
      ),
    ];
  }

  return [
    PrivacySection(
      title: '1. Local-First Storage & Privacy',
      content:
          'All your tasks, habits, routines, and settings are stored strictly locally on your device using an on-device database (Isar). Suwaya does not operate cloud servers to collect or sync your personal schedule.',
    ),
    PrivacySection(
      title: '2. Location Data',
      content:
          'Your location coordinates are processed strictly on-device to calculate prayer timings, astronomical periods, and nearest city data via the bundled offline database. Coordinates are never transmitted to external servers.',
    ),
    PrivacySection(
      title: '3. In-App Purchases (Google Play Billing & RevenueCat)',
      content:
          'If you choose to purchase or restore a supporter tier, the app uses Google Play Billing and the RevenueCat SDK to verify and sync your supporter entitlement. RevenueCat processes an anonymous customer identifier and purchase status receipt. Sensitive payment details are handled exclusively by Google Play and are never accessible to Suwaya.',
    ),
    PrivacySection(
      title: '4. Permissions & Network Access',
      content:
          'Notification and exact alarm permissions are used solely to trigger your scheduled prayer, Qiyam, task, and routine alerts. Internet access is limited to fetching documentation updates (FAQ/Privacy), checking for app updates, and processing store purchases.',
    ),
  ];
}
