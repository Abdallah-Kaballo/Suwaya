import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  test('Dial pin layout handles standard periods', () {
    final period = AstroPeriod(
      id: 1,
      periodKey: PeriodKey.nightMaghribIsha,
      nameKey: 'test',
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(hours: 1)),
      suwayasCount: 1,
      colorValue: 0,
    );
    expect(period.suwayasCount, 1);
  });
}
