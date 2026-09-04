import '../database/local_db_service.dart';
import '../models/geo_models.dart';

class GeoSeedService {
  
  /// زرع الدول الأساسية في العالم عند أول تشغيل للتطبيق
  static Future<void> seedCountries() async {
    final isar = LocalDbService.isar;
    
    // 🟢 الطريقة الآمنة 100% للوصول للجدول بدون الاعتماد على تخمين الأسماء
    final countries = isar.collection<GeoCountry>();
    
    final count = await countries.count();
    
    if (count > 0) return; // تم الزرع مسبقاً، لا تفعل شيئاً

    // بيانات الدول الافتراضية
    final List<Map<String, dynamic>> countriesData = [
      {'code': 'EG', 'ar': 'مصر', 'en': 'Egypt', 'method': 'egyptian', 'madhab': 'shafi'},
      {'code': 'SA', 'ar': 'المملكة العربية السعودية', 'en': 'Saudi Arabia', 'method': 'umm_al_qura', 'madhab': 'shafi'},
      {'code': 'AE', 'ar': 'الإمارات العربية المتحدة', 'en': 'United Arab Emirates', 'method': 'dubai', 'madhab': 'shafi'},
      {'code': 'QA', 'ar': 'قطر', 'en': 'Qatar', 'method': 'qatar', 'madhab': 'shafi'},
      {'code': 'KW', 'ar': 'الكويت', 'en': 'Kuwait', 'method': 'kuwait', 'madhab': 'shafi'},
      {'code': 'TR', 'ar': 'تركيا', 'en': 'Turkey', 'method': 'turkey', 'madhab': 'hanafi'},
      {'code': 'PK', 'ar': 'باكستان', 'en': 'Pakistan', 'method': 'karachi', 'madhab': 'hanafi'},
      {'code': 'US', 'ar': 'الولايات المتحدة', 'en': 'United States', 'method': 'north_america', 'madhab': 'shafi'},
      {'code': 'UK', 'ar': 'المملكة المتحدة', 'en': 'United Kingdom', 'method': 'muslim_world_league', 'madhab': 'shafi'},
    ];

    // عملية زرع سريعة جداً في قاعدة البيانات
    await isar.writeTxn(() async {
      for (var data in countriesData) {
        final country = GeoCountry()
          ..code = data['code']
          ..nameAr = data['ar']
          ..nameEn = data['en']
          ..defaultMethod = data['method']
          ..defaultMadhab = data['madhab']
          ..isDownloaded = false;
        await countries.put(country);
      }
    });
  }
}