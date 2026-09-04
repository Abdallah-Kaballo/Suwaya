import 'package:isar_community/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ✅ مسار نسبي دقيق يشير إلى مجلد النماذج الجديد داخل core
import 'package:suwaya/models/settings_model.dart';
import '../database/database_provider.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return SettingsRepository(isar);
});

class SettingsRepository {
  final Isar _isar;

  SettingsRepository(this._isar);

  Future<SettingsModel> getSettings() async {
    final settings = await _isar.settingsModels.get(1);
    if (settings != null) return settings;

    final defaultSettings = SettingsModel()
      ..id = 1
      ..isFirstLaunch = true
      ..savedLocations = [];
      
    await saveSettings(defaultSettings);
    return defaultSettings;
  }

  Future<void> saveSettings(SettingsModel settings) async {
    await _isar.writeTxn(() async {
      await _isar.settingsModels.put(settings);
    });
  }

  Future<void> updateActiveLocation(SavedLocation location) async {
    final settings = await getSettings();
    settings.activeLocation = location;
    
    if (!settings.savedLocations.any((l) => l.latitude == location.latitude && l.longitude == location.longitude)) {
      settings.savedLocations = List.from(settings.savedLocations)..add(location);
    }

    await saveSettings(settings);
  }
}