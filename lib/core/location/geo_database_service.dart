import 'dart:io';
import 'dart:math' show cos, asin, sqrt;
import 'package:flutter/services.dart';
import 'package:isar_community/isar.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/geo_models.dart';

class GeoDatabaseService {
  static Database? _database;

  // ==========================================
  // 1. SQLite: إدارة قاعدة بيانات المدن
  // ==========================================
  static Future<void> loadDatabase() async {
    if (_database != null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = join(dir.path, "cities.db");

      if (!File(path).existsSync()) {
        final data = await rootBundle.load("assets/db/cities.db");
        final bytes = data.buffer.asUint8List();
        await File(path).writeAsBytes(bytes, flush: true);
      }

      _database = await openDatabase(path, readOnly: true);
    } catch (e) {
      throw Exception("فشل في تحميل قاعدة بيانات المدن: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> searchCitiesInCountry(String query, String countryCode) async {
    await loadDatabase();
    if (query.trim().isEmpty || countryCode.isEmpty) return [];

    final q = query.toLowerCase().trim();
    return await _database!.rawQuery('''
      SELECT name_ar as name, name_en as nameEn,
             country_code as countryCode, lat, lng, timezone
      FROM cities
      WHERE country_code = ? AND (name_ar LIKE ? OR name_en LIKE ?)
      LIMIT 30
    ''', [countryCode.toUpperCase(), '$q%', '$q%']);
  }

  static Future<List<Map<String, dynamic>>> searchAllCities(String query) async {
    await loadDatabase();
    if (query.trim().isEmpty) return [];

    final q = query.toLowerCase().trim();
    return await _database!.rawQuery('''
      SELECT name_ar as name, name_en as nameEn,
             country_code as countryCode, lat, lng, timezone
      FROM cities
      WHERE name_ar LIKE ? OR name_en LIKE ?
      LIMIT 30
    ''', ['%$q%', '%$q%']);
  }

  static Future<List<Map<String, String>>> getCountries(String langCode) async {
    await loadDatabase();
    final result = await _database!.rawQuery('SELECT DISTINCT country_code as code FROM cities ORDER BY country_code');

    final list = result.map((row) {
      final code = row['code'] as String;
      return {'code': code, 'name': getLocalizedCountryName(code, langCode)};
    }).toList();

    list.sort((a, b) => a['name']!.compareTo(b['name']!));
    return list;
  }
  
  static Future<List<Map<String, dynamic>>> getCitiesByCountry(String countryCode) async {
    await loadDatabase();
    final results = await _database!.rawQuery('''
      SELECT name_ar as name, name_en as nameEn, country_code as countryCode, lat, lng, timezone
      FROM cities WHERE country_code = ?
    ''', [countryCode.toUpperCase()]);

    return results.map((row) {
      final mutableRow = Map<String, dynamic>.from(row);
      String? arName = mutableRow['name'] as String?;
      String? enName = mutableRow['nameEn'] as String?;
      
      if (arName != null) {
        arName = arName.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), ''); 
        arName = arName.replaceAll(RegExp(r'^ا{2,}ل'), 'ال'); 
        arName = arName.replaceAll(RegExp(r'^(محافظة|مدينة|ولاية|مقاطعة|بلدية)\s+'), ''); 
        arName = arName.replaceAll(RegExp(r'(?<=[\u0600-\u06FF])-(?=[\u0600-\u06FF])'), ' '); 
        arName = arName.replaceAll(RegExp(r'\s*\(.*?\)\s*'), ''); 
        mutableRow['name'] = arName.trim().replaceAll(RegExp(r'\s+'), ' '); 
      }

      if (enName != null) {
        enName = enName.replaceAll(RegExp(r'\s+(Governorate|City|Municipality|Province)$', caseSensitive: false), '');
        enName = enName.replaceAll(RegExp(r'\s*\(.*?\)\s*'), '');
        mutableRow['nameEn'] = enName.trim().replaceAll(RegExp(r'\s+'), ' ');
      }
      return mutableRow;
    }).toList();
  }

  // ==========================================
  // 2. Isar: زراعة الدول الافتراضية
  // ==========================================
  static Future<void> seedCountries(Isar isar) async {
    final countries = isar.collection<GeoCountry>();
    if (await countries.count() > 0) return;

    final List<Map<String, dynamic>> defaultCountries = [
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

    await isar.writeTxn(() async {
      for (var data in defaultCountries) {
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

  // ==========================================
  // 3. Utils: الهندسة العكسية (Reverse Geocoding)
  // ==========================================
  static Future<Map<String, dynamic>?> getNearestLocationData(double lat, double lng, String langCode) async {
    await loadDatabase();
    
    double limit = 2.0; 
    final results = await _database!.rawQuery('''
      SELECT name_ar, name_en, country_code, lat, lng
      FROM cities
      WHERE lat BETWEEN ? AND ? AND lng BETWEEN ? AND ?
    ''', [lat - limit, lat + limit, lng - limit, lng + limit]);

    if (results.isEmpty) return null;

    Map<String, dynamic>? closest;
    double minDistance = double.infinity;

    for (var row in results) {
      double cityLat = (row['lat'] as num).toDouble();
      double cityLng = (row['lng'] as num).toDouble();

      double distance = calculateDistance(lat, lng, cityLat, cityLng);
      if (distance < minDistance) {
        minDistance = distance;
        closest = Map<String, dynamic>.from(row);
      }
    }

    if (closest != null) {
      String cityName = langCode == 'ar' ? (closest['name_ar'] ?? closest['name_en']) : (closest['name_en'] ?? closest['name_ar']);
      return {
        'cityName': cityName,
        'countryCode': closest['country_code'],
      };
    }
    return null;
  }

  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 + cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  static String getFlagEmoji(String countryCode) {
    if (countryCode.isEmpty || countryCode.length > 2) return '📍';
    return countryCode.toUpperCase().split('').map((c) => String.fromCharCode(c.codeUnitAt(0) + 127397)).join();
  }

  static String getLocalizedCountryName(String code, String lang) {
    if (lang == 'ar') return _countriesAr[code] ?? code;
    return _countriesEn[code] ?? code;
  }

  // تم الاحتفاظ بقوائم الدول لدعم getLocalizedCountryName
  static const Map<String, String> _countriesAr = {
    'AF': 'أفغانستان', 'AX': 'جزر أولاند', 'AL': 'ألبانيا', 'DZ': 'الجزائر', 'AS': 'ساموا الأمريكية', 'AD': 'أندورا', 'AO': 'أنغولا', 'AI': 'أنغويلا', 'AQ': 'أنتاركتيكا', 'AG': 'أنتيغوا وباربودا',
    'AR': 'الأرجنتين', 'AM': 'أرمينيا', 'AW': 'أروبا', 'AU': 'أستراليا', 'AT': 'النمسا', 'AZ': 'أذربيجان', 'BS': 'جزر البهاما', 'BH': 'البحرين', 'BD': 'بنغلاديش', 'BB': 'باربادوس',
    'BY': 'بيلاروسيا', 'BE': 'بلجيكا', 'BZ': 'بليز', 'BJ': 'بنين', 'BM': 'برمودا', 'BT': 'بوتان', 'BO': 'بوليفيا', 'BA': 'البوسنة والهرسك', 'BW': 'بوتسوانا', 'BV': 'جزيرة بوفيه',
    'BR': 'البرازيل', 'IO': 'إقليم المحيط الهندي البريطاني', 'BN': 'بروناي', 'BG': 'بلغاريا', 'BF': 'بوركينا فاسو', 'BI': 'بوروندي', 'KH': 'كمبوديا', 'CM': 'الكاميرون', 'CA': 'كندا', 'CV': 'الرأس الأخضر',
    'KY': 'جزر كايمان', 'CF': 'جمهورية أفريقيا الوسطى', 'TD': 'تشاد', 'CL': 'تشيلي', 'CN': 'الصين', 'CX': 'جزيرة عيد الميلاد', 'CC': 'جزر كوكوس', 'CO': 'كولومبيا', 'KM': 'جزر القمر', 'CG': 'الكونغو',
    'CD': 'جمهورية الكونغو الديمقراطية', 'CK': 'جزر كوك', 'CR': 'كوستاريكا', 'CI': 'كوت ديفوار', 'HR': 'كرواتيا', 'CU': 'كوبا', 'CY': 'قبرص', 'CZ': 'جمهورية التشيك', 'DK': 'الدنمارك', 'DJ': 'جيبوتي',
    'DM': 'دومينيكا', 'DO': 'جمهورية الدومينيكان', 'EC': 'الإكوادور', 'EG': 'مصر', 'SV': 'السلفادور', 'GQ': 'غينيا الاستوائية', 'ER': 'إريتريا', 'EE': 'إستونيا', 'ET': 'إثيوبيا', 'FK': 'جزر فوكلاند',
    'FO': 'جزر فارو', 'FJ': 'فيجي', 'FI': 'فنلندا', 'FR': 'فرنسا', 'GF': 'غويانا الفرنسية', 'PF': 'بولينيزيا الفرنسية', 'TF': 'الأقاليم الجنوبية الفرنسية', 'GA': 'الغابون', 'GM': 'غامبيا', 'GE': 'جورجيا',
    'DE': 'ألمانيا', 'GH': 'غانا', 'GI': 'جبل طارق', 'GR': 'اليونان', 'GL': 'جرينلاند', 'GD': 'غرينادا', 'GP': 'جوادلوب', 'GU': 'غوام', 'GT': 'غواتيمالا', 'GG': 'غيرنزي', 'GN': 'غينيا', 'GW': 'غينيا بيساو',
    'GY': 'غويانا', 'HT': 'هايتي', 'HM': 'جزيرة هيرد وجزر ماكدونالد', 'VA': 'الفاتيكان', 'HN': 'هندوراس', 'HK': 'هونغ كونغ', 'HU': 'المجر', 'IS': 'آيسلندا', 'IN': 'الهند', 'ID': 'إندونيسيا',
    'IR': 'إيران', 'IQ': 'العراق', 'IE': 'أيرلندا', 'IM': 'جزيرة مان', 'IL': 'إسرائيل', 'IT': 'إيطاليا', 'JM': 'جامايكا', 'JP': 'اليابان', 'JE': 'جيرزي', 'JO': 'الأردن', 'KZ': 'كازاخستان',
    'KE': 'كينيا', 'KI': 'كيريباتي', 'KP': 'كوريا الشمالية', 'KR': 'كوريا الجنوبية', 'KW': 'الكويت', 'KG': 'قيرغيزستان', 'LA': 'لاوس', 'LV': 'لاتفيا', 'LB': 'لبنان', 'LS': 'ليسوتو', 'LR': 'ليبيريا',
    'LY': 'ليبيا', 'LI': 'ليختنشتاين', 'LT': 'ليتوانيا', 'LU': 'لوكسمبورغ', 'MO': 'ماكاو', 'MK': 'مقدونيا', 'MG': 'مدغشقر', 'MW': 'مالاوي', 'MY': 'ماليزيا', 'MV': 'جزر المالديف', 'ML': 'مالي',
    'MT': 'مالطا', 'MH': 'جزر مارشال', 'MQ': 'مارتينيك', 'MR': 'موريتانيا', 'MU': 'موريشيوس', 'YT': 'مايوت', 'MX': 'المكسيك', 'FM': 'ميكرونيزيا', 'MD': 'مولدوفا', 'MC': 'موناكو', 'MN': 'منغوليا',
    'ME': 'الجبل الأسود', 'MS': 'مونتسرات', 'MA': 'المغرب', 'MZ': 'موزمبيق', 'MM': 'ميانمار', 'NA': 'ناميبيا', 'NR': 'ناورو', 'NP': 'نيبال', 'NL': 'هولندا', 'NC': 'كاليدونيا الجديدة', 'NZ': 'نيوزيلندا',
    'NI': 'نيكاراغوا', 'NE': 'النيجر', 'NG': 'نيجيريا', 'NU': 'نييوي', 'NF': 'جزيرة نورفولك', 'MP': 'جزر ماريانا الشمالية', 'NO': 'النرويج', 'OM': 'عُمان', 'PK': 'باكستان', 'PW': 'بالاو', 'PS': 'فلسطين',
    'PA': 'بنما', 'PG': 'بابوا غينيا الجديدة', 'PY': 'باراغواي', 'PE': 'بيرو', 'PH': 'الفلبين', 'PN': 'بيتكيرن', 'PL': 'بولندا', 'PT': 'البرتغال', 'PR': 'بورتوريكو', 'QA': 'قطر', 'RE': 'رِيونيون',
    'RO': 'رومانيا', 'RU': 'روسيا', 'RW': 'رواندا', 'BL': 'سان بارتلمي', 'SH': 'سانت هيلانة', 'KN': 'سانت كيتس ونيفس', 'LC': 'سانت لوسيا', 'MF': 'سانت مارتن', 'PM': 'سان بيير وميكلون',
    'VC': 'سانت فينسنت والغرينادين', 'WS': 'ساموا', 'SM': 'سان مارينو', 'ST': 'ساو تومي وبرينسيب', 'SA': 'السعودية', 'SN': 'السنغال', 'RS': 'صربيا', 'SC': 'سيشل', 'SL': 'سيراليون', 'SG': 'سنغافورة',
    'SK': 'سلوفاكيا', 'SI': 'سلوفينيا', 'SB': 'جزر سليمان', 'SO': 'الصومال', 'ZA': 'جنوب أفريقيا', 'GS': 'جورجيا الجنوبية وجزر ساندويتش الجنوبية', 'ES': 'إسبانيا', 'LK': 'سريلانكا', 'SD': 'السودان',
    'SR': 'سورينام', 'SJ': 'سفالبارد ويان ماين', 'SZ': 'إسواتيني', 'SE': 'السويد', 'CH': 'سويسرا', 'SY': 'سوريا', 'TW': 'تايوان', 'TJ': 'طاجيكستان', 'TZ': 'تنزانيا', 'TH': 'تايلاند', 'TL': 'تيمور الشرقية',
    'TG': 'توغو', 'TK': 'توكيلاو', 'TO': 'تونغا', 'TT': 'ترينيداد وتوباغو', 'TN': 'تونس', 'TR': 'تركيا', 'TM': 'تركمانستان', 'TC': 'جزر تركس وكايكوس', 'TV': 'توفالو', 'UG': 'أوغندا', 'UA': 'أوكرانيا',
    'BQ': 'بونير', 'CW': 'كوراساو', 'SS': 'جنوب السودان', 'SX': 'سينت مارتن', 'XK': 'كوسوفو',
    'AE': 'الإمارات', 'GB': 'بريطانيا', 'US': 'أمريكا', 'UM': 'جزر الولايات المتحدة الصغيرة النائية', 'UY': 'أوروغواي', 'UZ': 'أوزبكستان', 'VU': 'فانواتو', 'VE': 'فنزويلا', 'VN': 'فيتنام',
    'VG': 'جزر فيرجن البريطانية', 'VI': 'جزر فيرجن الأمريكية', 'WF': 'واليس وفوتونا', 'EH': 'الصحراء الغربية', 'YE': 'اليمن', 'ZM': 'زامبيا', 'ZW': 'زيمبابوي',
  };

  static const Map<String, String> _countriesEn = {
    'AF': 'Afghanistan', 'AX': 'Aland Islands', 'AL': 'Albania', 'DZ': 'Algeria', 'AS': 'American Samoa', 'AD': 'Andorra', 'AO': 'Angola', 'AI': 'Anguilla', 'AQ': 'Antarctica', 'AG': 'Antigua and Barbuda',
    'AR': 'Argentina', 'AM': 'Armenia', 'AW': 'Aruba', 'AU': 'Australia', 'AT': 'Austria', 'AZ': 'Azerbaijan', 'BS': 'Bahamas', 'BH': 'Bahrain', 'BD': 'Bangladesh', 'BB': 'Barbados',
    'BY': 'Belarus', 'BE': 'Belgium', 'BZ': 'Belize', 'BJ': 'Benin', 'BM': 'Bermuda', 'BT': 'Bhutan', 'BO': 'Bolivia', 'BA': 'Bosnia and Herzegovina', 'BW': 'Botswana', 'BV': 'Bouvet Island',
    'BR': 'Brazil', 'IO': 'British Indian Ocean Territory', 'BN': 'Brunei', 'BG': 'Bulgaria', 'BF': 'Burkina Faso', 'BI': 'Burundi', 'KH': 'Cambodia', 'CM': 'Cameroon', 'CA': 'Canada', 'CV': 'Cape Verde',
    'KY': 'Cayman Islands', 'CF': 'Central African Republic', 'TD': 'Chad', 'CL': 'Chile', 'CN': 'China', 'CX': 'Christmas Island', 'CC': 'Cocos Islands', 'CO': 'Colombia', 'KM': 'Comoros', 'CG': 'Congo',
    'CD': 'Democratic Republic of the Congo', 'CK': 'Cook Islands', 'CR': 'Costa Rica', 'CI': 'Cote d\'Ivoire', 'HR': 'Croatia', 'CU': 'Cuba', 'CY': 'Cyprus', 'CZ': 'Czech Republic', 'DK': 'Denmark', 'DJ': 'Djibouti',
    'DM': 'Dominica', 'DO': 'Dominican Republic', 'EC': 'Ecuador', 'EG': 'Egypt', 'SV': 'El Salvador', 'GQ': 'Equatorial Guinea', 'ER': 'Eritrea', 'EE': 'Estonia', 'ET': 'Ethiopia', 'FK': 'Falkland Islands',
    'FO': 'Faroe Islands', 'FJ': 'Fiji', 'FI': 'Finland', 'FR': 'France', 'GF': 'French Guiana', 'PF': 'French Polynesia', 'TF': 'French Southern Territories', 'GA': 'Gabon', 'GM': 'Gambia', 'GE': 'Georgia',
    'DE': 'Germany', 'GH': 'Ghana', 'GI': 'Gibraltar', 'GR': 'Greece', 'GL': 'Greenland', 'GD': 'Grenada', 'GP': 'Guadeloupe', 'GU': 'Guam', 'GT': 'Guatemala', 'GG': 'Guernsey', 'GN': 'Guinea', 'GW': 'Guinea-Bissau',
    'GY': 'Guyana', 'HT': 'Haiti', 'HM': 'Heard Island and McDonald Islands', 'VA': 'Vatican City', 'HN': 'Honduras', 'HK': 'Hong Kong', 'HU': 'Hungary', 'IS': 'Iceland', 'IN': 'India', 'ID': 'Indonesia',
    'IR': 'Iran', 'IQ': 'Iraq', 'IE': 'Ireland', 'IM': 'Isle of Man', 'IL': 'Israel', 'IT': 'Italy', 'JM': 'Jamaica', 'JP': 'Japan', 'JE': 'Jersey', 'JO': 'Jordan', 'KZ': 'Kazakhstan',
    'KE': 'Kenya', 'KI': 'Kiribati', 'KP': 'North Korea', 'KR': 'South Korea', 'KW': 'Kuwait', 'KG': 'Kyrgyzstan', 'LA': 'Laos', 'LV': 'Latvia', 'LB': 'Lebanon', 'LS': 'Lesotho', 'LR': 'Liberia',
    'LY': 'Libya', 'LI': 'Liechtenstein', 'LT': 'Lithuania', 'LU': 'Luxembourg', 'MO': 'Macau', 'MK': 'Macedonia', 'MG': 'Madagascar', 'MW': 'Malawi', 'MY': 'Malaysia', 'MV': 'Maldives', 'ML': 'Mali',
    'MT': 'Malta', 'MH': 'Marshall Islands', 'MQ': 'Martinique', 'MR': 'Mauritania', 'MU': 'Mauritius', 'YT': 'Mayotte', 'MX': 'Mexico', 'FM': 'Micronesia', 'MD': 'Moldova', 'MC': 'Monaco', 'MN': 'Mongolia',
    'ME': 'Montenegro', 'MS': 'Montserrat', 'MA': 'Morocco', 'MZ': 'Mozambique', 'MM': 'Myanmar', 'NA': 'Namibia', 'NR': 'Nauru', 'NP': 'Nepal', 'NL': 'Netherlands', 'NC': 'New Caledonia', 'NZ': 'New Zealand',
    'NI': 'Nicaragua', 'NE': 'Niger', 'NG': 'Nigeria', 'NU': 'Niue', 'NF': 'Norfolk Island', 'MP': 'Northern Mariana Islands', 'NO': 'Norway', 'OM': 'Oman', 'PK': 'Pakistan', 'PW': 'Palau', 'PS': 'Palestine',
    'PA': 'Panama', 'PG': 'Papua New Guinea', 'PY': 'Paraguay', 'PE': 'Peru', 'PH': 'Philippines', 'PN': 'Pitcairn', 'PL': 'Poland', 'PT': 'Portugal', 'PR': 'Puerto Rico', 'QA': 'Qatar', 'RE': 'Reunion',
    'RO': 'Romania', 'RU': 'Russia', 'RW': 'Rwanda', 'BL': 'Saint Barthelemy', 'SH': 'Saint Helena', 'KN': 'Saint Kitts and Nevis', 'LC': 'Saint Lucia', 'MF': 'Saint Martin', 'PM': 'Saint Pierre and Miquelon',
    'VC': 'Saint Vincent and the Grenadines', 'WS': 'Samoa', 'SM': 'San Marino', 'ST': 'Sao Tome and Principe', 'SA': 'Saudi Arabia', 'SN': 'Senegal', 'RS': 'Serbia', 'SC': 'Seychelles', 'SL': 'Sierra Leone', 'SG': 'Singapore',
    'SK': 'Slovakia', 'SI': 'Slovenia', 'SB': 'Solomon Islands', 'SO': 'Somalia', 'ZA': 'South Africa', 'GS': 'South Georgia and South Sandwich Islands', 'ES': 'Spain', 'LK': 'Sri Lanka', 'SD': 'Sudan',
    'SR': 'Suriname', 'SJ': 'Svalbard and Jan Mayen', 'SZ': 'Eswatini', 'SE': 'Sweden', 'CH': 'Switzerland', 'SY': 'Syria', 'TW': 'Taiwan', 'TJ': 'Tajikistan', 'TZ': 'Tanzania', 'TH': 'Thailand', 'TL': 'Timor-Leste',
    'TG': 'Togo', 'TK': 'Tokelau', 'TO': 'Tonga', 'TT': 'Trinidad and Tobago', 'TN': 'Tunisia', 'TR': 'Turkey', 'TM': 'Turkmenistan', 'TC': 'Turks and Caicos Islands', 'TV': 'Tuvalu', 'UG': 'Uganda', 'UA': 'Ukraine',
    'AE': 'UAE', 'GB': 'UK', 'US': 'USA', 'UM': 'US Minor Outlying Islands', 'UY': 'Uruguay', 'UZ': 'Uzbekistan', 'VU': 'Vanuatu', 'VE': 'Venezuela', 'VN': 'Vietnam',
    'BQ': 'Bonaire', 'CW': 'Curaçao', 'SS': 'South Sudan', 'SX': 'Sint Maarten', 'XK': 'Kosovo',
    'VG': 'British Virgin Islands', 'VI': 'US Virgin Islands', 'WF': 'Wallis and Futuna', 'EH': 'Western Sahara', 'YE': 'Yemen', 'ZM': 'Zambia', 'ZW': 'Zimbabwe',
  };
}