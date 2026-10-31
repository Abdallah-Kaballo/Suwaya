import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suwaya/core/location/location_service.dart';
import 'package:suwaya/core/location/permissions_provider.dart';
import 'package:suwaya/models/settings_model.dart';
import 'package:suwaya_time/suwaya_time.dart' show AstroSmartDefaults;

import '../../core/astro_engine/astro_provider.dart';
import '../../core/repositories/settings_repository.dart';

export 'package:suwaya_time/suwaya_time.dart'
    show AstroDefaults, AstroSmartDefaults;

class SettingsNotifier extends Notifier<SettingsModel> {
  late final SettingsRepository _repository;
  Future<void>? _initialization;

  Future<void> get initialized => _initialization ??= _initializeSettings();

  @override
  SettingsModel build() {
    _repository = ref.watch(settingsRepositoryProvider);
    Future.microtask(() => initialized);

    return SettingsModel();
  }

  Future<void> _initializeSettings() async {
    await _loadSettings();
    await validateAndApplyStreakFreezes();
  }

  Future<void> validateAndApplyStreakFreezes() async {
    final settings = state.clone();
    if (settings.lastStreakDate == null || settings.currentStreak == 0) return;

    final cityNow = virtualDateTimeNotifier.value;
    final today = DateTime(cityNow.year, cityNow.month, cityNow.day);
    final lastDate = DateTime(
      settings.lastStreakDate!.year,
      settings.lastStreakDate!.month,
      settings.lastStreakDate!.day,
    );

    int missedDays = today.difference(lastDate).inDays - 1;

    if (missedDays > 0) {
      bool isSaved = false;

      while (missedDays > 0 && settings.streakFreezesAvailable > 0) {
        settings.streakFreezesAvailable -= 1;
        missedDays -= 1;
        isSaved = true;
      }

      if (missedDays > 0) {
        settings.currentStreak = 0;
        settings.lastStreakDate = null;
      } else if (isSaved) {
        settings.lastStreakDate = today.subtract(const Duration(days: 1));
      }

      await _repository.saveSettings(settings);
      state = settings;
    }
  }

  Future<void> updateGlobalStreak() async {
    final newState = state.clone();
    final cityNow = virtualDateTimeNotifier.value;
    final today = DateTime(cityNow.year, cityNow.month, cityNow.day);
    bool isUpdated = false;

    if (newState.lastStreakDate == null) {
      newState.currentStreak = 1;
      if (newState.longestStreak < 1) newState.longestStreak = 1;
      newState.lastStreakDate = today;
      isUpdated = true;
    } else {
      final lastDate = DateTime(
        newState.lastStreakDate!.year,
        newState.lastStreakDate!.month,
        newState.lastStreakDate!.day,
      );
      final difference = today.difference(lastDate).inDays;
      if (difference == 1) {
        newState.currentStreak += 1;
        if (newState.currentStreak > newState.longestStreak) {
          newState.longestStreak = newState.currentStreak;
        }
        newState.lastStreakDate = today;
        isUpdated = true;
      } else if (difference > 1) {
        newState.currentStreak = 1;
        newState.lastStreakDate = today;
        isUpdated = true;
      }
    }
    if (isUpdated) {
      state = newState;
      await _repository.saveSettings(newState);
    }
  }

  Future<void> _loadSettings() async {
    final settings = await _repository.getSettings();
    state = settings.clone();
  }

  Future<void> updatePeriodNotificationSettings({
    required String periodId,
    required bool isEnabled,
    required int alertLevel,
    required String soundPath,
    required double volume,
  }) async {
    final newState = state.clone();
    int index = newState.periodConfigs.indexWhere(
      (c) => c.periodId == periodId,
    );
    if (index >= 0) {
      newState.periodConfigs[index]
        ..isEnabled = isEnabled
        ..alertLevel = alertLevel
        ..soundPath = soundPath
        ..volume = volume;
    } else {
      newState.periodConfigs.add(
        PeriodConfig()
          ..periodId = periodId
          ..isEnabled = isEnabled
          ..alertLevel = alertLevel
          ..soundPath = soundPath
          ..volume = volume,
      );
    }
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> updateManualOffset(String periodId, int minutesOffset) async {
    final newState = state.clone();
    int index = newState.periodConfigs.indexWhere(
      (c) => c.periodId == periodId,
    );
    if (index >= 0) {
      newState.periodConfigs[index].manualOffsetMinutes = minutesOffset;
    } else {
      newState.periodConfigs.add(
        PeriodConfig()
          ..periodId = periodId
          ..manualOffsetMinutes = minutesOffset,
      );
    }
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> resetAllOffsets() async {
    final newState = state.clone();
    for (var config in newState.periodConfigs) {
      if (config.periodId != 'hijri_offset') config.manualOffsetMinutes = 0;
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
    int index = newState.periodConfigs.indexWhere(
      (c) => c.periodId == periodId,
    );
    if (index >= 0) {
      newState.periodConfigs[index].soundPath = soundId;
    } else {
      newState.periodConfigs.add(
        PeriodConfig()
          ..periodId = periodId
          ..soundPath = soundId,
      );
    }
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> togglePeriodNotification(String periodId, bool isEnabled) async {
    if (isEnabled) {
      final isNotifGranted = await ref
          .read(permissionsProvider.notifier)
          .ensureNotificationPermission();
      final isAlarmGranted = await ref
          .read(permissionsProvider.notifier)
          .ensureExactAlarmPermission();
      if (!isNotifGranted || !isAlarmGranted) return;
    }
    final newState = state.clone();
    int index = newState.periodConfigs.indexWhere(
      (c) => c.periodId == periodId,
    );
    if (index >= 0) {
      newState.periodConfigs[index].isEnabled = isEnabled;
    } else {
      newState.periodConfigs.add(
        PeriodConfig()
          ..periodId = periodId
          ..isEnabled = isEnabled,
      );
    }
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> updateProductivityDefaults({
    required bool isTask,
    required int alertLevel,
    required String tone,
    required double volume,
  }) async {
    final newState = state.clone();
    if (isTask) {
      newState.defaultTaskAlertLevel = alertLevel;
      newState.defaultTaskTone = tone;
      newState.defaultTaskVolume = volume;
    } else {
      newState.defaultHabitAlertLevel = alertLevel;
      newState.defaultHabitTone = tone;
      newState.defaultHabitVolume = volume;
    }
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> updateSnoozeSettings({
    required int durationMinutes,
    required int maxCount,
  }) async {
    final newState = state.clone();
    newState.snoozeDurationMinutes = durationMinutes;
    newState.maxSnoozeCount = maxCount;
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> updateThemeMode(String newTheme) async {
    final newState = state.clone()..themeMode = newTheme;
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> updateCivilTimeFormat(String format) async {
    final newState = state.clone()..civilTimeFormat = format;
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> updateAstroSettings({
    String? method,
    String? madhab,
    String? highLatRule,
    double? fajrAngle,
    double? ishaAngle,
  }) async {
    final newState = state.clone();
    if (method != null) newState.calculationMethod = method;
    if (madhab != null) newState.madhab = madhab;
    if (highLatRule != null) newState.highLatitudeRule = highLatRule;
    if (newState.calculationMethod == 'custom') {
      if (fajrAngle != null) newState.customFajrAngle = fajrAngle;
      if (ishaAngle != null) newState.customIshaAngle = ishaAngle;
    } else {
      newState.customFajrAngle = 18.0;
      newState.customIshaAngle = 18.0;
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
      ..isAutoLocation =
          (locationType == 'gps') // 🌟 ربط التحديث التلقائي بنوع GPS
      ..nearestCity = nearestCity;

    final newState = state.clone()..activeLocation = loc;

    final existingIndex = newState.savedLocations.indexWhere(
      (l) => l.latitude == lat && l.longitude == lng,
    );
    if (existingIndex != -1) {
      newState.savedLocations.removeAt(existingIndex);
    }
    newState.savedLocations.add(loc);

    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> selectSavedLocation(SavedLocation loc) async {
    final defaults = AstroSmartDefaults.getDefaultsForCountry(loc.countryCode);
    final newState = state.clone()
      ..activeLocation = loc
      ..calculationMethod = defaults.method
      ..madhab = defaults.madhab
      ..highLatitudeRule = defaults.highLatitudeRule;

    if (!newState.savedLocations.any(
      (l) => l.latitude == loc.latitude && l.longitude == loc.longitude,
    )) {
      newState.savedLocations = List.from(newState.savedLocations)..add(loc);
    }

    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> autoDetectLocation() async {
    try {
      final isLocGranted = await ref
          .read(permissionsProvider.notifier)
          .ensureLocationPermission();
      if (!isLocGranted) throw Exception('permissions.location_required'.tr());

      // 🌟 استخدام المسار المحلي الموحد لضمان جلب وحفظ المنطقة الزمنية (timezone) وأقرب مدينة
      final locData = await LocationService.fetchOfflineLocation(
        state.languageCode,
      );
      final String detectedCountryCode =
          (locData['countryCode'] as String?) ?? 'SA';

      await addAndSelectLocation(
        (locData['formattedName'] as String?) ??
            'location_picker.current_location'.tr(),
        (locData['lat'] as num).toDouble(),
        (locData['lng'] as num).toDouble(),
        detectedCountryCode,
        timezone: locData['timezone'] as String?,
        locationType: 'gps',
        nearestCity: (locData['city'] as String?) ?? '',
      );

      final defaults = AstroSmartDefaults.getDefaultsForCountry(
        detectedCountryCode,
      );
      await updateAstroSettings(
        method: defaults.method,
        madhab: defaults.madhab,
        highLatRule: defaults.highLatitudeRule,
      );
    } catch (e) {
      rethrow;
    }
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

  Future<void> updateDialPinMode(String mode) async {
    final newState = state.clone()..dialPinMode = mode;
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> toggleNightMarker(String markerId) async {
    const Map<String, String> startConflicts = {
      'half_2': 'sixth_4',
      'sixth_4': 'half_2',
      'third_3': 'sixth_5',
      'sixth_5': 'third_3',
    };

    const order = [
      'half_1',
      'half_2',
      'third_1',
      'third_2',
      'third_3',
      'sixth_1',
      'sixth_2',
      'sixth_3',
      'sixth_4',
      'sixth_5',
      'sixth_6',
    ];

    final newState = state.clone();
    final List<String> current = List.from(newState.activeNightMarkers);

    if (current.contains(markerId)) {
      current.remove(markerId);
    } else {
      final conflictingId = startConflicts[markerId];
      if (conflictingId != null) {
        current.remove(conflictingId);
      }
      current.add(markerId);
    }

    current.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
    newState.activeNightMarkers = current;
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> updateBatchPeriodNotificationSettings({
    required List<String> periodIds,
    required bool isEnabled,
    required int alertLevel,
    required String soundPath,
    required double volume,
  }) async {
    final newState = state.clone();
    for (final periodId in periodIds) {
      final index = newState.periodConfigs.indexWhere(
        (c) => c.periodId == periodId,
      );
      if (index >= 0) {
        newState.periodConfigs[index]
          ..isEnabled = isEnabled
          ..alertLevel = alertLevel
          ..soundPath = soundPath
          ..volume = volume;
      } else {
        newState.periodConfigs.add(
          PeriodConfig()
            ..periodId = periodId
            ..isEnabled = isEnabled
            ..alertLevel = alertLevel
            ..soundPath = soundPath
            ..volume = volume,
        );
      }
    }
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

    const order = [
      'half_1',
      'half_2',
      'third_1',
      'third_2',
      'third_3',
      'sixth_1',
      'sixth_2',
      'sixth_3',
      'sixth_4',
      'sixth_5',
      'sixth_6',
    ];
    newState.visibleNightParts.sort(
      (a, b) => order.indexOf(a).compareTo(order.indexOf(b)),
    );

    state = newState;
    await _repository.saveSettings(newState);
  }

  // 🌟 دالة تحديث نمط الرموز
  Future<void> updateSuwayaIconMode(String mode) async {
    final newState = state.clone()..suwayaIconMode = mode;
    state = newState;
    await _repository.saveSettings(newState);
  }

  // 🌟 دالة تحديث تصحيح التاريخ الهجري (-2 إلى +2 يوم)
  Future<void> updateHijriOffsetDays(int days) async {
    final newState = state.clone()..hijriOffsetDays = days.clamp(-2, 2);
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> updateAppFontFamily(String family) async {
    final newState = state.clone()..appFontFamily = family;
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> updateAppFontScale(double scale) async {
    final newState = state.clone()..appFontScale = scale.clamp(0.85, 1.25);
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> updateSuwayaNumberStyle(String numberStyle) async {
    final newState = state.clone()..suwayaNumberStyle = numberStyle;
    state = newState;
    await _repository.saveSettings(newState);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsModel>(
  SettingsNotifier.new,
);
