import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  group('Property-Based Testing: Suwaya Distribution', () {
    
    test('يجب أن يكون المجموع دائماً 48 سويعة في الأيام المعتدلة', () {
      final durations = [5400, 10800, 14400, 10800, 3600, 14400, 27000]; // ثواني افتراضية
      final distribution = SuwayaDistributor.distribute48Suwayas(durations);
      
      final sum = distribution.fold(0, (a, b) => a + b);
      expect(sum, equals(48), reason: 'مجموع السويعات يجب أن يكون 48');
      expect(distribution.length, equals(7), reason: 'يجب أن توزع على 7 فترات');
    });

    test('يجب أن يكون المجموع 48 سويعة في الصيف المتطرف (نهار طويل جداً)', () {
      final durations = [10000, 25000, 30000, 15000, 2000, 4000, 400]; 
      final distribution = SuwayaDistributor.distribute48Suwayas(durations);
      
      final sum = distribution.fold(0, (a, b) => a + b);
      expect(sum, equals(48));
      // لا يجب أن تحصل أي فترة على أقل من سويعة واحدة
      expect(distribution.every((suwaya) => suwaya >= 1), isTrue); 
    });

    test('يجب أن يكون المجموع 48 سويعة في الشتاء المتطرف (ليل طويل جداً)', () {
      final durations = [2000, 4000, 4000, 3000, 10000, 30000, 33400]; 
      final distribution = SuwayaDistributor.distribute48Suwayas(durations);
      
      final sum = distribution.fold(0, (a, b) => a + b);
      expect(sum, equals(48));
      expect(distribution.every((suwaya) => suwaya >= 1), isTrue);
    });

    test('معالجة الأصفار أو الأخطاء (Fall-back) تنتج 48 سويعة', () {
      final durations = [0, 0, 0, 0, 0, 0, 0]; 
      final distribution = SuwayaDistributor.distribute48Suwayas(durations);
      
      final sum = distribution.fold(0, (a, b) => a + b);
      expect(sum, equals(48));
    });
  });
}