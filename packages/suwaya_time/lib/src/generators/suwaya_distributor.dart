import '../models/astro_models.dart';

/// التصنيف الفلكي والفقهي لمناطق خطوط العرض حسب قرارات المجمع الفقهي الإسلامي (9/6 و 19/2)
enum SuwayaLatitudeZone {
  /// المنطقة الطبيعية والمدارية والمعتدلة: 0.00° <= |lat| < 45.00°
  normalTemperate,

  /// المنطقة الأولى في العروض العليا: 45.00° <= |lat| <= 48.56°
  /// تتمايز فيها العلامات الفلكية كلها في 24 ساعة، وتأخذ التوزيع السنوي الثابت
  highLatZone1Canonical,

  /// المنطقة الثانية في العروض العليا: 48.56° < |lat| <= 66.56°
  /// ينعدم فيها غياب الشفق في بعض ليالي الصيف ويتفاوت فيها الليل والنهار، وتأخذ نظام التقسيمتين السنويتين
  highLatZone2BiAnnual,

  /// المنطقة الثالثة القطبية: |lat| > 66.56° (إلى 90.00°)
  /// ينعدم فيها الشروق والغروب لأيام أو شهور، وتُقاس مواقيتها على خط 45.00° وتأخذ التوزيع السنوي الثابت
  highLatZone3PolarProjected,
}

/// الموسم الفلكي نصف السنوي (يفصل بينهما الاعتدالان الربيعي والخريفي)
enum SuwayaHalfYearSeason {
  /// النصف الصيفي (من الاعتدال الربيعي إلى الاعتدال الخريفي شمالاً، وعكسه جنوباً: النهار >= الليل)
  summerHalfYear,

  /// النصف الشتوي (من الاعتدال الخريفي إلى الاعتدال الربيعي شمالاً، وعكسه جنوباً: النهار < الليل)
  winterHalfYear,
}

class SuwayaDistributor {
  // ===========================================================================
  // الثوابت الفلكية والفقهية الدقيقة لحدود دوائر العرض (بالدرجات العشرية)
  // ===========================================================================

  /// ميل دائرة البروج الأعظم للشمس في الحقبة الحالية (23° 26' 10" ≈ 23.44°)
  static const double eclipticObliquityDegrees = 23.44;

  /// انخفاض الشروق والغروب الظاهري (50' دقيقة قوسية = 34' انكسار جوي + 16' نصف قطر الشمس)
  static const double horizonDepressionDegrees = 0.8333;

  /// خط العرض المرجعي للقياس النسبي والزمني في قرارات المجمع الفقهي الإسلامي (45° 00' 00")
  static const double temperateReferenceLatitude = 45.00;

  /// بداية المنطقة الأولى للعروض العليا (45° 00' 00")
  static const double zone1StartLatitude = 45.00;

  /// بداية المنطقة الثانية فلكياً: أقصى خط عرض يغيب فيه الشفق الفلكي (18°) في الانقلاب الصيفي
  /// 90.00° - 23.44° - 18.00° = 48.56° (48° 33' 36") — ويقابله 48° في التقريب الفقهي
  static const double zone2TwilightLimitLatitude = 48.56;

  /// الحد الفقهي التقريبي لبداية المنطقة الثانية المذكور في نص قرار المجمع (48.00°)
  static const double fiqhZone2NominalLatitude = 48.00;

  /// خط العرض الذي تلامس فيه الحافة العليا للشمس الأفق دون غروب في الانقلاب الصيفي
  /// 90.00° - 23.44° - 0.8333° = 65.7267° ≈ 65.73° (65° 43' 48")
  static const double apparentMidnightSunLatitude = 65.73;

  /// الدائرة القطبية الفلكية (بداية المنطقة الثالثة): 90.00° - 23.44° = 66.56° (66° 33' 36")
  /// ويقابلها 66.00° في التقريب الفقهي لقرار المجمع
  static const double zone3PolarCircleLatitude = 66.56;

  // ===========================================================================
  // جداول التوزيع المعيارية المعتمدة (مجموع الليل = 12 سويعة، مجموع النهار = 12 سويعة)
  // ===========================================================================

  /// 1. التوزيع السنوي الثابت للمنطقة الطبيعية والأولى (<= 48.56°) والمنطقة الثالثة (> 66.56°)
  static const List<int> _jumhurCanonical = [1, 4, 6, 1, 6, 3, 3];
  static const List<int> _hanafiCanonical = [1, 4, 6, 1, 6, 4, 2];

  /// 2. التقسيمة الصيفية للمنطقة الثانية (48.56° < |lat| <= 66.56°) — من الاعتدال الربيعي للخريفي:
  static const List<int> _zone2SummerJumhur = [2, 3, 6, 1, 6, 3, 3];
  static const List<int> _zone2SummerHanafi = [2, 3, 6, 1, 6, 4, 2];

  /// 3. التقسيمة الشتوية للمنطقة الثانية (48.56° < |lat| <= 66.56°) — من الاعتدال الخريفي للربيعي:
  static const List<int> _zone2WinterJumhur = [1, 4, 6, 1, 6, 2, 4];
  static const List<int> _zone2WinterHanafi = [1, 4, 6, 1, 6, 3, 3];

  /// تحديد المنطقة الجغرافية الفلكية لأي خط عرض على سطح الأرض
  static SuwayaLatitudeZone classifyLatitudeZone(double latitude) {
    final absLat = latitude.abs();
    if (absLat < zone1StartLatitude) {
      return SuwayaLatitudeZone.normalTemperate;
    } else if (absLat <= zone2TwilightLimitLatitude) {
      return SuwayaLatitudeZone.highLatZone1Canonical;
    } else if (absLat <= zone3PolarCircleLatitude) {
      return SuwayaLatitudeZone.highLatZone2BiAnnual;
    } else {
      return SuwayaLatitudeZone.highLatZone3PolarProjected;
    }
  }

  /// تحديد الموسم نصف السنوي (الصيفي أو الشتوي) بدقة فلكية عبر مقارنة طول النهار بطول الليل
  /// ينقلب تلقائياً عند لحظة الاعتدال الربيعي والاعتدال الخريفي في كل من نصفي الكرة الشمالي والجنوبي
  static SuwayaHalfYearSeason resolveHalfYearSeason(
    SuwayaCycleAnchors anchors,
  ) {
    final nightMicro = _spanMicro(
      anchors.cycleStartMaghrib,
      anchors.cycleSunrise,
      anchors.cycleStartMaghribUtc,
      anchors.cycleSunriseUtc,
    );
    final dayMicro = _spanMicro(
      anchors.cycleSunrise,
      anchors.cycleEndMaghrib,
      anchors.cycleSunriseUtc,
      anchors.cycleEndMaghribUtc,
    );

    return dayMicro >= nightMicro
        ? SuwayaHalfYearSeason.summerHalfYear
        : SuwayaHalfYearSeason.winterHalfYear;
  }

  /// جلب التوزيع القياسي الثابت بناءً على المذهب
  static List<int> getDistributionForMadhab(MadhabType madhab) {
    return madhab == MadhabType.hanafi ? _hanafiCanonical : _jumhurCanonical;
  }

  /// جلب التوزيع المعياري المعتمد وفق المنطقة الجغرافية والموسم والمذهب
  static List<int> resolveZonalBiAnnualDistribution({
    required double latitude,
    required MadhabType madhab,
    required SuwayaCycleAnchors anchors,
  }) {
    if (!anchors.isValidSequence) {
      return getDistributionForMadhab(madhab);
    }

    final zone = classifyLatitudeZone(latitude);

    // المنطقة الطبيعية (< 45°)، المنطقة الأولى (45°..48.56°)، والمنطقة الثالثة (> 66.56°)
    // تستخدم جميعها التوزيع السنوي الثابت الأصيل
    if (zone != SuwayaLatitudeZone.highLatZone2BiAnnual) {
      return getDistributionForMadhab(madhab);
    }

    // المنطقة الثانية (48.56° < |lat| <= 66.56°): نظام التقسيمتين السنويتين عند الاعتدالين
    final season = resolveHalfYearSeason(anchors);
    if (season == SuwayaHalfYearSeason.summerHalfYear) {
      return madhab == MadhabType.hanafi
          ? _zone2SummerHanafi
          : _zone2SummerJumhur;
    } else {
      return madhab == MadhabType.hanafi
          ? _zone2WinterHanafi
          : _zone2WinterJumhur;
    }
  }

  /// حساب توزيع الـ 24 سويعة على الفترات السبع وفق النظام المعياري الموحد
  static List<int> resolveDistribution({
    required MadhabType madhab,
    required SuwayaCycleAnchors anchors,
    double latitude = 21.4225,
  }) {
    return resolveZonalBiAnnualDistribution(
      latitude: latitude,
      madhab: madhab,
      anchors: anchors,
    );
  }

  static int _spanMicro(
    DateTime startWall,
    DateTime endWall,
    DateTime? startUtc,
    DateTime? endUtc,
  ) {
    final micro = (startUtc != null && endUtc != null)
        ? endUtc.difference(startUtc).inMicroseconds
        : endWall.difference(startWall).inMicroseconds;
    return micro > 0 ? micro : 1;
  }
}
