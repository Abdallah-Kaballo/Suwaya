import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  test('Jumhur distribution sum should be 24', () {
    final dist = SuwayaDistributor.getDistributionForMadhab(MadhabType.shafi);
    final sum = dist.reduce((a, b) => a + b);
    expect(sum, 24);
  });

  test('Hanafi distribution sum should be 24', () {
    final dist = SuwayaDistributor.getDistributionForMadhab(MadhabType.hanafi);
    final sum = dist.reduce((a, b) => a + b);
    expect(sum, 24);
  });
}
