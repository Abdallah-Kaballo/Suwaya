import 'package:geolocator/geolocator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'geo_database_service.dart';
import '../../features/settings/settings_provider.dart';

class LocationException implements Exception {
  final String messageKey;
  LocationException(this.messageKey);
  @override
  String toString() => messageKey.tr();
}

class LocationService {
  static const Duration _freshMaxAge = Duration(minutes: 10);
  static const double _freshMaxAccuracyMeters = 150.0;

  // الحدود القصوى المسموح بها عند السقوط الاحتياطي لآخر موقع معروف
  static const Duration _fallbackMaxAge = Duration(hours: 12);
  static const double _fallbackMaxAccuracyMeters = 2500.0;

  static bool _isAcceptableFallback(Position pos) {
    final age = DateTime.now().difference(pos.timestamp).abs();
    return age <= _fallbackMaxAge && pos.accuracy <= _fallbackMaxAccuracyMeters;
  }

  static Future<Position> determinePosition() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('location_picker.error_gps_disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
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
        if (age <= _freshMaxAge &&
            lastKnown.accuracy <= _freshMaxAccuracyMeters) {
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
    } catch (_) {
      // لا نقبل الموقع القديم عند فشل الـ GPS إلا إذا كان ضمن هامش صلاحية ودقة موثوق
      if (lastKnown != null && _isAcceptableFallback(lastKnown)) {
        return lastKnown;
      }
      throw LocationException('location_picker.error_gps_timeout');
    }
  }

  static Future<Map<String, dynamic>> fetchOfflineLocation(
    String langCode,
  ) async {
    final Position position = await determinePosition();

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

    // الاعتماد على الجدول المرجعي الموحد للدول (شاملاً طريقة الحساب، المذهب، وقاعدة العروض العليا)
    final smartDefaults = AstroSmartDefaults.getDefaultsForCountry(countryCode);

    return {
      'lat': position.latitude,
      'lng': position.longitude,
      'city': city,
      'country': country,
      'countryCode': countryCode,
      'timezone': timezone,
      'method': smartDefaults.method,
      'madhab': smartDefaults.madhab,
      'highLatRule': smartDefaults.highLatitudeRule,
      'formattedName': '$city / $country',
    };
  }
}