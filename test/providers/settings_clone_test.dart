import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya/models/settings_model.dart'; // تأكد من مسار النموذج

void main() {
  group('اختبارات حماية البيانات (Settings Model)', () {
    test('دالة clone يجب أن تنسخ جميع الحقول العميقة والمضافة حديثاً', () {
      final original = SettingsModel()
        ..id = 1
        ..isSynced = true
        ..streakFreezesAvailable = 5
        ..dayBoundary = 'midnight'
        ..useAstroTimeForIbadat = false
        ..currentStreak = 10;

      final cloned = original.clone();

      expect(cloned.id, equals(1));
      expect(cloned.isSynced, isTrue, reason: 'يجب ألا تفقد حالة المزامنة');
      expect(cloned.streakFreezesAvailable, equals(5), reason: 'يجب ألا تفقد رصيد التجميد');
      expect(cloned.dayBoundary, equals('midnight'));
      expect(cloned.useAstroTimeForIbadat, isFalse);
      expect(cloned.currentStreak, equals(10));
      
      // التعديل على المنسوخ يجب ألا يؤثر على الأصلي (Deep Copy)
      cloned.currentStreak = 20;
      expect(original.currentStreak, equals(10), reason: 'النسخ يجب أن يكون عميقاً وليس مرجعياً');
    });
  });
}