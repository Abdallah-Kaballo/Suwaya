import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya/features/home/widgets/dial/dial_pin_layout.dart';
import 'package:suwaya/features/home/widgets/dial/dial_constants.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  group('civil dial pin layout', () {
    final dayStart = DateTime.utc(2026, 6, 12, 18, 30);
    final dayEnd = DateTime.utc(2026, 6, 13, 18, 30);

    test('places one pin for each civil hour and anchors 00 at midnight', () {
      final pins = buildCivilDialPins(dayStart, dayEnd);

      expect(pins, hasLength(24));
      expect(
          pins.map((pin) => pin.hour).toSet(),
          equals(Set<int>.from(
            List<int>.generate(24, (hour) => hour),
          )));

      final midnightPin = pins.singleWhere((pin) => pin.hour == 0);
      expect(
        midnightPin.angle,
        closeTo(
          timeToAngle(DateTime.utc(2026, 6, 13), dayStart, dayEnd),
          1e-10,
        ),
      );
    });
  });

  test('keeps all 48 suwaya pin angles', () {
    final dayStart = DateTime.utc(2026, 6, 12, 18, 30);
    final dayEnd = DateTime.utc(2026, 6, 13, 18, 30);
    final period = AstroPeriod(
      id: 1,
      name: 'Full day',
      nameKey: 'period_full_day',
      startTime: dayStart,
      endTime: dayEnd,
      suwayasCount: 48,
      colorValue: 0xFFFFFFFF,
    );

    final angles = buildSuwayaPinAngles([period], dayStart, dayEnd);

    expect(angles, hasLength(48));
    expect(angles.first, closeTo(-1.5707963267948966, 1e-10));
  });

  test('aligns inward Suwaya pins with civil ticks and needle tip', () {
    const dialRadius = 200.0;
    final band = buildSuwayaPinRadiusBand(dialRadius);

    expect(band.innerRadius, closeTo(161, 1e-10));
    expect(band.outerRadius, closeTo(dialRadius * kRailwayR, 1e-10));
    expect(band.outerRadius, lessThan(dialRadius * kOuterR));
  });
}
