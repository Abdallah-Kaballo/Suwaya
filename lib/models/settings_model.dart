import 'package:isar_community/isar.dart';
part 'settings_model.g.dart';

@collection
class SettingsModel {
  Id id = 0; 
  bool isFirstLaunch = true;
  String languageCode = 'ar';
  
  String themeMode = 'dark'; 

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

  bool qiyamAlarmEnabled = false;

  List<int> hiddenPeriods = [];

  bool isDialAutoRotating = true;
  String suwayaNumberStyle = 'english'; 
  List<String> activeNightMarkers = ['fifth_sixth']; 

  List<PeriodConfig> periodConfigs = [];

  bool useAstroTimeForIbadat = true; 
  bool showSunrise = false; 
  List<String> visibleNightParts = ['third_3', 'sixth_4', 'sixth_5'];

  int defaultTaskAlertLevel = 1; 
  String defaultTaskTone = 'assets/audio/default.mp3';
  double defaultTaskVolume = 1.0;

  int defaultHabitAlertLevel = 2; 
  String defaultHabitTone = 'assets/audio/default.mp3';
  double defaultHabitVolume = 1.0;

  int snoozeDurationMinutes = 10; 
  int maxSnoozeCount = 3;         

  PeriodConfig? _getConfig(String pId) {
    try { return periodConfigs.firstWhere((c) => c.periodId == pId); } 
    catch (_) { return null; }
  }

  bool isPeriodEnabled(String pId, {bool defaultVal = true}) {
    final smartDefault = (pId == 'sunrise' || pId.startsWith('half') || pId.startsWith('third') || pId.startsWith('sixth')) ? false : defaultVal;
    return _getConfig(pId)?.isEnabled ?? smartDefault;
  }

  // 🌟 الحل الجذري: الإعداد الافتراضي أصبح 0 (صامت) بدلاً من 2
  int getPeriodAlertLevel(String pId, [int defaultVal = 0]) {
    final smartDefault = (pId == 'sunrise' || pId.startsWith('half') || pId.startsWith('third') || pId.startsWith('sixth')) ? 0 : defaultVal;
    return _getConfig(pId)?.alertLevel ?? smartDefault;
  }

  String getPeriodSound(String pId, [String defaultVal = 'assets/audio/default.mp3']) {
    return _getConfig(pId)?.soundPath ?? defaultVal;
  }

  double getPeriodVolume(String pId, [double defaultVal = 1.0]) {
    return _getConfig(pId)?.volume ?? defaultVal;
  }

  int getManualOffset(String pId) {
    return _getConfig(pId)?.manualOffsetMinutes ?? 0;
  }

  SettingsModel clone() {
    return SettingsModel()
      ..useAstroTimeForIbadat = useAstroTimeForIbadat
      ..showSunrise = showSunrise
      ..visibleNightParts = List.from(visibleNightParts)
      ..id = id
      ..isFirstLaunch = isFirstLaunch
      ..languageCode = languageCode
      ..themeMode = themeMode
      ..calculationMethod = calculationMethod
      ..madhab = madhab
      ..highLatitudeRule = highLatitudeRule
      ..customFajrAngle = customFajrAngle
      ..customIshaAngle = customIshaAngle
      ..activeLocation = activeLocation != null 
          ? (SavedLocation()
              ..name = activeLocation!.name 
              ..latitude = activeLocation!.latitude 
              ..longitude = activeLocation!.longitude 
              ..countryCode = activeLocation!.countryCode 
              ..isAutoLocation = activeLocation!.isAutoLocation 
              ..timezone = activeLocation!.timezone
              ..locationType = activeLocation!.locationType 
              ..nearestCity = activeLocation!.nearestCity   
            ) 
          : null
      ..savedLocations = savedLocations.map((l) => SavedLocation()
              ..name = l.name 
              ..latitude = l.latitude 
              ..longitude = l.longitude 
              ..countryCode = l.countryCode 
              ..isAutoLocation = l.isAutoLocation 
              ..timezone = l.timezone
              ..locationType = l.locationType 
              ..nearestCity = l.nearestCity   
          ).toList()
      ..currentStreak = currentStreak
      ..longestStreak = longestStreak
      ..lastStreakDate = lastStreakDate
      ..qiyamAlarmEnabled = qiyamAlarmEnabled
      ..hiddenPeriods = List.from(hiddenPeriods)
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
      ..periodConfigs = periodConfigs.map((c) => PeriodConfig()
         ..periodId = c.periodId
         ..isEnabled = c.isEnabled
         ..alertLevel = c.alertLevel
         ..soundPath = c.soundPath
         ..volume = c.volume
         ..manualOffsetMinutes = c.manualOffsetMinutes).toList();
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
  int alertLevel = 0; // 🌟 الافتراضي صامت أيضاً هنا
  String? soundPath;
  double volume = 1.0;
  int manualOffsetMinutes = 0; 
}