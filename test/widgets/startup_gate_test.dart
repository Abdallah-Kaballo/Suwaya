import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya/core/router/startup_gate.dart';

void main() {
  test('sends new users to onboarding after settings load', () {
    expect(startupDestination(true), '/onboarding');
  });

  test('sends returning users to home after settings load', () {
    expect(startupDestination(false), '/home');
  });
}
