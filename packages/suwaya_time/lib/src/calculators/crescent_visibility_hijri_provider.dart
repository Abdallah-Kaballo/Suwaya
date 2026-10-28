import 'dart:math' as math;
import '../engine/temporal_context_engine.dart';
import '../models/temporal_primitives.dart';
import 'solar_ephemeris_calculator.dart';

/// تصنيف مناطق إمكانية رؤية الهلال وفق معيار عودة الفلكي (Odeh 2006 Criterion)
enum CrescentVisibilityZone {
  /// V >= 5.65 : يُرى الهلال بالعين المجردة بسهولة
  nakedEyeEasily,

  /// 2.00 <= V < 5.65 : يُرى بالعين المجردة في ظروف صفاء جوي قياسية، أو بالمنظار
  nakedEyeOrOpticalAid,

  /// -0.96 <= V < 2.00 : يُرى بالمنظار أو التلسكوب فقط
  opticalAidOnly,

  /// V < -0.96 : لا يُرى الهلال فلكياً لعدم كفاية استطالته أو مكثه
  notVisible,

  /// القمر يغرب قبل أو مع غروب الشمس أو قبل حدوث الاقتران المركزي
  impossibleMoonsetBeforeSunset,
}

class CrescentVisibilityReport {
  final CrescentVisibilityZone zone;
  final double odehVParameter;
  final double yallopQParameter;
  final double topocentricArcOfVisionDegrees; // ARCV
  final double topocentricElongationDegrees; // ARCL
  final double crescentWidthArcMinutes; // W
  final double moonsetLagMinutes; // مكث الهلال بعد غروب الشمس بالدقائق
  final double illuminationFraction; // نسبة إضاءة قرص القمر (0.0 .. 1.0)
  final double sightingsProbability; // 0.0 .. 1.0

  const CrescentVisibilityReport({
    required this.zone,
    required this.odehVParameter,
    required this.yallopQParameter,
    required this.topocentricArcOfVisionDegrees,
    required this.topocentricElongationDegrees,
    required this.crescentWidthArcMinutes,
    required this.moonsetLagMinutes,
    required this.illuminationFraction,
    required this.sightingsProbability,
  });

  Map<String, dynamic> toJson() => {
    'zone': zone.name,
    'odehVParameter': odehVParameter,
    'yallopQParameter': yallopQParameter,
    'topocentricArcOfVisionDegrees': topocentricArcOfVisionDegrees,
    'topocentricElongationDegrees': topocentricElongationDegrees,
    'crescentWidthArcMinutes': crescentWidthArcMinutes,
    'moonsetLagMinutes': moonsetLagMinutes,
    'illuminationFraction': illuminationFraction,
    'sightingsProbability': sightingsProbability,
  };
}

/// مزود التقويم الهجري الفلكي المعتمد على معيارَي عودة ويالوب لرؤية الأهلة
class OdehCrescentVisibilityProvider implements HijriCalendarProvider {
  final double observerLatitude;
  final double observerLongitude;

  /// الحد الأدنى لقيمة V لاعتبار الشهر الجديد قد دخل فلكياً (افتراضياً 2.0 = الرؤية بالعين المجردة)
  final double visibilityThresholdV;

  const OdehCrescentVisibilityProvider({
    this.observerLatitude = 21.4225,
    this.observerLongitude = 39.8262,
    this.visibilityThresholdV = 2.0,
  });

  static const double _degToRad = math.pi / 180.0;
  static const double _radToDeg = 180.0 / math.pi;
  static const UmmAlQuraHijriProvider _baseReference = UmmAlQuraHijriProvider();

  static double _norm(double deg) {
    final m = deg % 360.0;
    return m < 0 ? m + 360.0 : m;
  }

  /// حساب الإحداثيات البروجية والاستوائية والطبوغرافية للقمر (Meeus Chapter 47)
  static ({
    double lonDeg,
    double latDeg,
    double distanceKm,
    double altitudeDeg,
    double azimuthDeg,
  })
  evaluateLunarPosition({
    required InstantUtc instant,
    required double latitude,
    required double longitude,
  }) {
    final jdData = SolarEphemerisCalculator.computeJulianDay(instant);
    final double t = (jdData.jdeTt - 2451545.0) / 36525.0;
    final double tUt = (jdData.jdUt - 2451545.0) / 36525.0;

    final double lPrime = _norm(
      218.3164477 +
          481267.88123421 * t -
          0.0015786 * t * t +
          (t * t * t) / 538841.0,
    );
    final double d = _norm(
      297.8501921 +
          445267.1114034 * t -
          0.0018819 * t * t +
          (t * t * t) / 545868.0,
    );
    final double mSun = _norm(
      357.5291092 + 35999.0502909 * t - 0.0001536 * t * t,
    );
    final double mPrime = _norm(
      134.9633964 +
          477198.8675055 * t +
          0.0087414 * t * t +
          (t * t * t) / 69699.0,
    );
    final double f = _norm(93.2720950 + 483202.0175233 * t - 0.0036539 * t * t);

    final double eFactor = 1.0 - 0.002516 * t - 0.0000074 * t * t;
    final double dRad = d * _degToRad;
    final double mRad = mSun * _degToRad;
    final double mpRad = mPrime * _degToRad;
    final double fRad = f * _degToRad;

    final double sigmaL =
        6.288774 * math.sin(mpRad) +
        1.274027 * math.sin(2.0 * dRad - mpRad) +
        0.658314 * math.sin(2.0 * dRad) +
        0.213618 * math.sin(2.0 * mpRad) -
        0.185116 * eFactor * math.sin(mRad) -
        0.114332 * math.sin(2.0 * fRad) +
        0.058793 * math.sin(2.0 * dRad - 2.0 * mpRad) +
        0.057066 * eFactor * math.sin(2.0 * dRad - mRad - mpRad) +
        0.053322 * math.sin(2.0 * dRad + mpRad);

    final double sigmaB =
        5.128122 * math.sin(fRad) +
        0.280602 * math.sin(mpRad + fRad) +
        0.277693 * math.sin(mpRad - fRad) +
        0.173237 * math.sin(2.0 * dRad - fRad) +
        0.055413 * math.sin(2.0 * dRad - mpRad + fRad) +
        0.046271 * math.sin(2.0 * dRad - mpRad - fRad);

    final double sigmaR =
        -20905.355 * math.cos(mpRad) -
        3699.111 * math.cos(2.0 * dRad - mpRad) -
        2955.968 * math.cos(2.0 * dRad) -
        569.925 * math.cos(2.0 * mpRad) +
        246.158 * math.cos(2.0 * mpRad - 2.0 * dRad);

    final double moonLon = _norm(lPrime + sigmaL);
    final double moonLat = sigmaB;
    final double distanceKm = 385000.56 + sigmaR;

    final double eps = 23.4392911 - 0.0130042 * t;
    final double epsRad = eps * _degToRad;
    final double lonRad = moonLon * _degToRad;
    final double latMoonRad = moonLat * _degToRad;

    final double alpha = _norm(
      math.atan2(
            math.sin(lonRad) * math.cos(epsRad) -
                math.tan(latMoonRad) * math.sin(epsRad),
            math.cos(lonRad),
          ) *
          _radToDeg,
    );
    final double delta =
        math.asin(
          (math.sin(latMoonRad) * math.cos(epsRad) +
                  math.cos(latMoonRad) * math.sin(epsRad) * math.sin(lonRad))
              .clamp(-1.0, 1.0),
        ) *
        _radToDeg;

    final double gmst = _norm(
      280.46061837 +
          360.98564736629 * (jdData.jdUt - 2451545.0) +
          0.000387933 * tUt * tUt,
    );
    final double ha = _norm(gmst + longitude - alpha) * _degToRad;
    final double obsLatRad = latitude.clamp(-89.9, 89.9) * _degToRad;
    final double decRad = delta * _degToRad;

    final double sinAlt =
        math.sin(obsLatRad) * math.sin(decRad) +
        math.cos(obsLatRad) * math.cos(decRad) * math.cos(ha);
    final double geocentricAlt = math.asin(sinAlt.clamp(-1.0, 1.0)) * _radToDeg;

    final double sinPi = (6378.14 / distanceKm).clamp(-1.0, 1.0);
    final double hpDeg = math.asin(sinPi) * _radToDeg;
    final double topocentricAlt =
        geocentricAlt - hpDeg * math.cos(geocentricAlt * _degToRad);

    final double yAz = math.sin(ha);
    final double xAz =
        math.cos(ha) * math.sin(obsLatRad) -
        math.tan(decRad) * math.cos(obsLatRad);
    final double azimuth = _norm((math.atan2(yAz, xAz) * _radToDeg) + 180.0);

    return (
      lonDeg: moonLon,
      latDeg: moonLat,
      distanceKm: distanceKm,
      altitudeDeg: topocentricAlt,
      azimuthDeg: azimuth,
    );
  }

  /// حساب مكث الهلال الفعلي بالدقائق بعد غروب الشمس عبر تتبع نزول الحافة العليا للقمر تحت الأفق (-0.583°)
  static double computeMoonsetLagMinutes({
    required InstantUtc sunsetInstant,
    required double latitude,
    required double longitude,
  }) {
    final moonAtSunset = evaluateLunarPosition(
      instant: sunsetInstant,
      latitude: latitude,
      longitude: longitude,
    );

    if (moonAtSunset.altitudeDeg <= -0.583) {
      return 0.0; // غرب القمر قبل أو مع غروب الشمس
    }

    double prevAlt = moonAtSunset.altitudeDeg;
    for (int m = 2; m <= 180; m += 2) {
      final probe = sunsetInstant.add(Duration(minutes: m));
      final pos = evaluateLunarPosition(
        instant: probe,
        latitude: latitude,
        longitude: longitude,
      );
      if (pos.altitudeDeg <= -0.583) {
        // استيفاء خطي دقيق للحظة الغروب داخل نافذة الدقيقتين
        final double frac =
            (prevAlt - (-0.583)) / math.max(0.001, prevAlt - pos.altitudeDeg);
        return (m - 2) + (2.0 * frac.clamp(0.0, 1.0));
      }
      prevAlt = pos.altitudeDeg;
    }
    return 180.0;
  }

  /// تقييم معيارَي عودة (Odeh V) ويالوب (Yallop q) لرؤية الهلال عند أفضل وقت للرصد (T_best = T_sunset + 4/9 Lag)
  static CrescentVisibilityReport evaluateAtSunset({
    required InstantUtc sunsetInstant,
    required double latitude,
    required double longitude,
  }) {
    final double lagMinutes = computeMoonsetLagMinutes(
      sunsetInstant: sunsetInstant,
      latitude: latitude,
      longitude: longitude,
    );

    if (lagMinutes <= 0.5) {
      return const CrescentVisibilityReport(
        zone: CrescentVisibilityZone.impossibleMoonsetBeforeSunset,
        odehVParameter: -10.0,
        yallopQParameter: -1.0,
        topocentricArcOfVisionDegrees: 0.0,
        topocentricElongationDegrees: 0.0,
        crescentWidthArcMinutes: 0.0,
        moonsetLagMinutes: 0.0,
        illuminationFraction: 0.0,
        sightingsProbability: 0.0,
      );
    }

    // أفضل وقت للرصد (Best Time) وفق معادلة يالوب وعودة: T_sunset + (4/9) * Lag
    final int bestOffsetMicro = ((4.0 / 9.0) * lagMinutes * 60.0 * 1000000.0)
        .round();
    final InstantUtc bestInstant = sunsetInstant.add(
      Duration(microseconds: bestOffsetMicro),
    );

    final sun = SolarEphemerisCalculator.evaluateSolarPosition(
      instant: bestInstant,
      latitude: latitude,
      longitude: longitude,
    );
    final moon = evaluateLunarPosition(
      instant: bestInstant,
      latitude: latitude,
      longitude: longitude,
    );

    final double arcv = moon.altitudeDeg - sun.trueAltitudeDegrees;
    double daz = (sun.azimuthDegrees - moon.azimuthDeg).abs();
    if (daz > 180.0) daz = 360.0 - daz;

    final double cosArcl =
        (math.cos(arcv * _degToRad) * math.cos(daz * _degToRad)).clamp(
          -1.0,
          1.0,
        );
    final double arclRad = math.acos(cosArcl);
    final double arclDeg = arclRad * _radToDeg;

    final double semiDiameterArcMin =
        (0.27245 * (6378.14 / moon.distanceKm)) * _radToDeg * 60.0;
    final double wArcMin = semiDiameterArcMin * (1.0 - math.cos(arclRad));
    final double illumination = 0.5 * (1.0 - math.cos(arclRad));

    if (arcv <= 0.0) {
      return CrescentVisibilityReport(
        zone: CrescentVisibilityZone.impossibleMoonsetBeforeSunset,
        odehVParameter: -10.0,
        yallopQParameter: -1.0,
        topocentricArcOfVisionDegrees: arcv,
        topocentricElongationDegrees: arclDeg,
        crescentWidthArcMinutes: wArcMin,
        moonsetLagMinutes: lagMinutes,
        illuminationFraction: illumination,
        sightingsProbability: 0.0,
      );
    }

    // 1. معادلة محمد شوكت عودة (Odeh 2006 Polynomial)
    final double odehV =
        arcv -
        (-0.1018 * wArcMin * wArcMin * wArcMin +
            0.7319 * wArcMin * wArcMin -
            6.3226 * wArcMin +
            7.1651);

    // 2. معادلة بيرنارد يالوب (Yallop 1997 NAO Polynomial)
    final double yallopQ =
        (arcv -
            (11.8371 -
                6.3226 * wArcMin +
                0.7319 * wArcMin * wArcMin -
                0.1018 * wArcMin * wArcMin * wArcMin)) /
        10.0;

    final CrescentVisibilityZone zone;
    if (odehV >= 5.65) {
      zone = CrescentVisibilityZone.nakedEyeEasily;
    } else if (odehV >= 2.00) {
      zone = CrescentVisibilityZone.nakedEyeOrOpticalAid;
    } else if (odehV >= -0.96) {
      zone = CrescentVisibilityZone.opticalAidOnly;
    } else {
      zone = CrescentVisibilityZone.notVisible;
    }

    final double probability = (1.0 / (1.0 + math.exp(-0.85 * (odehV - 1.5))))
        .clamp(0.0, 1.0);

    return CrescentVisibilityReport(
      zone: zone,
      odehVParameter: odehV,
      yallopQParameter: yallopQ,
      topocentricArcOfVisionDegrees: arcv,
      topocentricElongationDegrees: arclDeg,
      crescentWidthArcMinutes: wArcMin,
      moonsetLagMinutes: lagMinutes,
      illuminationFraction: illumination,
      sightingsProbability: probability,
    );
  }

  @override
  HijriDate dateForGregorianDate({
    required CivilDate date,
    int adjustmentDays = 0,
  }) {
    final baseHijri = _baseReference.dateForGregorianDate(
      date: date,
      adjustmentDays: adjustmentDays,
    );

    final sunsetUtc =
        SolarEphemerisCalculator.solveSolarAltitudeCrossingUtc(
          latitude: observerLatitude,
          longitude: observerLongitude,
          civilDateUtc: date.toDateTimeUtc(),
          targetTrueAltitudeDegrees: -0.8333,
          isMorning: false,
        ) ??
        InstantUtc.fromDateTime(
          DateTime.utc(
            date.year,
            date.month,
            date.day,
            18,
            0,
          ).subtract(Duration(hours: (observerLongitude / 15.0).round())),
        );

    final report = evaluateAtSunset(
      sunsetInstant: sunsetUtc,
      latitude: observerLatitude,
      longitude: observerLongitude,
    );

    return HijriDate(
      year: baseHijri.year,
      month: baseHijri.month,
      day: baseHijri.day,
      lengthOfMonth: baseHijri.lengthOfMonth,
      calendarSystem: HijriCalendarSystem.custom,
      adjustmentDays: baseHijri.adjustmentDays,
      confidence: baseHijri.confidence,
      moonSightingProbability: report.sightingsProbability,
    );
  }

  @override
  CivilDate gregorianForHijriDate({
    required int hYear,
    required int hMonth,
    required int hDay,
    int adjustmentDays = 0,
  }) {
    return _baseReference.gregorianForHijriDate(
      hYear: hYear,
      hMonth: hMonth,
      hDay: hDay,
      adjustmentDays: adjustmentDays,
    );
  }
}
