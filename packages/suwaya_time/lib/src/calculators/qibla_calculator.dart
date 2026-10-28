import 'dart:math' as math;
import '../models/temporal_primitives.dart';
import 'solar_ephemeris_calculator.dart';

/// مخرجات حساب القبلة الجيوديسي الإهليلجي الدقيق (WGS84 Ellipsoid)
class QiblaDirectionResult {
  /// زاوية القبلة من الشمال الحقيقي باتجاه عقارب الساعة (0°..360°)
  final double bearingDegrees;

  /// السمت العكسي من الكعبة المشرفة إلى موقع الراصد (0°..360°)
  final double reverseBearingDegrees;

  /// المسافة الجيوديسية الإهليلجية الدقيقة بالكيلومتر (WGS84)
  final double distanceKilometers;

  /// المسافة الكروية المقابلة للمقارنة (Great-Circle Spherical Distance)
  final double sphericalBearingDegrees;

  const QiblaDirectionResult({
    required this.bearingDegrees,
    required this.reverseBearingDegrees,
    required this.distanceKilometers,
    required this.sphericalBearingDegrees,
  });

  Map<String, dynamic> toJson() => {
    'bearingDegrees': bearingDegrees,
    'reverseBearingDegrees': reverseBearingDegrees,
    'distanceKilometers': distanceKilometers,
    'sphericalBearingDegrees': sphericalBearingDegrees,
  };
}

class QiblaCalculator {
  /// الإحداثيات الجيوديسية الدقيقة لمركز الكعبة المشرفة (WGS84)
  static const double kaabaLatitude = 21.422487;
  static const double kaabaLongitude = 39.826206;

  // ثوابت المجسم الإهليلجي المرجعي للأرض (WGS84 Ellipsoid)
  static const double _wgs84A = 6378137.0; // نصف القطر الاستوائي بالمتر
  static const double _wgs84F = 1.0 / 298.257223563; // التفلطح
  static const double _wgs84B = (1.0 - _wgs84F) * _wgs84A; // نصف القطر القطبي

  static const double _degToRad = math.pi / 180.0;
  static const double _radToDeg = 180.0 / math.pi;

  static double _normalizeBearing(double deg) {
    final mod = deg % 360.0;
    return mod < 0 ? mod + 360.0 : mod;
  }

  /// حساب اتجاه القبلة والمسافة الجيوديسية بمعادلة فينسنتي الإهليلجية (Vincenty's Inverse Formula - WGS84)
  static QiblaDirectionResult calculate(double latitude, double longitude) {
    final safeLat = latitude.clamp(-89.9999, 89.9999);
    final safeLng = ((longitude + 180.0) % 360.0 + 360.0) % 360.0 - 180.0;

    final sphericalBearing = calculateSphericalBearing(safeLat, safeLng);

    // إذا كان الراصد داخل صحن المطاف مباشرةً
    if ((safeLat - kaabaLatitude).abs() < 1e-5 &&
        (safeLng - kaabaLongitude).abs() < 1e-5) {
      return const QiblaDirectionResult(
        bearingDegrees: 0.0,
        reverseBearingDegrees: 180.0,
        distanceKilometers: 0.0,
        sphericalBearingDegrees: 0.0,
      );
    }

    final double phi1 = safeLat * _degToRad;
    final double l1 = safeLng * _degToRad;
    final double phi2 = kaabaLatitude * _degToRad;
    final double l2 = kaabaLongitude * _degToRad;

    final double u1 = math.atan((1.0 - _wgs84F) * math.tan(phi1));
    final double u2 = math.atan((1.0 - _wgs84F) * math.tan(phi2));
    final double l = l2 - l1;

    final double sinU1 = math.sin(u1), cosU1 = math.cos(u1);
    final double sinU2 = math.sin(u2), cosU2 = math.cos(u2);

    double lambda = l;
    double lambdaPrev = 0.0;
    int iterLimit = 100;

    double cosSqAlpha = 0.0;
    double sinSigma = 0.0;
    double cosSigma = 0.0;
    double cos2SigmaM = 0.0;
    double sigma = 0.0;

    while ((lambda - lambdaPrev).abs() > 1e-12 && --iterLimit > 0) {
      final double sinLambda = math.sin(lambda);
      final double cosLambda = math.cos(lambda);

      final double term1 = cosU2 * sinLambda;
      final double term2 = cosU1 * sinU2 - sinU1 * cosU2 * cosLambda;
      sinSigma = math.sqrt(term1 * term1 + term2 * term2);

      if (sinSigma == 0.0) {
        return const QiblaDirectionResult(
          bearingDegrees: 0.0,
          reverseBearingDegrees: 180.0,
          distanceKilometers: 0.0,
          sphericalBearingDegrees: 0.0,
        );
      }

      cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
      sigma = math.atan2(sinSigma, cosSigma);

      final double sinAlpha = (cosU1 * cosU2 * sinLambda) / sinSigma;
      cosSqAlpha = 1.0 - sinAlpha * sinAlpha;

      cos2SigmaM = (cosSqAlpha != 0.0)
          ? (cosSigma - (2.0 * sinU1 * sinU2) / cosSqAlpha)
          : 0.0;

      final double c =
          (_wgs84F / 16.0) *
          cosSqAlpha *
          (4.0 + _wgs84F * (4.0 - 3.0 * cosSqAlpha));

      lambdaPrev = lambda;
      lambda =
          l +
          (1.0 - c) *
              _wgs84F *
              sinAlpha *
              (sigma +
                  c *
                      sinSigma *
                      (cos2SigmaM +
                          c * cosSigma * (-1.0 + 2.0 * cos2SigmaM * cos2SigmaM)));
    }

    if (iterLimit == 0) {
      // السقوط الآمن للنقاط المتقابلة قطرياً (Antipodal Points) في المحيط الهادئ
      return QiblaDirectionResult(
        bearingDegrees: sphericalBearing,
        reverseBearingDegrees: _normalizeBearing(sphericalBearing + 180.0),
        distanceKilometers: 20003.93,
        sphericalBearingDegrees: sphericalBearing,
      );
    }

    final double uSq =
        cosSqAlpha *
        (_wgs84A * _wgs84A - _wgs84B * _wgs84B) /
        (_wgs84B * _wgs84B);
    final double aCoeff =
        1.0 +
        (uSq / 16384.0) *
            (4096.0 + uSq * (-768.0 + uSq * (320.0 - 175.0 * uSq)));
    final double bCoeff =
        (uSq / 1024.0) * (256.0 + uSq * (-128.0 + uSq * (74.0 - 47.0 * uSq)));

    final double deltaSigma =
        bCoeff *
        sinSigma *
        (cos2SigmaM +
            (bCoeff / 4.0) *
                (cosSigma * (-1.0 + 2.0 * cos2SigmaM * cos2SigmaM) -
                    (bCoeff / 6.0) *
                        cos2SigmaM *
                        (-3.0 + 4.0 * sinSigma * sinSigma) *
                        (-3.0 + 4.0 * cos2SigmaM * cos2SigmaM)));

    final double distanceMeters = _wgs84B * aCoeff * (sigma - deltaSigma);

    final double fwdAz = math.atan2(
      cosU2 * math.sin(lambda),
      cosU1 * sinU2 - sinU1 * cosU2 * math.cos(lambda),
    );
    final double revAz = math.atan2(
      cosU1 * math.sin(lambda),
      -sinU1 * cosU2 + cosU1 * sinU2 * math.cos(lambda),
    );

    return QiblaDirectionResult(
      bearingDegrees: _normalizeBearing(fwdAz * _radToDeg),
      reverseBearingDegrees: _normalizeBearing((revAz * _radToDeg) + 180.0),
      distanceKilometers: distanceMeters / 1000.0,
      sphericalBearingDegrees: sphericalBearing,
    );
  }

  /// معادلة الدائرة العظمى الكروية الكلاسيكية (Spherical Great-Circle Qibla)
  static double calculateSphericalBearing(double latitude, double longitude) {
    final double phi1 = latitude * _degToRad;
    final double phi2 = kaabaLatitude * _degToRad;
    final double deltaL = (kaabaLongitude - longitude) * _degToRad;

    final double y = math.sin(deltaL);
    final double x =
        math.cos(phi1) * math.tan(phi2) - math.sin(phi1) * math.cos(deltaL);
    return _normalizeBearing(math.atan2(y, x) * _radToDeg);
  }

  /// حساب اللحظتين السنويتين لتعامد الشمس على الكعبة المشرفة (Solar Zenith over Kaaba: 28 مايو و16 يوليو)
  /// عند هاتين اللحظتين، من ينظر إلى الشمس في أي بقعة نهارية في العالم يكون متجهاً إلى القبلة بدقة 100%
  static ({InstantUtc firstZenithUtc, InstantUtc secondZenithUtc})
  annualKaabaSolarZeniths(int gregorianYear) {
    // الزوال الشمسي في مكة يقع حوالي الساعة 09:18 UTC في مايو و 09:26 UTC في يوليو
    return (
      firstZenithUtc: InstantUtc.fromDateTime(
        DateTime.utc(gregorianYear, 5, 28, 9, 18),
      ),
      secondZenithUtc: InstantUtc.fromDateTime(
        DateTime.utc(gregorianYear, 7, 16, 9, 26),
      ),
    );
  }

  /// إيجاد اللحظة اليومية التي تكون فيها الشمس في سمت القبلة أو عكسه (+180° بحيث يشير ظل أي شاخص رأسي نحو القبلة)
  static ({
    InstantUtc? sunFacingQiblaUtc,
    InstantUtc? shadowPointingToQiblaUtc,
  })
  findDailySolarQiblaAlignment({
    required double latitude,
    required double longitude,
    required DateTime dateUtc,
  }) {
    final qibla = calculate(latitude, longitude).bearingDegrees;
    final antiQibla = _normalizeBearing(qibla + 180.0);

    final baseDayStartUtc = DateTime.utc(
      dateUtc.year,
      dateUtc.month,
      dateUtc.day,
    ).subtract(Duration(hours: (longitude / 15.0).round()));

    InstantUtc? bestSunFacing;
    double minSunDiff = 3.0; // هامش تطابق السمت <= 3 درجات

    InstantUtc? bestShadowPointing;
    double minShadowDiff = 3.0;

    for (int minute = 0; minute < 1440; minute += 2) {
      final inst = InstantUtc.fromDateTime(
        baseDayStartUtc.add(Duration(minutes: minute)),
      );
      final pos = SolarEphemerisCalculator.evaluateSolarPosition(
        instant: inst,
        latitude: latitude,
        longitude: longitude,
      );

      // يشترط أن تكون الشمس مشرقة فوق الأفق (+2° على الأقل لتكوين ظل واضح)
      if (pos.apparentAltitudeDegrees < 2.0) continue;

      double diffSun = (pos.azimuthDegrees - qibla).abs();
      if (diffSun > 180.0) diffSun = 360.0 - diffSun;
      if (diffSun < minSunDiff) {
        minSunDiff = diffSun;
        bestSunFacing = inst;
      }

      double diffShadow = (pos.azimuthDegrees - antiQibla).abs();
      if (diffShadow > 180.0) diffShadow = 360.0 - diffShadow;
      if (diffShadow < minShadowDiff) {
        minShadowDiff = diffShadow;
        bestShadowPointing = inst;
      }
    }

    return (
      sunFacingQiblaUtc: bestSunFacing,
      shadowPointingToQiblaUtc: bestShadowPointing,
    );
  }
}