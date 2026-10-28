import '../models/astro_models.dart';

class AstroDefaults {
  final CalculationMethodType methodType;
  final MadhabType madhabType;
  final HighLatitudeRuleType highLatitudeRuleType;

  /// المعرفات النصية المتوافقة 100% مع SettingsModel في طبقة التطبيق
  final String method;
  final String madhab;
  final String highLatitudeRule;

  const AstroDefaults({
    required this.methodType,
    required this.madhabType,
    required this.highLatitudeRuleType,
    required this.method,
    required this.madhab,
    required this.highLatitudeRule,
  });
}

class AstroSmartDefaults {
  static AstroDefaults getDefaultsForCountry(String? countryCode) {
    if (countryCode == null ||
        countryCode.isEmpty ||
        countryCode == 'CUSTOM' ||
        countryCode == 'XX') {
      return const AstroDefaults(
        methodType: CalculationMethodType.muslimWorldLeague,
        madhabType: MadhabType.shafi,
        highLatitudeRuleType: HighLatitudeRuleType.middleOfTheNight,
        method: 'muslim_world_league',
        madhab: 'shafi',
        highLatitudeRule: 'middle_of_the_night',
      );
    }

    CalculationMethodType methodType = CalculationMethodType.muslimWorldLeague;
    MadhabType madhabType = MadhabType.shafi;
    HighLatitudeRuleType highLatType = HighLatitudeRuleType.middleOfTheNight;
    String methodStr = 'muslim_world_league';
    String madhabStr = 'shafi';
    String highLatStr = 'middle_of_the_night';

    switch (countryCode.trim().toUpperCase()) {
      // مصر، السودان، جنوب السودان، ليبيا، سوريا، لبنان، فلسطين
      case 'EG':
      case 'SD':
      case 'SS':
      case 'LY':
      case 'SY':
      case 'LB':
      case 'PS':
        methodType = CalculationMethodType.egyptian;
        methodStr = 'egyptian';
        break;

      // الأردن
      case 'JO':
        methodType = CalculationMethodType.jordan;
        methodStr = 'jordan';
        break;

      // المغرب، الجزائر، تونس
      case 'MA':
      case 'EH':
        methodType = CalculationMethodType.morocco;
        methodStr = 'morocco';
        break;
      case 'DZ':
        methodType = CalculationMethodType.algeria;
        methodStr = 'algeria';
        break;
      case 'TN':
        methodType = CalculationMethodType.tunisia;
        methodStr = 'tunisia';
        break;

      // الجزيرة العربية والخليج
      case 'SA':
      case 'YE':
      case 'BH':
        methodType = CalculationMethodType.ummAlQura;
        methodStr = 'ummAlQura';
        break;
      case 'OM':
        methodType = CalculationMethodType.oman;
        methodStr = 'oman';
        break;
      case 'AE':
        methodType = CalculationMethodType.dubai;
        methodStr = 'dubai';
        break;
      case 'QA':
        methodType = CalculationMethodType.qatar;
        methodStr = 'qatar';
        break;
      case 'KW':
        methodType = CalculationMethodType.kuwait;
        methodStr = 'kuwait';
        break;

      // العراق وإيران
      case 'IR':
      case 'IQ':
        methodType = CalculationMethodType.tehran;
        methodStr = 'tehran';
        break;

      // شبه القارة الهندية وجنوب آسيا
      case 'PK':
      case 'AF':
      case 'BD':
      case 'IN':
      case 'LK':
      case 'MV':
      case 'NP':
        methodType = CalculationMethodType.karachi;
        madhabType = MadhabType.hanafi;
        methodStr = 'karachi';
        madhabStr = 'hanafi';
        break;

      // جنوب شرق آسيا
      case 'MY':
      case 'BN':
        methodType = CalculationMethodType.malaysiaJakim;
        methodStr = 'malaysia_jakim';
        break;
      case 'ID':
        methodType = CalculationMethodType.indonesiaKemenag;
        methodStr = 'indonesia_kemenag';
        break;
      case 'SG':
      case 'TH':
      case 'PH':
        methodType = CalculationMethodType.singapore;
        methodStr = 'singapore';
        break;

      // تركيا، القوقاز، آسيا الوسطى، والبلقان
      case 'TR':
      case 'AZ':
      case 'TM':
      case 'UZ':
      case 'KG':
      case 'TJ':
      case 'BA':
      case 'AL':
      case 'XK':
      case 'MK':
        methodType = CalculationMethodType.turkey;
        madhabType = MadhabType.hanafi;
        methodStr = 'turkey';
        madhabStr = 'hanafi';
        break;
      case 'KZ':
        methodType = CalculationMethodType.turkey;
        madhabType = MadhabType.hanafi;
        highLatType = HighLatitudeRuleType.seventhOfTheNight;
        methodStr = 'turkey';
        madhabStr = 'hanafi';
        highLatStr = 'seventh_of_the_night';
        break;

      // فرنسا وجنوب غرب أوروبا
      case 'FR':
      case 'BE':
      case 'IT':
      case 'ES':
      case 'PT':
      case 'CH':
      case 'AT':
        methodType = CalculationMethodType.franceUoif;
        methodStr = 'france_uoif';
        if (countryCode.toUpperCase() == 'BE' ||
            countryCode.toUpperCase() == 'CH' ||
            countryCode.toUpperCase() == 'AT') {
          highLatType = HighLatitudeRuleType.seventhOfTheNight;
          highLatStr = 'seventh_of_the_night';
        }
        break;

      // روسيا وشرق أوروبا (عروض عليا)
      case 'RU':
      case 'BY':
      case 'UA':
      case 'MD':
        methodType = CalculationMethodType.russia;
        madhabType = MadhabType.hanafi;
        highLatType = HighLatitudeRuleType.seventhOfTheNight;
        methodStr = 'russia';
        madhabStr = 'hanafi';
        highLatStr = 'seventh_of_the_night';
        break;

      // شمال ووسط أوروبا (عروض عليا بين 48° و56°)
      case 'GB':
      case 'IE':
      case 'DE':
      case 'NL':
      case 'PL':
      case 'CZ':
      case 'SK':
      case 'HU':
      case 'LT':
      case 'LV':
      case 'EE':
        methodType = CalculationMethodType.muslimWorldLeague;
        highLatType = HighLatitudeRuleType.seventhOfTheNight;
        methodStr = 'muslim_world_league';
        highLatStr = 'seventh_of_the_night';
        break;

      // الدول الإسكندنافية والقطبية (> 56°)
      case 'SE':
      case 'NO':
      case 'FI':
      case 'DK':
      case 'IS':
      case 'GL':
        methodType = CalculationMethodType.muslimWorldLeague;
        highLatType = HighLatitudeRuleType.twilightAngle;
        methodStr = 'muslim_world_league';
        highLatStr = 'twilight_angle';
        break;

      // أمريكا الشمالية
      case 'US':
      case 'CA':
        methodType = CalculationMethodType.northAmerica;
        methodStr = 'north_america';
        if (countryCode.toUpperCase() == 'CA') {
          highLatType = HighLatitudeRuleType.seventhOfTheNight;
          highLatStr = 'seventh_of_the_night';
        }
        break;
    }

    return AstroDefaults(
      methodType: methodType,
      madhabType: madhabType,
      highLatitudeRuleType: highLatType,
      method: methodStr,
      madhab: madhabStr,
      highLatitudeRule: highLatStr,
    );
  }
}
