import '../engine/temporal_context_engine.dart';

enum IslamicFastingType {
  obligatoryRamadan,
  arafah,
  ashura,
  tasua,
  whiteDays,
  shawwalSixDaysWindow,
  mondayThursdaySunnah,
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

  factory SeasonalFastingRecommendation.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    return SeasonalFastingRecommendation(
      type: IslamicFastingType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => IslamicFastingType.none,
      ),
      titleKey: (json['titleKey'] as String?) ?? '',
      reasonKey: (json['reasonKey'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      reason: (json['reason'] as String?) ?? '',
      highlightColorHex:
          (json['highlightColorHex'] as num?)?.toInt() ?? 0xFF10B981,
      isFastingForbidden: (json['isFastingForbidden'] as bool?) ?? false,
    );
  }
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

  /// تقييم توصية الصيام الموسمي لأي تاريخ هجري:
  /// - افتراضياً (`includeObligatoryAndForbidden = false`): يُرجع أيام صيام التطوع المؤكدة فقط (عرفة، عاشوراء، تاسوعاء، الأيام البيض) للتوافق التام مع لافتات التقويم الحالية.
  /// - عند تمرير `includeObligatoryAndForbidden: true` (أو استدعاء `evaluateCompleteDayStatus`): يُرجع أيضاً حكم وجوب صوم رمضان، وحرمة صوم العيدين وأيام التشريق، ونافذة الست من شوال، وصيام الاثنين والخميس.
  static SeasonalFastingRecommendation? evaluateFastingForHijri({
    required int hMonth,
    required int hDay,
    String langCode = 'ar',
    String? localizedMonthName,
    bool includeObligatoryAndForbidden = false,
    bool includeShawwalWindow = false,
    int? weekday,
  }) {
    final isAr = langCode.toLowerCase().startsWith('ar');
    final monthName =
        localizedMonthName ??
        (isAr
            ? (_hijriMonthsAr[hMonth] ?? '$hMonth')
            : (_hijriMonthsEn[hMonth] ?? '$hMonth'));

    // 1. أيام يحرم صيامها شرعاً: عيد الفطر (1 شوال)، عيد الأضحى (10 ذو الحجة)، وأيام التشريق (11 و12 و13 ذو الحجة)
    final bool isEidAlFitr = hMonth == 10 && hDay == 1;
    final bool isEidAlAdha = hMonth == 12 && hDay == 10;
    final bool isTashreeq =
        hMonth == 12 && (hDay == 11 || hDay == 12 || hDay == 13);

    if (isEidAlFitr || isEidAlAdha || isTashreeq) {
      if (!includeObligatoryAndForbidden) return null;

      final String forbiddenTitle = isEidAlFitr
          ? (isAr ? 'عيد الفطر المبارك (1 شوال)' : 'Eid al-Fitr (1 Shawwal)')
          : isEidAlAdha
          ? (isAr
                ? 'عيد الأضحى المبارك (10 ذو الحجة)'
                : 'Eid al-Adha (10 Dhu al-Hijjah)')
          : (isAr
                ? 'أيام التشريق ($hDay ذو الحجة)'
                : 'Days of Tashreeq ($hDay Dhu al-Hijjah)');

      final String forbiddenReason = isTashreeq
          ? (isAr
                ? 'أيام التشريق أيام أكل وشرب وذكر لله، ويحرم صيامها تطوعاً.'
                : 'Days of Tashreeq are days of eating, drinking, and remembrance of Allah; voluntary fasting is prohibited.')
          : (isAr
                ? 'يوم عيد للمسلمين يحرم صيامه بإجماع العلماء.'
                : 'Fasting on the day of Eid is strictly prohibited.');

      return SeasonalFastingRecommendation(
        type: IslamicFastingType.forbiddenEidOrTashreeq,
        titleKey: 'fasting.forbidden_eid_tashreeq_title',
        reasonKey: 'fasting.forbidden_eid_tashreeq_reason',
        title: forbiddenTitle,
        reason: forbiddenReason,
        highlightColorHex: 0xFFEF4444,
        isFastingForbidden: true,
      );
    }

    // 2. شهر رمضان المبارك (فرض عين)
    if (hMonth == 9) {
      if (!includeObligatoryAndForbidden) return null;
      return SeasonalFastingRecommendation(
        type: IslamicFastingType.obligatoryRamadan,
        titleKey: 'fasting.ramadan_title',
        reasonKey: 'fasting.ramadan_reason',
        title: isAr
            ? 'صيام شهر رمضان ($hDay $monthName)'
            : 'Ramadan Obligatory Fast ($hDay $monthName)',
        reason: isAr
            ? 'صوم شهر رمضان المبارك ركن من أركان الإسلام الخمسة.'
            : 'Fasting the month of Ramadan is an obligatory pillar of Islam.',
        highlightColorHex: 0xFFD4AF37,
      );
    }

    // 3. يوم عرفة (9 ذو الحجة)
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

    // 4. يوم عاشوراء (10 محرم) وتاسوعاء (9 محرم)
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

    // 5. الأيام البيض (13 و14 و15 من كل شهر هجري، وقد استُثني أعلاه رمضان و13 ذو الحجة)
    if (hDay == 13 || hDay == 14 || hDay == 15) {
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

    // 6. نافذة صيام الست من شوال (من 2 إلى 30 شوال) عند تفعيلها
    if (includeShawwalWindow && hMonth == 10 && hDay >= 2) {
      return SeasonalFastingRecommendation(
        type: IslamicFastingType.shawwalSixDaysWindow,
        titleKey: 'fasting.shawwal_six_title',
        reasonKey: 'fasting.shawwal_six_reason',
        title: isAr ? 'موسم صيام الست من شوال' : 'Six Days of Shawwal Window',
        reason: isAr
            ? 'من صام رمضان ثم أتبعه ستاً من شوال كان كصيام الدهر.'
            : 'Fasting Ramadan followed by six days of Shawwal is like fasting the entire year.',
      );
    }

    // 7. سنة صيام الاثنين والخميس (عند تمرير weekday: 1 للاثنين أو 4 للخميس)
    if (weekday == 1 || weekday == 4) {
      final isMonday = weekday == 1;
      return SeasonalFastingRecommendation(
        type: IslamicFastingType.mondayThursdaySunnah,
        titleKey: 'fasting.monday_thursday_title',
        reasonKey: 'fasting.monday_thursday_reason',
        title: isAr
            ? (isMonday ? 'سنة صيام يوم الاثنين' : 'سنة صيام يوم الخميس')
            : (isMonday ? 'Sunnah Monday Fast' : 'Sunnah Thursday Fast'),
        reason: isAr
            ? 'تُعرض الأعمال يومي الاثنين والخميس، ويُستحب الصيام فيهما.'
            : 'Deeds are presented on Mondays and Thursdays; fasting on them is Sunnah.',
      );
    }

    return null;
  }

  /// تقييم شامل لحالة اليوم (يشمل الفرض، والتحريم، والست من شوال، والاثنين والخميس) للـ APIs والتقويم المتقدم
  static SeasonalFastingRecommendation? evaluateCompleteDayStatus({
    required int hMonth,
    required int hDay,
    int? weekday,
    String langCode = 'ar',
    String? localizedMonthName,
  }) {
    return evaluateFastingForHijri(
      hMonth: hMonth,
      hDay: hDay,
      langCode: langCode,
      localizedMonthName: localizedMonthName,
      includeObligatoryAndForbidden: true,
      includeShawwalWindow: true,
      weekday: weekday,
    );
  }

  static SeasonalFastingRecommendation? evaluateForHijriDate(
    HijriDate hijriDate, {
    String langCode = 'ar',
    String? localizedMonthName,
    bool includeObligatoryAndForbidden = false,
    bool includeShawwalWindow = false,
    int? weekday,
  }) {
    return evaluateFastingForHijri(
      hMonth: hijriDate.month,
      hDay: hijriDate.day,
      langCode: langCode,
      localizedMonthName: localizedMonthName,
      includeObligatoryAndForbidden: includeObligatoryAndForbidden,
      includeShawwalWindow: includeShawwalWindow,
      weekday: weekday,
    );
  }
}
