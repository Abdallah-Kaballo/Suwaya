import '../engine/temporal_context_engine.dart';

enum IslamicFastingType {
  obligatoryRamadan,
  arafah,
  ashura,
  tasua,
  whiteDays,
  shawwalSixDaysWindow,
  forbiddenEidOrTashreeq,
  none,
}

class SeasonalFastingRecommendation {
  final IslamicFastingType type;
  final String titleKey;
  final String reasonKey;
  final String title;
  final String reason;
  final int highlightColorHex;
  final bool isFastingForbidden;

  const SeasonalFastingRecommendation({
    required this.type,
    required this.titleKey,
    required this.reasonKey,
    required this.title,
    required this.reason,
    this.highlightColorHex = 0xFF10B981,
    this.isFastingForbidden = false,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'titleKey': titleKey,
    'reasonKey': reasonKey,
    'title': title,
    'reason': reason,
    'highlightColorHex': highlightColorHex,
    'isFastingForbidden': isFastingForbidden,
  };
}

class IslamicEventsCatalog {
  static const Map<int, String> _hijriMonthsAr = {
    1: 'محرم',
    2: 'صفر',
    3: 'ربيع الأول',
    4: 'ربيع الآخر',
    5: 'جمادى الأولى',
    6: 'جمادى الآخرة',
    7: 'رجب',
    8: 'شعبان',
    9: 'رمضان',
    10: 'شوال',
    11: 'ذو القعدة',
    12: 'ذو الحجة',
  };

  static const Map<int, String> _hijriMonthsEn = {
    1: 'Muharram',
    2: 'Safar',
    3: 'Rabi\' al-Awwal',
    4: 'Rabi\' al-Thani',
    5: 'Jumada al-Awwal',
    6: 'Jumada al-Thani',
    7: 'Rajab',
    8: 'Sha\'ban',
    9: 'Ramadan',
    10: 'Shawwal',
    11: 'Dhu al-Qi\'dah',
    12: 'Dhu al-Hijjah',
  };

  /// تقييم توصية الصيام الموسمي لأي تاريخ هجري (يدعم استثناء أيام التشريق ورمضان بدقة فقهية)
  static SeasonalFastingRecommendation? evaluateFastingForHijri({
    required int hMonth,
    required int hDay,
    String langCode = 'ar',
    String? localizedMonthName,
  }) {
    final isAr = langCode.toLowerCase().startsWith('ar');
    final monthName =
        localizedMonthName ??
        (isAr
            ? (_hijriMonthsAr[hMonth] ?? '$hMonth')
            : (_hijriMonthsEn[hMonth] ?? '$hMonth'));

    // 1. يوم عرفة (9 ذو الحجة)
    if (hMonth == 12 && hDay == 9) {
      return SeasonalFastingRecommendation(
        type: IslamicFastingType.arafah,
        titleKey: 'fasting.arafah_title',
        reasonKey: 'fasting.arafah_reason',
        title: isAr
            ? 'صيام يوم عرفة (9 ذو الحجة)'
            : 'Fasting Day of Arafah (9 Dhu al-Hijjah)',
        reason: isAr
            ? 'يُستحب صيامه لغير الحاج؛ يكفّر السنة الماضية والباقية.'
            : 'Recommended for non-pilgrims; expiates sins of the previous and coming year.',
      );
    }

    // 2. يوم عاشوراء (10 محرم) وتاسوعاء (9 محرم)
    if (hMonth == 1 && hDay == 10) {
      return SeasonalFastingRecommendation(
        type: IslamicFastingType.ashura,
        titleKey: 'fasting.ashura_title',
        reasonKey: 'fasting.ashura_reason',
        title: isAr
            ? 'صيام يوم عاشوراء (10 محرم)'
            : 'Fasting Day of Ashura (10 Muharram)',
        reason: isAr
            ? 'صيام يوم عاشوراء يكفّر السنة التي قبله.'
            : 'Recommended fast; expiates the sins of the preceding year.',
      );
    }

    if (hMonth == 1 && hDay == 9) {
      return SeasonalFastingRecommendation(
        type: IslamicFastingType.tasua,
        titleKey: 'fasting.tasua_title',
        reasonKey: 'fasting.tasua_reason',
        title: isAr
            ? 'صيام يوم تاسوعاء (9 محرم)'
            : 'Fasting Tasu\'a (9 Muharram)',
        reason: isAr
            ? 'يُستحب صيامه مع يوم عاشوراء.'
            : 'Recommended to fast along with the Day of Ashura.',
      );
    }

    // 3. الأيام البيض (13 و 14 و 15 من كل شهر هجري، باستثناء 13 ذي الحجة لأنه من أيام التشريق، واستثناء شهر رمضان)
    if (hMonth != 9 && (hDay == 13 || hDay == 14 || hDay == 15)) {
      if (hMonth == 12 && hDay == 13) {
        return null; // 13 ذو الحجة ثالث أيام التشريق ولا يُصام تطوعاً
      }
      return SeasonalFastingRecommendation(
        type: IslamicFastingType.whiteDays,
        titleKey: 'fasting.white_days_title',
        reasonKey: 'fasting.white_days_reason',
        title: isAr
            ? 'من الأيام البيض ($hDay $monthName)'
            : 'White Days Fast ($hDay $monthName)',
        reason: isAr
            ? 'يُندب صيام الأيام البيض (13 و14 و15) من كل شهر هجري، وصيامها كصيام الدهر.'
            : 'Recommended monthly fast on the 13th, 14th, and 15th of the Hijri month.',
      );
    }

    return null;
  }

  static SeasonalFastingRecommendation? evaluateForHijriDate(
    HijriDate hijriDate, {
    String langCode = 'ar',
    String? localizedMonthName,
  }) {
    return evaluateFastingForHijri(
      hMonth: hijriDate.month,
      hDay: hijriDate.day,
      langCode: langCode,
      localizedMonthName: localizedMonthName,
    );
  }
}
