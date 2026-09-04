import 'dart:math';
// افترض أن لديك نموذج لبيانات المدن المحفوظة في SQLite
// import '../../models/city_model.dart'; 

class GeoUtils {
  /// معادلة Haversine لحساب المسافة الدقيقة بالكيلومترات بين نقطتين
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  /// البحث عن أقرب مدينة من القائمة المدمجة
  static String findNearestCityName(double lat, double lng, List<dynamic> allDbCities) {
    if (allDbCities.isEmpty) return "مدينة غير معروفة";

    double minDistance = double.infinity;
    String nearestName = "";

    for (var city in allDbCities) {
      double distance = calculateDistance(lat, lng, city.latitude, city.longitude);
      if (distance < minDistance) {
        minDistance = distance;
        nearestName = city.name; // مثل "الرياض" أو "القاهرة"
      }
    }
    return nearestName;
  }
}