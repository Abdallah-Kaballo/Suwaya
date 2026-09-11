import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  group('SuwayaDistributor Tests', () {
    test('يجب أن يعيد دائماً التوزيع العالمي الموحد [7, 7, 7, 6, 7, 7, 7]', () {
      final distribution = SuwayaDistributor.getUniversalDistribution();
      
      expect(distribution, equals([7, 7, 7, 6, 7, 7, 7]));
      
      final total = distribution.fold(0, (a, b) => a + b);
      expect(total, equals(48)); // التأكد من أن المجموع يساوي 48 سويعة
    });
  });
}