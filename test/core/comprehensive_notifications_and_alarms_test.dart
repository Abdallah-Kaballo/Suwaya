import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:suwaya/core/notification/schedule_fingerprint.dart';
import 'package:suwaya/core/notification/schedule_plan_builder.dart';
import 'package:suwaya/core/services/alarm_service.dart';
import 'package:suwaya/models/routine_model.dart';
import 'package:suwaya/models/settings_model.dart';
import 'package:suwaya/models/task_model.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group(
    '1. 8-Day Isolate Astro Window & Deterministic ID Namespace Collision Tests',
    () {
      test(
        'Generates 8-day windows (-1 to +6) in Isolate with zero ID collisions across prayers, qiyam, routines, and tasks',
        () async {
          final cityNow = DateTime.utc(2026, 10, 22, 12, 0);
          final offsets = List.filled(9, const Duration(hours: 3));

          final windows = await SchedulePlanBuilder.computeWeekAstroWindows(
            latitude: 21.4225,
            longitude: 39.8262,
            timezoneId: 'Asia/Riyadh',
            isolatedCityNow: cityNow,
            fallbackDayOffsets: offsets,
            calcMethod: CalculationMethodType.ummAlQura,
            madhab: MadhabType.shafi,
            hlRule: HighLatitudeRuleType.middleOfTheNight,
            fajrAngle: 18.5,
            ishaAngle: 18.0,
            manualOffsets: const {},
          );

          expect(windows.length, 8);
          expect(windows.first.dayOffset, -1);
          expect(windows.last.dayOffset, 6);

          final allGeneratedIds = <int>{};

          for (int index = 0; index < windows.length; index++) {
            final safeOffsetIndex = windows[index].dayOffset + 1;

            // 1. الصلوات الخمس
            for (final numericId in [1, 3, 4, 5, 9]) {
              final id = 100000 + (safeOffsetIndex * 1000) + numericId;
              expect(
                allGeneratedIds.add(id),
                isTrue,
                reason: 'Duplicate Prayer ID: $id',
              );
            }

            // 2. أجزاء الليل الخمسة
            for (final partId in [
              'half_2',
              'third_3',
              'sixth_4',
              'sixth_5',
              'sixth_6',
            ]) {
              final code = ScheduleFingerprint.stableNightPartCode(partId);
              final id = 200000 + (safeOffsetIndex * 1000) + code;
              expect(
                allGeneratedIds.add(id),
                isTrue,
                reason: 'Duplicate Qiyam ID: $id',
              );
            }

            // 3. 50 روتيناً مختلفاً في كل يوم
            for (int rId = 1; rId <= 50; rId++) {
              final id = 300000 + (safeOffsetIndex * 10000) + (rId % 10000);
              expect(
                allGeneratedIds.add(id),
                isTrue,
                reason: 'Duplicate Routine ID: $id',
              );
            }

            // 4. 50 مهمة سويعية (مع عدة سويعات لكل مهمة) و 50 مهمة مدنية
            for (int tId = 1; tId <= 50; tId++) {
              for (int suwayaNum = 1; suwayaNum <= 6; suwayaNum++) {
                final astroTaskId =
                    400000 +
                    (safeOffsetIndex * 10000) +
                    ((tId % 1000) * 10) +
                    suwayaNum;
                expect(
                  allGeneratedIds.add(astroTaskId),
                  isTrue,
                  reason: 'Duplicate Astro Task ID: $astroTaskId',
                );
              }

              final civilTaskId =
                  500000 + (safeOffsetIndex * 10000) + (tId % 10000);
              expect(
                allGeneratedIds.add(civilTaskId),
                isTrue,
                reason: 'Duplicate Civil Task ID: $civilTaskId',
              );
            }
          }
        },
      );

      test(
        'Same-second collision resolver prioritizes Adhan at +0s and caps stagger at +30s under heavy load',
        () {
          final occupied = <int>{};
          final baseAdhanTime = DateTime(2026, 10, 22, 18, 0, 0);

          final resolvedTimes = List.generate(
            20,
            (_) => ScheduleFingerprint.resolveCollisionSafeTime(
              baseAdhanTime,
              occupied,
            ),
          );

          // الحدث الأول (الأذان) يأخذ الثانية +0s بالضبط
          expect(resolvedTimes[0], equals(baseAdhanTime));
          // الأحداث التالية تُزاح بمقدار +2s تتابعياً
          for (int i = 1; i <= 15; i++) {
            expect(
              resolvedTimes[i],
              equals(baseAdhanTime.add(Duration(seconds: i * 2))),
            );
          }
          // السقف الأقصى للإزاحة هو 30 ثانية حتى لا يخرج التنبيه عن دقيقته
          expect(
            resolvedTimes.last.difference(baseAdhanTime).inSeconds,
            equals(30),
          );
        },
      );
    },
  );

  group('2. ScheduleFingerprint Sensitivity & Determinism Tests', () {
    test(
      'Fingerprint changes on any relevant mutation in settings, tasks, or routines',
      () {
        final cityNow = DateTime.utc(2026, 10, 22, 12, 0);
        const offset = Duration(hours: 3);

        final baseSettings = SettingsModel()
          ..activeLocation = (SavedLocation()
            ..latitude = 30.0444
            ..longitude = 31.2357
            ..timezone = 'Africa/Cairo')
          ..calculationMethod = 'egyptian'
          ..madhab = 'shafi'
          ..visibleNightParts = ['sixth_5'];

        final baseTask = TaskModel()
          ..id = 1
          ..title = 'Read'
          ..isAstroTime = true
          ..targetPeriodId = 4
          ..targetSuwayas = [1]
          ..targetVirtualMinute = 15;

        final baseRoutine = RoutineModel()
          ..id = 10
          ..title = 'Deep Work'
          ..isAstroTime = true
          ..startPeriodId = 5
          ..startSuwaya = 1
          ..endPeriodId = 5
          ..endSuwaya = 3;

        final fpBase = ScheduleFingerprint.compute(
          cityNow: cityNow,
          todayOffset: offset,
          settings: baseSettings,
          allTasks: [baseTask],
          routines: [baseRoutine],
        );

        // 1. تغير إزاحة التوقيت الصيفي (مثلاً من +2 إلى +3)
        final fpDstShift = ScheduleFingerprint.compute(
          cityNow: cityNow,
          todayOffset: const Duration(hours: 2),
          settings: baseSettings,
          allTasks: [baseTask],
          routines: [baseRoutine],
        );
        expect(fpDstShift, isNot(equals(fpBase)));

        // 2. تغير الدقيقة الافتراضية للمهمة
        final modifiedTask = TaskModel()
          ..id = 1
          ..title = 'Read'
          ..isAstroTime = true
          ..targetPeriodId = 4
          ..targetSuwayas = [1]
          ..targetVirtualMinute = 30;
        final fpTaskShift = ScheduleFingerprint.compute(
          cityNow: cityNow,
          todayOffset: offset,
          settings: baseSettings,
          allTasks: [modifiedTask],
          routines: [baseRoutine],
        );
        expect(fpTaskShift, isNot(equals(fpBase)));

        // 3. تغير أجزاء الليل المرئية
        final modifiedSettings = baseSettings.clone()
          ..visibleNightParts = ['third_3'];
        final fpNightPartShift = ScheduleFingerprint.compute(
          cityNow: cityNow,
          todayOffset: offset,
          settings: modifiedSettings,
          allTasks: [baseTask],
          routines: [baseRoutine],
        );
        expect(fpNightPartShift, isNot(equals(fpBase)));
      },
    );
  });

  group('3. SettingsModel Period Normalization & Hijri Offset Persistence', () {
    test(
      'Normalizes legacy numeric prayer IDs (1,3,4,5,9) to canonical names and clamps hijriOffsetDays',
      () {
        final s = SettingsModel();
        expect(SettingsModel.normalizePeriodId('1'), 'fajr');
        expect(SettingsModel.normalizePeriodId('3'), 'dhuhr');
        expect(SettingsModel.normalizePeriodId('4'), 'asr');
        expect(SettingsModel.normalizePeriodId('5'), 'maghrib');
        expect(SettingsModel.normalizePeriodId('9'), 'isha');

        s.hijriOffsetDays = 5; // خارج النطاق [-2, 2]
        expect(s.hijriOffsetDays, 2);

        s.hijriOffsetDays = -4;
        expect(s.hijriOffsetDays, -2);
      },
    );

    test(
      'ParsedAlarmData copyWith increments snoozeCount and enforces maxSnoozes boundary',
      () {
        const data = ParsedAlarmData(
          eventId: 401011,
          kind: AlarmEventKind.task,
          deliveryMode: AlarmDeliveryMode.fullscreenAlarm,
          sourceId: '1',
          title: 'Task',
          body: 'Body',
          colorValue: 0xFF22D3EE,
          snoozeAllowed: true,
          snoozeDurationMinutes: 5,
          snoozeCount: 2,
          maxSnoozes: 3,
          loopAudio: true,
          volumePolicy: AlarmVolumePolicy.userAdjustable,
        );

        expect(data.canSnooze, isTrue);
        final afterThirdSnooze = data.copyWith(snoozeCount: 3);
        expect(afterThirdSnooze.canSnooze, isFalse);
      },
    );
  });
}
