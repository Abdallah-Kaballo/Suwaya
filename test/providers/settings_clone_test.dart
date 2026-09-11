import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya/models/settings_model.dart';

void main() {
  group('SettingsModel Clone Tests', () {
    test('يجب نسخ جميع الإعدادات المحلية بدقة واستقلالية', () {
      final original = SettingsModel()
        ..languageCode = 'ar'
        ..themeMode = 'dark'
        ..streakFreezesAvailable = 5
        ..currentStreak = 12
        ..isDialAutoRotating = false;

      final cloned = original.clone();

      expect(cloned.languageCode, equals('ar'));
      expect(cloned.themeMode, equals('dark'));
      expect(cloned.streakFreezesAvailable, equals(5));
      expect(cloned.currentStreak, equals(12));
      expect(cloned.isDialAutoRotating, equals(false));

      // التأكد من استقلالية الكائن المنسوخ
      cloned.currentStreak = 20;
      expect(original.currentStreak, equals(12));
    });
  });
}