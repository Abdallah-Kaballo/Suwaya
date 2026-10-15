import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  test('generateDay should create valid 24-suwaya distribution for Hanafi', () {
    const lat = 21.4225;
    const lng = 39.8262;
    final date = DateTime(2023, 5, 1);
    const method = CalculationMethodType.ummAlQura;
    const madhab = MadhabType.hanafi;
    const hlRule = HighLatitudeRuleType.middleOfTheNight;
    const customFajr = 18.0;
    const customIsha = 18.0;
    const cityOffset = Duration(hours: 3);

    final day = SuwayaTimeEngine.generateDay(
      lat, lng, date, method, madhab, hlRule, customFajr, customIsha, cityOffset
    );

    int totalSuwayas = day.periods.fold(0, (sum, p) => sum + p.suwayasCount);
    expect(totalSuwayas, equals(24));
  });
}