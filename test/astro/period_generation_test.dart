import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  group('Property-Based Testing: Period Generation & Continuity', () {
    
    late IbadatTimings mockIbadat;
    final List<int> validDistribution = [5, 6, 9, 7, 3, 7, 11]; // مجموعها 48

    setUp(() {
      final now = DateTime(2026, 9, 8, 0, 0, 0);
      mockIbadat = IbadatTimings(
        fajr: now.add(const Duration(hours: 4)),
        sunrise: now.add(const Duration(hours: 5, minutes: 30)),
        dhuhr: now.add(const Duration(hours: 12)),
        asr: now.add(const Duration(hours: 15, minutes: 30)),
        maghrib: now.add(const Duration(hours: 18, minutes: 15)),
        isha: now.add(const Duration(hours: 19, minutes: 45)),
        nextFajr: now.add(const Duration(hours: 28, minutes: 10)), // فجر اليوم التالي
        nightParts: [],
      );
    });

    test('1. مجموع الفترات يجب أن يغطي الفجر إلى الفجر التالي بالضبط', () {
      final periods = PeriodGenerator.generatePeriods(mockIbadat, validDistribution);
      
      expect(periods.first.startTime, equals(mockIbadat.fajr));
      expect(periods.last.endTime, equals(mockIbadat.nextFajr));
    });

    test('2. الفترات متصلة تماماً (Contiguous) ولا يوجد أي فجوات زمنيّة (Gaps)', () {
      final periods = PeriodGenerator.generatePeriods(mockIbadat, validDistribution);
      
      for (int i = 0; i < periods.length - 1; i++) {
        final currentPeriod = periods[i];
        final nextPeriod = periods[i + 1];
        
        expect(
          currentPeriod.endTime, 
          equals(nextPeriod.startTime),
          reason: 'يجب أن تنتهي الفترة ${currentPeriod.name} في نفس لحظة بداية ${nextPeriod.name}',
        );
      }
    });

    test('3. لا يوجد أي تداخل زمني (Overlaps) بين الفترات', () {
      final periods = PeriodGenerator.generatePeriods(mockIbadat, validDistribution);
      
      for (int i = 0; i < periods.length - 1; i++) {
        expect(
          periods[i].endTime.isAfter(periods[i + 1].startTime), 
          isFalse,
          reason: 'اكتشاف تداخل زمني غير منطقي بين فترتين',
        );
      }
    });

    test('4. طول كل فترة زمني يجب أن يكون إيجابياً (لا يوجد وقت سالب)', () {
      final periods = PeriodGenerator.generatePeriods(mockIbadat, validDistribution);
      
      for (var period in periods) {
        final duration = period.endTime.difference(period.startTime);
        expect(duration.inMicroseconds, greaterThan(0));
      }
    });
  });
}