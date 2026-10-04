import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:suwaya/features/tasks/routine_schedule_format.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  test('formats civil routine time as fixed 24-hour HH:mm', () {
    expect(formatCivilRoutineTime(5 * 60 + 7, 'en'), '05:07');
    expect(formatCivilRoutineTime(16 * 60 + 5, 'en'), '16:05');
  });

  test('shows daily when recurrence days are empty', () {
    expect(formatRoutineRecurrence(null, 'en'), isNull);
    expect(formatRoutineRecurrence([], 'en'), isNull);
  });

  test('lists localized weekday abbreviations in weekday order', () {
    expect(formatRoutineRecurrence([5, 1, 3, 1], 'en'), 'Mon, Wed, Fri');
    expect(formatRoutineRecurrence([1, 7], 'ar'), isNotEmpty);
  });
}
