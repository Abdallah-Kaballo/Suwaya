import 'package:geolocator/geolocator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'geo_database_service.dart';

class LocationException implements Exception {
  final String messageKey;
  LocationException(this.messageKey);
  @override
  String toString() => messageKey.tr();
}

class LocationService {
  static Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('location_picker.error_gps_disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('location_picker.error_permission_denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException('location_picker.error_permission_denied_forever');
    }

    Position? lastKnown;
    try {
      lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        final age = DateTime.now().difference(lastKnown.timestamp).abs();
        // 🌟 قبول الموقع المخزن مسبقاً فقط إذا كان حديثاً (أقل من 10 دقائق) ودقيقاً (<= 150 متر)
        if (age <= const Duration(minutes: 10) && lastKnown.accuracy <= 150) {
          return lastKnown;
        }
      }
    } catch (_) {}

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (e) {
      // 🌟 استخدام آخر موقع معروف كخطة بديلة فقط عند انتهاء مهلة الـ GPS
      if (lastKnown != null) return lastKnown;
      throw LocationException('location_picker.error_gps_timeout');
    }
  }

  static Future<Map<String, dynamic>> fetchOfflineLocation(
      String langCode) async {
    Position position = await determinePosition();

    final localData = await GeoDatabaseService.getNearestLocationData(
      position.latitude,
      position.longitude,
      langCode,
    );

    String city = 'common.unknown'.tr();
    String country = 'common.unknown'.tr();
    String countryCode = 'XX';
    String? timezone;

    if (localData != null) {
      city = localData['cityName'] ?? 'common.unknown'.tr();
      countryCode = localData['countryCode'] ?? 'XX';
      timezone = localData['timezone'] as String?;
      country = GeoDatabaseService.getLocalizedCountryName(
        countryCode,
        langCode,
      );
    }

    return {
      'lat': position.latitude,
      'lng': position.longitude,
      'city': city,
      'country': country,
      'countryCode': countryCode,
      'timezone': timezone, // 🌟 تمرير المنطقة الزمنية لضبط التوقيت الصيفي والشتوي
      'method': _determineMethod(countryCode, country),
      'madhab': _determineMadhab(countryCode, country),
      'formattedName': '$city / $country',
    };
  }

  static String _determineMethod(String code, String countryName) {
    final c = countryName.toLowerCase();
    if (code == 'EG' || c.contains('مصر') || c.contains('سودان')) {
      return 'egyptian';
    }
    if (code == 'SA' || c.contains('سعودية')) return 'ummAlQura';
    if (code == 'PK' ||
        code == 'IN' ||
        c.contains('باكستان') ||
        c.contains('هند')) {
      return 'karachi';
    }
    if (code == 'TR' || c.contains('تركيا')) return 'turkey';
    if (code == 'KW' || c.contains('كويت')) return 'kuwait';
    if (code == 'QA' || c.contains('قطر')) return 'qatar';
    if (code == 'AE' || c.contains('إمارات')) return 'dubai';
    if (code == 'US' ||
        code == 'CA' ||
        c.contains('أمريكا') ||
        c.contains('كندا')) {
      return 'north_america';
    }
    if (code == 'IR' || c.contains('إيران')) return 'tehran';
    return 'muslim_world_league';
  }

  static String _determineMadhab(String code, String countryName) {
    if (['PK', 'IN', 'TR', 'BD', 'AF'].contains(code.toUpperCase())) {
      return 'hanafi';
    }
    return 'shafi';
  }
}