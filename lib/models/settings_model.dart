import 'package:isar_community/isar.dart';
part 'settings_model.g.dart';

@collection
class SettingsModel {
  Id id = 0;

  bool isFirstLaunch = true;
  String languageCode = 'ar';
  String themeMode = 'dark';

  int streakFreezesAvailable = 3;
  String dayBoundary = 'maghrib';

  String calculationMethod = 'muslim_world_league';
  String madhab = 'shafi';
  String highLatitudeRule = 'middle_of_the_night';
  double customFajrAngle = 18.0;
  double customIshaAngle = 18.0;

  SavedLocation? activeLocation;
  List<SavedLocation> savedLocations = [];

  int currentStreak = 0;
  int longestStreak = 0;
  DateTime? lastStreakDate;

  String timeDisplayMode = 'suwaya';
  // 🌟 الخيار الجديد: 'emoji' (☀️/🌑) أو 'text' (ن/ل - D/N)
  String suwayaIconMode = 'emoji'; 

  bool qiyamAlarmEnabled = false;
  List<int> hiddenPeriods = [];
  bool isDialAutoRotating = true;
  String dialPinMode = 'suwaya24';
  String suwayaNumberStyle = 'english';
  List<String> activeNightMarkers = ['sixth_5'];
  
  List<PeriodConfig> periodConfigs = [];

  bool useAstroTimeForIbadat = true;
  String civilTimeFormat = 'system';
  bool showSunrise = true;
  List<String> visibleNightParts = ['sixth_5'];

  int defaultTaskAlertLevel = 1;
  String defaultTaskTone = 'assets/audio/default.mp3';
  double defaultTaskVolume = 1.0;

  int defaultHabitAlertLevel = 2;
  String defaultHabitTone = 'assets/audio/default.mp3';
  double defaultHabitVolume = 1.0;

  int snoozeDurationMinutes = 10;
  int maxSnoozeCount = 3;

  /// 🌟 توحيد معرفات الصلوات بين الشاشات والمحرك الخلفي
  static String normalizePeriodId(String pId) {
    switch (pId.toLowerCase().trim()) {
      case '1':
      case 'fajr':
      case 'period_fajr':
        return 'fajr';
      case '3':
      case 'dhuhr':
      case 'period_dhuhr':
        return 'dhuhr';
      case '4':
      case 'asr':
      case 'period_asr':
        return 'asr';
      case '5':
      case 'maghrib':
      case 'period_maghrib':
        return 'maghrib';
      case '9':
      case 'isha':
      case 'prayer_isha':
        return 'isha';
      default:
        return pId;
    }
  }

  static List<String> _aliasesFor(String pId) {
    final norm = normalizePeriodId(pId);
    switch (norm) {
      case 'fajr':
        return const ['fajr', '1'];
      case 'dhuhr':
        return const ['dhuhr', '3'];
      case 'asr':
        return const ['asr', '4'];
      case 'maghrib':
        return const ['maghrib', '5'];
      case 'isha':
        return const ['isha', '9'];
      default:
        return [pId];
    }
  }

  static bool _isMandatoryPrayer(String pId) {
    final norm = normalizePeriodId(pId);
    return norm == 'fajr' ||
        norm == 'dhuhr' ||
        norm == 'asr' ||
        norm == 'maghrib' ||
        norm == 'isha';
  }

  PeriodConfig? _getConfig(String pId) {
    final aliases = _aliasesFor(pId);
    for (final c in periodConfigs) {
      if (c.periodId != null && aliases.contains(c.periodId)) {
        return c;
      }
    }
    return null;
  }

  bool isPeriodEnabled(String pId, {bool defaultVal = true}) {
    final smartDefault = (pId == 'sunrise' ||
            pId.startsWith('half') ||
            pId.startsWith('third') ||
            pId.startsWith('sixth'))
        ? false
        : defaultVal;
    return _getConfig(pId)?.isEnabled ?? smartDefault;
  }

  /// 🌟 الوضع الافتراضي للصلوات الخمس هو 1 (إشعار على الستارة بصوت الأذان)
  int getPeriodAlertLevel(String pId, [int? defaultVal]) {
    final config = _getConfig(pId);
    if (config != null) {
      if (!config.isEnabled) return 0;
      return config.alertLevel;
    }
    if (_isMandatoryPrayer(pId)) {
      return defaultVal ?? 1; // 1 = إشعار على الستارة بصوت الأذان افتراضياً
    }
    return 0;
  }

  String getPeriodSound(
    String pId, [
    String? defaultVal,
  ]) {
    final saved = _getConfig(pId)?.soundPath;
    if (saved != null && saved.isNotEmpty) return saved;
    if (_isMandatoryPrayer(pId)) {
      return defaultVal ?? 'assets/audio/adhan.mp3';
    }
    return defaultVal ?? 'assets/audio/default.mp3';
  }

  double getPeriodVolume(String pId, [double defaultVal = 1.0]) {
    return _getConfig(pId)?.volume ?? defaultVal;
  }
  
  /// 🌟 قراءة وحفظ تصحيح التاريخ الهجري (-2 إلى +2 يوم) داخل Isar دون الحاجة لإعادة توليد settings_model.g.dart
  int get hijriOffsetDays {
    for (final c in periodConfigs) {
      if (c.periodId == 'hijri_offset') {
        return c.manualOffsetMinutes.clamp(-2, 2);
      }
    }
    return 0;
  }

  set hijriOffsetDays(int days) {
    final clamped = days.clamp(-2, 2);
    final idx = periodConfigs.indexWhere((c) => c.periodId == 'hijri_offset');
    if (idx >= 0) {
      periodConfigs[idx].manualOffsetMinutes = clamped;
    } else {
      periodConfigs.add(
        PeriodConfig()
          ..periodId = 'hijri_offset'
          ..isEnabled = false
          ..manualOffsetMinutes = clamped,
      );
    }
  }

  int getManualOffset(String pId) {
    return _getConfig(pId)?.manualOffsetMinutes ?? 0;
  }

  SettingsModel clone() {
    return SettingsModel()
      ..id = id
      ..streakFreezesAvailable = streakFreezesAvailable
      ..dayBoundary = dayBoundary
      ..useAstroTimeForIbadat = useAstroTimeForIbadat
      ..civilTimeFormat = civilTimeFormat
      ..showSunrise = showSunrise
      ..visibleNightParts = List.from(visibleNightParts)
      ..isFirstLaunch = isFirstLaunch
      ..languageCode = languageCode
      ..themeMode = themeMode
      ..calculationMethod = calculationMethod
      ..madhab = madhab
      ..highLatitudeRule = highLatitudeRule
      ..customFajrAngle = customFajrAngle // 🌟 حفظ زاوية الفجر المخصصة
      ..customIshaAngle = customIshaAngle // 🌟 حفظ زاوية العشاء المخصصة
      ..timeDisplayMode = timeDisplayMode
      ..suwayaIconMode = suwayaIconMode
      ..activeLocation = activeLocation != null
          ? (SavedLocation()
            ..name = activeLocation!.name
            ..latitude = activeLocation!.latitude
            ..longitude = activeLocation!.longitude
            ..countryCode = activeLocation!.countryCode
            ..isAutoLocation = activeLocation!.isAutoLocation
            ..timezone = activeLocation!.timezone
            ..locationType = activeLocation!.locationType
            ..nearestCity = activeLocation!.nearestCity)
          : null
      ..savedLocations = savedLocations
          .map((l) => SavedLocation()
            ..name = l.name
            ..latitude = l.latitude
            ..longitude = l.longitude
            ..countryCode = l.countryCode
            ..isAutoLocation = l.isAutoLocation
            ..timezone = l.timezone
            ..locationType = l.locationType
            ..nearestCity = l.nearestCity)
          .toList()
      ..currentStreak = currentStreak
      ..longestStreak = longestStreak
      ..lastStreakDate = lastStreakDate
      ..qiyamAlarmEnabled = qiyamAlarmEnabled
      ..hiddenPeriods = List.from(hiddenPeriods)
      ..dialPinMode = dialPinMode
      ..suwayaNumberStyle = suwayaNumberStyle
      ..activeNightMarkers = List.from(activeNightMarkers)
      ..isDialAutoRotating = isDialAutoRotating
      ..defaultTaskAlertLevel = defaultTaskAlertLevel
      ..defaultTaskTone = defaultTaskTone
      ..defaultTaskVolume = defaultTaskVolume
      ..defaultHabitAlertLevel = defaultHabitAlertLevel
      ..defaultHabitTone = defaultHabitTone
      ..defaultHabitVolume = defaultHabitVolume
      ..snoozeDurationMinutes = snoozeDurationMinutes
      ..maxSnoozeCount = maxSnoozeCount
      ..periodConfigs = periodConfigs
          .map((c) => PeriodConfig()
            ..periodId = c.periodId
            ..isEnabled = c.isEnabled
            ..alertLevel = c.alertLevel
            ..soundPath = c.soundPath
            ..volume = c.volume
            ..manualOffsetMinutes = c.manualOffsetMinutes)
          .toList();
  }
}

@embedded
class SavedLocation {
  String name = '';
  double latitude = 0.0;
  double longitude = 0.0;
  String? countryCode;
  bool isAutoLocation = false;
  String? timezone;
  String locationType = 'list';
  String nearestCity = '';
}

@embedded
class PeriodConfig {
  String? periodId;
  bool isEnabled = true;
  int alertLevel = 0;
  String? soundPath;
  double volume = 1.0;
  int manualOffsetMinutes = 0;
}