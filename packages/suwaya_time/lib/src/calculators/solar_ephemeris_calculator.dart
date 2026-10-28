import 'dart:math' as math;
import '../models/astro_models.dart';
import '../models/temporal_primitives.dart';

/// الظروف الجوية الطبوغرافية للمرصد (حرارة، ضغط، ارتفاع) لحساب الانكسار الجوي بدقة
class AtmosphericConditions {
  final double temperatureCelsius;
  final double pressureHpa;
  final double elevationMeters;

  const AtmosphericConditions({
    this.temperatureCelsius = 15.0,
    this.pressureHpa = 1013.25,
    this.elevationMeters = 0.0,
  });

  /// تقدير الضغط الجوي القياسي تلقائياً من الارتفاع عن سطح البحر (Barometric Formula)
  factory AtmosphericConditions.fromElevation(
    double elevationMeters, {
    double temperatureCelsius = 15.0,
  }) {
    final safeElev = elevationMeters.clamp(-450.0, 9000.0);
    final pressure =
        1013.25 * math.pow(1.0 - (0.0000225577 * safeElev), 5.25588);
    return AtmosphericConditions(
      temperatureCelsius: temperatureCelsius,
      pressureHpa: pressure.toDouble(),
      elevationMeters: safeElev,
    );
  }

  /// فرق دقائق الشروق/الغروب الناتج عن اختلاف الحرارة والضغط عن المعيار القياسي (10°C, 1010 hPa)
  Duration horizonRefractionTimeDelta(double latitudeDegrees) {
    const double standardRefractionArcMin = 34.478;
    final double actualRefractionArcMin =
        standardRefractionArcMin *
        (pressureHpa / 1010.0) *
        (283.15 / (273.15 + temperatureCelsius.clamp(-60.0, 60.0)));
    final double deltaDegrees =
        (actualRefractionArcMin - standardRefractionArcMin) / 60.0;
    final double latRad =
        (latitudeDegrees.abs().clamp(0.0, 65.0)) * (math.pi / 180.0);
    final double minutesShift = (deltaDegrees * 4.0) / math.cos(latRad);
    return Duration(microseconds: (minutesShift * 60 * 1000000).round());
  }

  Map<String, dynamic> toJson() => {
    'temperatureCelsius': temperatureCelsius,
    'pressureHpa': pressureHpa,
    'elevationMeters': elevationMeters,
  };
}

/// الموقع اللحظي للشمس في السماء (الإحداثيات الأفقية والاستوائية)
class SolarPosition {
  final InstantUtc instant;
  final double trueAltitudeDegrees;
  final double apparentAltitudeDegrees;
  final double refractionDegrees;
  final double azimuthDegrees;
  final double declinationDegrees;
  final double rightAscensionDegrees;
  final double equationOfTimeMinutes;
  final double hourAngleDegrees;
  final double deltaTSeconds;

  const SolarPosition({
    required this.instant,
    required this.trueAltitudeDegrees,
    required this.apparentAltitudeDegrees,
    required this.refractionDegrees,
    required this.azimuthDegrees,
    required this.declinationDegrees,
    required this.rightAscensionDegrees,
    required this.equationOfTimeMinutes,
    required this.hourAngleDegrees,
    required this.deltaTSeconds,
  });

  /// زاوية سمت البعد عن السمت الرأسي (Zenith Angle)
  double get apparentZenithDegrees => 90.0 - apparentAltitudeDegrees;

  Map<String, dynamic> toJson() => {
    'instantUtc': instant.toIso8601String(),
    'trueAltitudeDegrees': trueAltitudeDegrees,
    'apparentAltitudeDegrees': apparentAltitudeDegrees,
    'refractionDegrees': refractionDegrees,
    'azimuthDegrees': azimuthDegrees,
    'declinationDegrees': declinationDegrees,
    'rightAscensionDegrees': rightAscensionDegrees,
    'equationOfTimeMinutes': equationOfTimeMinutes,
    'hourAngleDegrees': hourAngleDegrees,
    'deltaTSeconds': deltaTSeconds,
  };
}

/// فترات النهي والكراهة الثلاث للصلاة خلال اليوم الفلكي
class ProhibitedTimesWindow {
  /// 1. من شروق الشمس حتى ترتفع قيد رمح (+3.5° فوق الأفق)
  final DateTime postSunriseStart;
  final DateTime postSunriseEnd;
  final DateTime? postSunriseStartUtc;
  final DateTime? postSunriseEndUtc;

  /// 2. وقت الاستواء (قائم الظهيرة: قبل الزوال حتى دخول وقت الظهر)
  final DateTime solarNoonZenithStart;
  final DateTime solarNoonZenithEnd;
  final DateTime? solarNoonZenithStartUtc;
  final DateTime? solarNoonZenithEndUtc;

  /// 3. وقت الاصفرار والغروب (من انخفاض الشمس لزاوية +3.5° حتى تمام الغروب)
  final DateTime preSunsetStart;
  final DateTime preSunsetEnd;
  final DateTime? preSunsetStartUtc;
  final DateTime? preSunsetEndUtc;

  const ProhibitedTimesWindow({
    required this.postSunriseStart,
    required this.postSunriseEnd,
    this.postSunriseStartUtc,
    this.postSunriseEndUtc,
    required this.solarNoonZenithStart,
    required this.solarNoonZenithEnd,
    this.solarNoonZenithStartUtc,
    this.solarNoonZenithEndUtc,
    required this.preSunsetStart,
    required this.preSunsetEnd,
    this.preSunsetStartUtc,
    this.preSunsetEndUtc,
  });

  /// التحقق مما إذا كانت اللحظة المعطاة تقع داخل أي من أوقات النهي الثلاثة
  bool isInstantProhibited(DateTime instant, {DateTime? instantUtc}) {
    if (instantUtc != null &&
        postSunriseStartUtc != null &&
        postSunriseEndUtc != null &&
        solarNoonZenithStartUtc != null &&
        solarNoonZenithEndUtc != null &&
        preSunsetStartUtc != null &&
        preSunsetEndUtc != null) {
      return (!instantUtc.isBefore(postSunriseStartUtc!) &&
              instantUtc.isBefore(postSunriseEndUtc!)) ||
          (!instantUtc.isBefore(solarNoonZenithStartUtc!) &&
              instantUtc.isBefore(solarNoonZenithEndUtc!)) ||
          (!instantUtc.isBefore(preSunsetStartUtc!) &&
              instantUtc.isBefore(preSunsetEndUtc!));
    }

    return (!instant.isBefore(postSunriseStart) &&
            instant.isBefore(postSunriseEnd)) ||
        (!instant.isBefore(solarNoonZenithStart) &&
            instant.isBefore(solarNoonZenithEnd)) ||
        (!instant.isBefore(preSunsetStart) && instant.isBefore(preSunsetEnd));
  }

  Map<String, dynamic> toJson() => {
    'postSunriseStart': postSunriseStart.toIso8601String(),
    'postSunriseEnd': postSunriseEnd.toIso8601String(),
    'solarNoonZenithStart': solarNoonZenithStart.toIso8601String(),
    'solarNoonZenithEnd': solarNoonZenithEnd.toIso8601String(),
    'preSunsetStart': preSunsetStart.toIso8601String(),
    'preSunsetEnd': preSunsetEnd.toIso8601String(),
  };
}

class SolarEphemerisCalculator {
  static const double _degToRad = math.pi / 180.0;
  static const double _radToDeg = 180.0 / math.pi;

  static double _normalizeDegrees(double angle) {
    final mod = angle % 360.0;
    return mod < 0 ? mod + 360.0 : mod;
  }

  /// حساب لحظة الزوال الشمسي الحقيقي (True Solar Transit / Noon) بدقة أجزاء الثانية عبر التكرار المتتالي
  static InstantUtc solveSolarTransitUtc({
    required double latitude,
    required double longitude,
    required DateTime civilDateUtc,
  }) {
    // التقدير الأولي للزوال بناءً على خط الطول
    DateTime estimate = DateTime.utc(
      civilDateUtc.year,
      civilDateUtc.month,
      civilDateUtc.day,
      12,
      0,
    ).subtract(Duration(seconds: (longitude / 15.0 * 3600.0).round()));

    // خطوتا تكرار (Two-Pass Refinement) لتصحيح معادلة الزمن وزاوية الساعة عند لحظة الزوال ذاتها
    for (int pass = 0; pass < 2; pass++) {
      final pos = evaluateSolarPosition(
        instant: InstantUtc.fromDateTime(estimate),
        latitude: latitude,
        longitude: longitude,
      );
      final correctionSeconds = (pos.hourAngleDegrees / 15.0) * 3600.0;
      estimate = estimate.subtract(
        Duration(microseconds: (correctionSeconds * 1000000).round()),
      );
    }
    return InstantUtc.fromDateTime(estimate);
  }

  /// حساب اللحظة الكونية الدقيقة لعبور مركز الشمس زاوية ارتفاع معينة (صباحاً أو مساءً) بتكرار نيوتن-رافسون
  static InstantUtc? solveSolarAltitudeCrossingUtc({
    required double latitude,
    required double longitude,
    required DateTime civilDateUtc,
    required double targetTrueAltitudeDegrees,
    required bool isMorning,
  }) {
    final transit = solveSolarTransitUtc(
      latitude: latitude,
      longitude: longitude,
      civilDateUtc: civilDateUtc,
    );
    final double latRad = latitude.clamp(-89.9, 89.9) * _degToRad;
    final double targetRad = targetTrueAltitudeDegrees * _degToRad;

    InstantUtc currentGuess = transit;

    for (int pass = 0; pass < 3; pass++) {
      final pos = evaluateSolarPosition(
        instant: currentGuess,
        latitude: latitude,
        longitude: longitude,
      );
      final double decRad = pos.declinationDegrees * _degToRad;
      final double denom = math.cos(latRad) * math.cos(decRad);
      if (denom.abs() < 1e-6) return null;

      final double cosH =
          (math.sin(targetRad) - math.sin(latRad) * math.sin(decRad)) / denom;
      if (cosH < -1.0 || cosH > 1.0) {
        return null; // الشمس لا تبلغ هذه الزاوية في هذا اليوم (منطقة قطبية)
      }

      final double hourAngleDeg = math.acos(cosH) * _radToDeg;
      final Duration offsetFromTransit = Duration(
        microseconds: ((hourAngleDeg / 15.0) * 3600.0 * 1000000).round(),
      );

      currentGuess = isMorning
          ? transit.subtract(offsetFromTransit)
          : transit.add(offsetFromTransit);
    }

    return currentGuess;
  }

  /// حساب الفرق بين الزمن الديناميكي الأرضي والزمن العالمي (Delta T = TT - UT1) بالثواني
  /// باستخدام متعددات حدود إسبيناك وميوس (Espenak & Meeus NASA Polynomials) عبر القرون
  static double computeDeltaTSeconds(int year, int month) {
    final double y = year + ((month - 0.5) / 12.0);

    if (y < 948.0) {
      final double u = (y - 1000.0) / 100.0;
      return 2177.0 + 497.0 * u + 44.1 * u * u;
    } else if (y < 1600.0) {
      final double u = (y - 1000.0) / 100.0;
      return 102.0 + 102.0 * u + 25.3 * u * u;
    } else if (y < 1900.0) {
      final double t = (y - 1600.0) / 100.0;
      return 120.0 - 98.08 * t - 153.2 * t * t + (t * t * t) / 0.007129;
    } else if (y < 1986.0) {
      final double t = y - 1900.0;
      return -2.79 + 0.8972 * t;
    } else if (y < 2005.0) {
      final double t = y - 2000.0;
      return 63.86 +
          0.3345 * t -
          0.060374 * t * t +
          0.0017275 * t * t * t +
          0.000651814 * t * t * t * t +
          0.00002373599 * math.pow(t, 5);
    } else if (y < 2050.0) {
      final double t = y - 2000.0;
      return 62.92 + 0.32217 * t + 0.005589 * t * t;
    } else if (y < 2150.0) {
      final double u = (y - 1820.0) / 100.0;
      return -20.0 + 32.0 * u * u - 0.5628 * (2150.0 - y);
    } else {
      final double u = (y - 1820.0) / 100.0;
      return -20.0 + 32.0 * u * u;
    }
  }

  /// تحويل اللحظة الكونية إلى اليوم اليولياني (Julian Ephemeris Day)
  static ({double jdUt, double jdeTt, double deltaTSeconds}) computeJulianDay(
    InstantUtc instant,
  ) {
    final dt = instant.toDateTimeUtc();
    final double jdUt =
        (instant.epochMicroseconds / 86400000000.0) + 2440587.5;
    final double deltaT = computeDeltaTSeconds(dt.year, dt.month);
    final double jdeTt = jdUt + (deltaT / 86400.0);
    return (jdUt: jdUt, jdeTt: jdeTt, deltaTSeconds: deltaT);
  }

  /// حساب الانكسار الجوي بالدرجات القوسية وفق معادلة Saemundsson-Bennett المصححة بالحرارة والضغط
  static double computeAtmosphericRefractionDegrees({
    required double trueAltitudeDegrees,
    AtmosphericConditions conditions = const AtmosphericConditions(),
  }) {
    if (trueAltitudeDegrees < -2.0 || trueAltitudeDegrees >= 89.9) {
      return 0.0;
    }
    final double h = trueAltitudeDegrees.clamp(-1.5, 89.9);
    final double tanArg = (h + (10.3 / (h + 5.11))) * _degToRad;
    final double rArcMinutes = 1.02 / math.tan(tanArg);
    final double ptFactor =
        (conditions.pressureHpa / 1010.0) *
        (283.15 /
            (273.15 + conditions.temperatureCelsius.clamp(-60.0, 60.0)));
    return math.max(0.0, (rArcMinutes * ptFactor) / 60.0);
  }

  /// حساب الموقع اللحظي الدقيق للشمس (Jean Meeus Chapter 25 High-Precision Solar Coordinates)
  static SolarPosition evaluateSolarPosition({
    required InstantUtc instant,
    required double latitude,
    required double longitude,
    AtmosphericConditions conditions = const AtmosphericConditions(),
  }) {
    final jdData = computeJulianDay(instant);
    final double t = (jdData.jdeTt - 2451545.0) / 36525.0;
    final double tUt = (jdData.jdUt - 2451545.0) / 36525.0;

    // الطول الهندسي المتوسط للشمس (L0) والزاوية المتوسطة (M)
    final double l0 = _normalizeDegrees(
      280.46646 + 36000.76983 * t + 0.0003032 * t * t,
    );
    final double m = _normalizeDegrees(
      357.52911 + 35999.05029 * t - 0.0001537 * t * t,
    );
    final double e = 0.016708634 - 0.000042037 * t - 0.0000001267 * t * t;

    final double mRad = m * _degToRad;
    final double c =
        (1.914602 - 0.004817 * t - 0.000014 * t * t) * math.sin(mRad) +
        (0.019993 - 0.000101 * t) * math.sin(2.0 * mRad) +
        0.000289 * math.sin(3.0 * mRad);

    final double sunTrueLong = l0 + c;
    final double omega = 125.04 - 1934.136 * t;
    final double lambda =
        sunTrueLong - 0.00569 - 0.00478 * math.sin(omega * _degToRad);

    // ميل دائرة البروج الظاهري (Obliquity of the Ecliptic)
    final double epsilon0 =
        23.0 +
        (26.0 / 60.0) +
        (21.448 / 3600.0) -
        (46.8150 / 3600.0) * t -
        (0.00059 / 3600.0) * t * t +
        (0.001813 / 3600.0) * t * t * t;
    final double epsilon = epsilon0 + 0.00256 * math.cos(omega * _degToRad);

    final double lambdaRad = lambda * _degToRad;
    final double epsRad = epsilon * _degToRad;

    // المطلع المستقيم (Right Ascension) والميل الاستوائي (Declination)
    final double alpha = _normalizeDegrees(
      math.atan2(
            math.cos(epsRad) * math.sin(lambdaRad),
            math.cos(lambdaRad),
          ) *
          _radToDeg,
    );
    final double delta =
        math.asin(math.sin(epsRad) * math.sin(lambdaRad)) * _radToDeg;

    // معادلة الزمن الدقيقة (Equation of Time in minutes)
    final double y = math.pow(math.tan(epsRad / 2.0), 2).toDouble();
    final double l0Rad = l0 * _degToRad;
    final double eotRad =
        y * math.sin(2.0 * l0Rad) -
        2.0 * e * math.sin(mRad) +
        4.0 * e * y * math.sin(mRad) * math.cos(2.0 * l0Rad) -
        0.5 * y * y * math.sin(4.0 * l0Rad) -
        1.25 * e * e * math.sin(2.0 * mRad);
    final double eotMinutes = eotRad * _radToDeg * 4.0;

    // الزمن النجمي الظاهري في غرينتش (GAST) وزاوية الساعة المحلية (Hour Angle)
    final double gmst = _normalizeDegrees(
      280.46061837 +
          360.98564736629 * (jdData.jdUt - 2451545.0) +
          0.000387933 * tUt * tUt -
          (tUt * tUt * tUt) / 38710000.0,
    );
    final double gast =
        gmst +
        (-0.00478 * math.sin(omega * _degToRad)) * math.cos(epsRad);

    double hourAngle = _normalizeDegrees(gast + longitude - alpha);
    if (hourAngle > 180.0) hourAngle -= 360.0;

    final double latRad = latitude.clamp(-89.99, 89.99) * _degToRad;
    final double decRad = delta * _degToRad;
    final double haRad = hourAngle * _degToRad;

    // زاوية الارتفاع الحقيقية (True Altitude)
    final double sinAlt =
        math.sin(latRad) * math.sin(decRad) +
        math.cos(latRad) * math.cos(decRad) * math.cos(haRad);
    final double trueAlt = math.asin(sinAlt.clamp(-1.0, 1.0)) * _radToDeg;

    // تصحيح اختلاف المنظر الأفقي للشمس (Solar Horizontal Parallax ~ 8.794 arcsec)
    final double topocentricTrueAlt =
        trueAlt - (0.0024428 * math.cos(trueAlt * _degToRad));

    final double refraction = computeAtmosphericRefractionDegrees(
      trueAltitudeDegrees: topocentricTrueAlt,
      conditions: conditions,
    );
    final double apparentAlt = topocentricTrueAlt + refraction;

    // السمت الشمسي (Azimuth: 0° شمالاً، 90° شرقاً، 180° جنوباً، 270° غرباً)
    final double yAz = math.sin(haRad);
    final double xAz =
        math.cos(haRad) * math.sin(latRad) -
        math.tan(decRad) * math.cos(latRad);
    final double azimuth = _normalizeDegrees(
      (math.atan2(yAz, xAz) * _radToDeg) + 180.0,
    );

    return SolarPosition(
      instant: instant,
      trueAltitudeDegrees: topocentricTrueAlt,
      apparentAltitudeDegrees: apparentAlt,
      refractionDegrees: refraction,
      azimuthDegrees: azimuth,
      declinationDegrees: delta,
      rightAscensionDegrees: alpha,
      equationOfTimeMinutes: eotMinutes,
      hourAngleDegrees: hourAngle,
      deltaTSeconds: jdData.deltaTSeconds,
    );
  }

  /// حساب المدة الفلكية التي تستغرقها الشمس للانتقال بين زاويتي ارتفاع (مثلاً من الأفق -0.833° إلى قيد رمح +3.5°)
  static Duration computeAltitudeCrossingDuration({
    required double latitude,
    required double solarDeclinationDegrees,
    double fromAltitudeDegrees = -0.8333,
    double toAltitudeDegrees = 3.5,
  }) {
    final double latRad = latitude.clamp(-65.0, 65.0) * _degToRad;
    final double decRad = solarDeclinationDegrees * _degToRad;
    final double denom = math.cos(latRad) * math.cos(decRad);

    if (denom.abs() < 1e-5) {
      return const Duration(minutes: 16);
    }

    double cosH(double altDeg) {
      final num =
          math.sin(altDeg * _degToRad) - math.sin(latRad) * math.sin(decRad);
      return (num / denom).clamp(-1.0, 1.0);
    }

    final double h1Deg = math.acos(cosH(fromAltitudeDegrees)) * _radToDeg;
    final double h2Deg = math.acos(cosH(toAltitudeDegrees)) * _radToDeg;
    final double deltaMinutes = ((h1Deg - h2Deg).abs() * 4.0).clamp(
      12.0,
      45.0,
    );

    return Duration(microseconds: (deltaMinutes * 60 * 1000000).round());
  }

  /// حساب أوقات الكراهة والنهي الثلاثة ليوم فلكي كامل بدقة زاوية ارتفاع الشمس
  static ProhibitedTimesWindow calculateProhibitedTimes({
    required double latitude,
    required double longitude,
    required IbadatTimings ibadat,
    Duration? utcOffset,
    double spearAltitudeDegrees = 3.5,
    Duration zenithPreDhuhrLead = const Duration(minutes: 6),
  }) {
    final offset = utcOffset ?? Duration.zero;
    final sunriseUtc = ibadat.sunrise.subtract(offset);
    final dhuhrUtc = ibadat.dhuhr.subtract(offset);
    final sunsetWall = ibadat.calculatedSunset ?? ibadat.maghrib;
    final sunsetUtc = sunsetWall.subtract(offset);

    final noonPos = evaluateSolarPosition(
      instant: InstantUtc.fromDateTime(dhuhrUtc),
      latitude: latitude,
      longitude: longitude,
    );

    final spearDuration = computeAltitudeCrossingDuration(
      latitude: latitude,
      solarDeclinationDegrees: noonPos.declinationDegrees,
      fromAltitudeDegrees: -0.8333,
      toAltitudeDegrees: spearAltitudeDegrees,
    );

    final postSunriseEndWall = ibadat.sunrise.add(spearDuration);
    final postSunriseEndUtc = sunriseUtc.add(spearDuration);

    final zenithStartWall = ibadat.dhuhr.subtract(zenithPreDhuhrLead);
    final zenithStartUtc = dhuhrUtc.subtract(zenithPreDhuhrLead);

    final preSunsetStartWall = sunsetWall.subtract(spearDuration);
    final preSunsetStartUtc = sunsetUtc.subtract(spearDuration);

    return ProhibitedTimesWindow(
      postSunriseStart: ibadat.sunrise,
      postSunriseEnd: postSunriseEndWall,
      postSunriseStartUtc: sunriseUtc,
      postSunriseEndUtc: postSunriseEndUtc,
      solarNoonZenithStart: zenithStartWall,
      solarNoonZenithEnd: ibadat.dhuhr,
      solarNoonZenithStartUtc: zenithStartUtc,
      solarNoonZenithEndUtc: dhuhrUtc,
      preSunsetStart: preSunsetStartWall,
      preSunsetEnd: sunsetWall,
      preSunsetStartUtc: preSunsetStartUtc,
      preSunsetEndUtc: sunsetUtc,
    );
  }
}