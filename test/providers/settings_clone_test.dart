import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya/models/settings_model.dart';

void main() {
  group('SettingsModel Clone Tests', () {
    test('يجب نسخ جميع الإعدادات المحلية بدقة واستقلالية', () {
      final original = SettingsModel()
        ..languageCode = 'ar'
        ..themeMode = 'dark'
        ..civilTimeFormat = '24-hour'
        ..streakFreezesAvailable = 5
        ..currentStreak = 12
        ..isDialAutoRotating = false
        ..dialPinMode = 'civil24';

      final cloned = original.clone();

      expect(cloned.languageCode, equals('ar'));
      expect(cloned.themeMode, equals('dark'));
      expect(cloned.civilTimeFormat, equals('24-hour'));
      expect(cloned.streakFreezesAvailable, equals(5));
      expect(cloned.currentStreak, equals(12));
      expect(cloned.isDialAutoRotating, equals(false));
      expect(cloned.dialPinMode, equals('civil24'));

      // التأكد من استقلالية الكائن المنسوخ
      cloned.currentStreak = 20;
      expect(original.currentStreak, equals(12));
    });

    test('يستخدم ترقيم السويعات كخيار افتراضي', () {
      expect(SettingsModel().dialPinMode, equals('suwaya48'));
    });
  });
}
