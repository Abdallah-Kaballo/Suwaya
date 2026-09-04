import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/repositories/settings_repository.dart';
import 'package:suwaya/models/settings_model.dart';
import '../../core/services/location_service.dart';
import '../../core/services/permissions_provider.dart'; 

class AstroDefaults {
  final String method;
  final String madhab;
  final String highLatitudeRule;
  const AstroDefaults({
    required this.method, 
    required this.madhab, 
    required this.highLatitudeRule,
  });
}

class AstroSmartDefaults {
  static AstroDefaults getDefaultsForCountry(String? countryCode) {
    if (countryCode == null || countryCode == 'CUSTOM') {
      return const AstroDefaults(method: 'muslim_world_league', madhab: 'shafi', highLatitudeRule: 'middle_of_the_night');
    }

    String method = 'muslim_world_league';
    String madhab = 'shafi';
    String highLatRule = 'middle_of_the_night'; 

    switch (countryCode.toUpperCase()) {
      case 'EG': case 'SD': case 'SS': case 'LY': case 'SY': case 'LB': case 'JO': case 'PS':
        method = 'egyptian'; break;
      case 'SA': 
        method = 'umm_al_qura'; break;
      case 'AE': 
        method = 'dubai'; break;
      case 'QA': 
        method = 'qatar'; break;
      case 'KW': 
        method = 'kuwait'; break;
      case 'IR': case 'IQ':
        method = 'tehran'; break;
      case 'PK': case 'AF': case 'BD': case 'IN': case 'LK': case 'MV':
        method = 'karachi'; madhab = 'hanafi'; break;
      case 'MY': case 'SG': case 'ID': case 'BN':
        method = 'singapore'; break;
      case 'TR': case 'AZ': case 'TM': case 'UZ': case 'KG':
        method = 'turkey'; madhab = 'hanafi'; break;
      case 'FR': case 'BE': case 'IT': case 'ES': case 'CH':
        method = 'france_uoif'; break;
      case 'RU': case 'BY': case 'UA':
        method = 'russia'; highLatRule = 'seventh_of_the_night'; break;
      case 'GB': case 'IE': case 'DE': case 'NL':
        method = 'muslim_world_league'; highLatRule = 'seventh_of_the_night'; break;
      case 'SE': case 'NO': case 'FI': case 'DK': case 'IS':
        method = 'muslim_world_league'; highLatRule = 'twilight_angle'; break;
      case 'US': case 'CA':
        method = 'north_america'; highLatRule = countryCode.toUpperCase() == 'CA' ? 'seventh_of_the_night' : 'middle_of_the_night'; break;
    }
    return AstroDefaults(method: method, madhab: madhab, highLatitudeRule: highLatRule);
  }
}

class SettingsNotifier extends Notifier<SettingsModel> {
  late final SettingsRepository _repository;

  @override
  SettingsModel build() {
    _repository = ref.watch(settingsRepositoryProvider);
    _loadSettings();
    return SettingsModel();
  }
 
  Future<void> _loadSettings() async {
    final settings = await _repository.getSettings();
    state = settings.clone(); 
  }
  
  Future<void> updatePeriodNotificationSettings({required String periodId, required bool isEnabled, required int alertLevel, required String soundPath, required double volume}) async {
    final newState = state.clone();
    int index = newState.periodConfigs.indexWhere((c) => c.periodId == periodId);
    if (index >= 0) {
      newState.periodConfigs[index]..isEnabled = isEnabled..alertLevel = alertLevel..soundPath = soundPath..volume = volume;
    } else {
      newState.periodConfigs.add(PeriodConfig()..periodId = periodId..isEnabled = isEnabled..alertLevel = alertLevel..soundPath = soundPath..volume = volume);
    }
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> updateManualOffset(String periodId, int minutesOffset) async {
    final newState = state.clone();
    int index = newState.periodConfigs.indexWhere((c) => c.periodId == periodId);
    if (index >= 0) {
      newState.periodConfigs[index].manualOffsetMinutes = minutesOffset;
    } else {
      newState.periodConfigs.add(PeriodConfig()..periodId = periodId..manualOffsetMinutes = minutesOffset);
    }
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> resetAllOffsets() async {
    final newState = state.clone();
    for (var config in newState.periodConfigs) {
      config.manualOffsetMinutes = 0;
    }
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> updateCalculationMethod(String method) async {
    final newState = state.clone()..calculationMethod = method;
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> updateMadhab(String madhab) async {
    final newState = state.clone()..madhab = madhab;
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> updatePeriodSound(String periodId, String soundId) async {
    final newState = state.clone();
    int index = newState.periodConfigs.indexWhere((c) => c.periodId == periodId);
    if (index >= 0) {
      newState.periodConfigs[index].soundPath = soundId;
    } else {
      newState.periodConfigs.add(PeriodConfig()..periodId = periodId..soundPath = soundId);
    }
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> togglePeriodNotification(String periodId, bool isEnabled) async {
    if (isEnabled) {
      final isNotifGranted = await ref.read(permissionsProvider.notifier).ensureNotificationPermission();
      final isAlarmGranted = await ref.read(permissionsProvider.notifier).ensureExactAlarmPermission();
      if (!isNotifGranted || !isAlarmGranted) return; 
    }
    final newState = state.clone();
    int index = newState.periodConfigs.indexWhere((c) => c.periodId == periodId);
    if (index >= 0) {
      newState.periodConfigs[index].isEnabled = isEnabled;
    } else {
      newState.periodConfigs.add(PeriodConfig()..periodId = periodId..isEnabled = isEnabled);
    }
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> updateProductivityDefaults({required bool isTask, required int alertLevel, required String tone, required double volume}) async {
    final newState = state.clone();
    if (isTask) {
      newState.defaultTaskAlertLevel = alertLevel; newState.defaultTaskTone = tone; newState.defaultTaskVolume = volume;
    } else {
      newState.defaultHabitAlertLevel = alertLevel; newState.defaultHabitTone = tone; newState.defaultHabitVolume = volume;
    }
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> updateSnoozeSettings({required int durationMinutes, required int maxCount}) async {
    final newState = state.clone();
    newState.snoozeDurationMinutes = durationMinutes; newState.maxSnoozeCount = maxCount;
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> updateThemeMode(String newTheme) async {
    final newState = state.clone()..themeMode = newTheme;
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> updateAstroSettings({String? method, String? madhab, String? highLatRule, double? fajrAngle, double? ishaAngle}) async {
    final newState = state.clone();
    if (method != null) newState.calculationMethod = method;
    if (madhab != null) newState.madhab = madhab;
    if (highLatRule != null) newState.highLatitudeRule = highLatRule;
    if (newState.calculationMethod == 'custom') {
      if (fajrAngle != null) newState.customFajrAngle = fajrAngle;
      if (ishaAngle != null) newState.customIshaAngle = ishaAngle;
    } else {
      newState.customFajrAngle = 18.0; newState.customIshaAngle = 18.0;
    }
    state = newState; 
    await _repository.saveSettings(newState); 
  }

  Future<void> updateLanguage(String langCode) async {
    final newState = state.clone()..languageCode = langCode;
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> addAndSelectLocation(
    String name, 
    double lat, 
    double lng, 
    String countryCode, {
    String? timezone,
    String locationType = 'list', 
    String nearestCity = '',      
  }) async {
    final loc = SavedLocation()
      ..name = name
      ..latitude = lat
      ..longitude = lng
      ..countryCode = countryCode
      ..timezone = timezone
      ..locationType = locationType 
      ..nearestCity = nearestCity;

    final newState = state.clone()..activeLocation = loc;
    
    final existingIndex = newState.savedLocations.indexWhere((l) => 
        l.latitude == lat && l.longitude == lng);
    if (existingIndex != -1) {
      newState.savedLocations.removeAt(existingIndex);
    }
    newState.savedLocations.add(loc);
    
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> selectSavedLocation(SavedLocation loc) async {
    final defaults = AstroSmartDefaults.getDefaultsForCountry(loc.countryCode);
    final newState = state.clone()..activeLocation = loc..calculationMethod = defaults.method..madhab = defaults.madhab..highLatitudeRule = defaults.highLatitudeRule;
    state = newState; 
    _repository.updateActiveLocation(loc);
    _repository.saveSettings(newState);
  }

  Future<void> autoDetectLocation() async {
    try {
      final isLocGranted = await ref.read(permissionsProvider.notifier).ensureLocationPermission();
      if (!isLocGranted) throw Exception('لا يمكن تحديد الموقع بدون منح الصلاحيات.');
      final position = await LocationService.determinePosition();
      String detectedCountryCode = 'SA'; 
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty && placemarks.first.isoCountryCode != null) detectedCountryCode = placemarks.first.isoCountryCode!;
      } catch (_) {}
      
      final loc = SavedLocation()..latitude = position.latitude..longitude = position.longitude..countryCode = detectedCountryCode..name = 'موقعي الحالي'..isAutoLocation = true;
      await _repository.updateActiveLocation(loc);
      final defaults = AstroSmartDefaults.getDefaultsForCountry(detectedCountryCode);
      await updateAstroSettings(method: defaults.method, madhab: defaults.madhab, highLatRule: defaults.highLatitudeRule);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateGlobalStreak() async {
    final newState = state.clone();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool isUpdated = false;

    if (newState.lastStreakDate == null) {
      newState.currentStreak = 1; newState.longestStreak = 1; newState.lastStreakDate = today; isUpdated = true;
    } else {
      final lastDate = DateTime(newState.lastStreakDate!.year, newState.lastStreakDate!.month, newState.lastStreakDate!.day);
      final difference = today.difference(lastDate).inDays;
      if (difference == 1) {
        newState.currentStreak += 1;
        if (newState.currentStreak > newState.longestStreak) newState.longestStreak = newState.currentStreak;
        newState.lastStreakDate = today; isUpdated = true;
      } else if (difference > 1) {
        newState.currentStreak = 1; newState.lastStreakDate = today; isUpdated = true;
      }
    }
    if (isUpdated) { state = newState; await _repository.saveSettings(newState); }
  }

  Future<void> saveAndUpdateScheduler(SettingsModel newSettings) async {
    state = newSettings.clone();
    await _repository.saveSettings(state);
  }

  Future<void> completeOnboarding() async {
    final newState = state.clone()..isFirstLaunch = false;
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> updateDialAutoRotation(bool isAutoRotating) async {
    final newState = state.clone()..isDialAutoRotating = isAutoRotating; 
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> toggleNightMarker(String markerId) async {
    final newState = state.clone();
    List<String> current = List.from(newState.activeNightMarkers);

    if (current.contains(markerId)) {
      current.remove(markerId);
    } else {
      if (markerId == 'np_third_3') { current.remove('np_sixth_5'); current.remove('np_sixth_6'); }
      if (markerId == 'np_sixth_5' || markerId == 'np_sixth_6') current.remove('np_third_3');
      if (markerId == 'np_half_2') { current.remove('np_sixth_4'); current.remove('np_sixth_5'); current.remove('np_sixth_6'); current.remove('np_third_3'); }
      if (markerId == 'np_sixth_4') current.remove('np_half_2');
      if (markerId == 'np_third_2') { current.remove('np_sixth_3'); current.remove('np_sixth_4'); }
      if (markerId == 'np_sixth_3') current.remove('np_third_2');

      if (current.length >= 2) current.removeAt(0); 
      current.add(markerId);
    }
    
    newState.activeNightMarkers = current;
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> refreshDynamicLocationIfNeeded() async {
    if (state.activeLocation?.isAutoLocation == true) {
      try {
        await autoDetectLocation();
      } catch (_) {}
    }
  }

  Future<void> updateUseAstroTimeForIbadat(bool value) async {
    final newState = state.clone()..useAstroTimeForIbadat = value;
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> updateShowSunrise(bool value) async {
    final newState = state.clone()..showSunrise = value;
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> toggleVisibleNightPart(String partId) async {
    final newState = state.clone();
    if (newState.visibleNightParts.contains(partId)) {
      newState.visibleNightParts.remove(partId);
    } else {
      newState.visibleNightParts.add(partId);
    }
    
    final order = ['half_1','half_2','third_1','third_2','third_3','sixth_1','sixth_2','sixth_3','sixth_4','sixth_5','sixth_6'];
    newState.visibleNightParts.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));

    state = newState;
    await _repository.saveSettings(newState);
  }
} 

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsModel>(SettingsNotifier.new);