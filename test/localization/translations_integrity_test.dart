import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya/core/localization/app_locales.dart';

void _expectSectionMatchesEnglish({
  required String localeCode,
  required String sectionName,
  required Map<String, dynamic> localeMap,
  required Map<String, dynamic> englishMap,
}) {
  final value = localeMap[sectionName];
  expect(
    value,
    isA<Map<String, dynamic>>(),
    reason: 'Locale $localeCode.json section "$sectionName" must be a JSON object',
  );
  if (value is! Map<String, dynamic>) return;

  final englishValue = englishMap[sectionName];
  expect(
    englishValue,
    isA<Map<String, dynamic>>(),
    reason: 'English reference section "$sectionName" must be a JSON object',
  );
  if (englishValue is! Map<String, dynamic>) return;

  expect(
    value.keys.toSet(),
    englishValue.keys.toSet(),
    reason: 'Locale $localeCode.json section "$sectionName" must use the same keys as en.json',
  );

  for (final entry in value.entries) {
    expect(
      entry.value,
      isA<String>(),
      reason: 'Translation for "$sectionName.${entry.key}" in $localeCode.json must be a string',
    );
    if (entry.value is String) {
      expect(
        (entry.value as String).trim(),
        isNotEmpty,
        reason: 'Empty translation for "$sectionName.${entry.key}" in $localeCode.json',
      );
    }
  }
}

void main() {
  group('22-language translation JSON integrity', () {
    test('Every supported locale exists, parses, and contains the required core sections', () {
      const requiredTopLevelSections = [
        'app_name',
        'common',
        'night_parts',
        'home',
        'periods',
        'prayers',
        'ibadat',
        'tasks',
        'settings',
        'pomodoro',
      ];

      final enFile = File('assets/translations/en.json');
      expect(enFile.existsSync(), isTrue);
      final englishMap =
          jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
      expect(englishMap.keys, isNotEmpty);

      for (final locale in AppLocales.supported) {
        final code = locale.languageCode;
        final file = File('assets/translations/$code.json');
        expect(
          file.existsSync(),
          isTrue,
          reason: 'Missing translation file for locale: $code',
        );

        final rawContent = file.readAsStringSync();
        late final Map<String, dynamic> decoded;
        expect(
          () => decoded = jsonDecode(rawContent) as Map<String, dynamic>,
          returnsNormally,
          reason: 'Invalid JSON syntax in assets/translations/$code.json',
        );

        for (final section in requiredTopLevelSections) {
          expect(
            decoded.containsKey(section),
            isTrue,
            reason: 'Locale $code.json is missing required section "$section"',
          );
        }

        for (final section in ['periods', 'prayers']) {
          _expectSectionMatchesEnglish(
            localeCode: code,
            sectionName: section,
            localeMap: decoded,
            englishMap: englishMap,
          );
        }
      }
    });
  });
}
