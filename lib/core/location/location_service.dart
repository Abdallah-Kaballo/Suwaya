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

    try {
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;
    } catch (_) {}

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium, 
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (e) {
      throw LocationException('location_picker.error_gps_timeout');
    }
  }

  static Future<Map<String, dynamic>> fetchOfflineLocation(String langCode) async {
    Position position = await determinePosition();
    
    final localData = await GeoDatabaseService.getNearestLocationData(
      position.latitude, 
      position.longitude, 
      langCode
    );

    String city = 'common.unknown'.tr();
    String country = 'common.unknown'.tr();
    String countryCode = 'XX';

    if (localData != null) {
      city = localData['cityName'] ?? 'common.unknown'.tr();
      countryCode = localData['countryCode'] ?? 'XX';
      country = GeoDatabaseService.getLocalizedCountryName(countryCode, langCode);
    }

    return {
      'lat': position.latitude,
      'lng': position.longitude,
      'city': city,
      'country': country,
      'countryCode': countryCode,
      'method': _determineMethod(countryCode, country),
      'madhab': _determineMadhab(countryCode, country),
      'formattedName': '$city / $country', 
    };
  }

  static String _determineMethod(String code, String countryName) {
    final c = countryName.toLowerCase();
    if (code == 'EG' || c.contains('مصر') || c.contains('سودان')) return 'egyptian';
    if (code == 'SA' || c.contains('سعودية')) return 'ummAlQura';
    if (code == 'PK' || code == 'IN' || c.contains('باكستان') || c.contains('هند')) return 'karachi';
    if (code == 'TR' || c.contains('تركيا')) return 'turkey';
    if (code == 'KW' || c.contains('كويت')) return 'kuwait';
    if (code == 'QA' || c.contains('قطر')) return 'qatar';
    if (code == 'AE' || c.contains('إمارات')) return 'dubai';
    if (code == 'US' || code == 'CA' || c.contains('أمريكا') || c.contains('كندا')) return 'north_america';
    if (code == 'IR' || c.contains('إيران')) return 'tehran';
    return 'muslim_world_league'; 
  }

  static String _determineMadhab(String code, String countryName) {
    if (['PK', 'IN', 'TR', 'BD', 'AF'].contains(code.toUpperCase())) return 'hanafi';
    return 'shafi'; 
  }
}