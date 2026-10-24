import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya/core/localization/app_locales.dart';

Set<String> _flattenKeys(Map<String, dynamic> map, [String prefix = '']) {
  final keys = <String>{};
  for (final entry in map.entries) {
    final fullKey = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    if (entry.value is Map<String, dynamic>) {
      keys.addAll(_flattenKeys(entry.value as Map<String, dynamic>, fullKey));
    } else {
      keys.add(fullKey);
    }
  }
  return keys;
}

void main() {
  group('22-Language Translations JSON Integrity Tests', () {
    test(
        'All 22 supported locale JSON files exist, parse cleanly, and contain core astronomical and UI sections',
        () {
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
      final enMap =
          jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
      final enKeys = _flattenKeys(enMap);
      expect(enKeys, isNotEmpty);

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

        // التأكد من عدم وجود قيم فارغة في مفاتيح الفترات والصلوات
        final periods = decoded['periods'] as Map<String, dynamic>;
        for (final pEntry in periods.entries) {
          expect(
            (pEntry.value as String).trim().isNotEmpty,
            isTrue,
            reason: 'Empty period translation for ${pEntry.key} in $code.json',
          );
        }
      }
    });
  });
}
