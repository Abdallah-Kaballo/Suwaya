import 'package:alarm/alarm.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya/core/notification/scheduler_service.dart';
import 'package:suwaya/core/services/alarm_service.dart';

AlarmSettings _mockAlarmSettings({
  required int id,
  String? payload,
  bool fullScreen = true,
  bool loopAudio = false,
  String title = 'Fajr',
  String body = 'Time for prayer',
}) {
  return AlarmSettings(
    id: id,
    dateTime: DateTime(2026, 10, 21, 5, 0),
    assetAudioPath: 'assets/audio/adhan.mp3',
    loopAudio: loopAudio,
    vibrate: true,
    androidFullScreenIntent: fullScreen,
    payload: payload,
    volumeSettings: VolumeSettings.fade(
      volume: 1.0,
      fadeDuration: const Duration(seconds: 6),
      volumeEnforced: false,
    ),
    notificationSettings: NotificationSettings(
      title: title,
      body: body,
      stopButton: 'Stop',
    ),
  );
}

void main() {
  group('AlarmPayload Schema V2 & Legacy Compatibility Tests', () {
    test('Serializes and parses V2 JSON payload accurately independent of language', () {
      const original = ParsedAlarmData(
        eventId: 101001,
        kind: AlarmEventKind.prayer,
        deliveryMode: AlarmDeliveryMode.fullscreenAlarm,
        sourceId: 'fajr',
        title: 'صلاة الفجر',
        body: 'حان الآن موعد الأذان',
        colorValue: 0xFFD4AF37,
        snoozeAllowed: false,
        snoozeDurationMinutes: 10,
        snoozeCount: 0,
        maxSnoozes: 0,
        loopAudio: false,
        volumePolicy: AlarmVolumePolicy.userAdjustable,
      );

      final encoded = original.toPayloadString();
      final settings = _mockAlarmSettings(id: 101001, payload: encoded);
      final parsed = AlarmService.parseAlarmSettings(settings);

      expect(parsed.schemaVersion, 2);
      expect(parsed.eventId, 101001);
      expect(parsed.kind, AlarmEventKind.prayer);
      expect(parsed.deliveryMode, AlarmDeliveryMode.fullscreenAlarm);
      expect(parsed.sourceId, 'fajr');
      expect(parsed.snoozeAllowed, isFalse);
      expect(parsed.canSnooze, isFalse);
      expect(parsed.loopAudio, isFalse);
      expect(parsed.volumePolicy, AlarmVolumePolicy.userAdjustable);
    });

    test('Parses legacy V1 pipe-delimited curtain and fullscreen payloads safely', () {
      final legacyCurtain = _mockAlarmSettings(
        id: 101003,
        payload: 'curtain|Dhuhr Prayer|0xFFD4AF37|0',
        fullScreen: false,
      );
      final parsedCurtain = AlarmService.parseAlarmSettings(legacyCurtain);

      expect(parsedCurtain.schemaVersion, 1);
      expect(parsedCurtain.kind, AlarmEventKind.prayer);
      expect(parsedCurtain.isCurtainOnly, isTrue);
      expect(parsedCurtain.snoozeAllowed, isFalse);

      final legacyTask = _mockAlarmSettings(
        id: 401021,
        payload: 'fullscreen|Read Quran|0xFF00E5FF|2',
        fullScreen: true,
      );
      final parsedTask = AlarmService.parseAlarmSettings(legacyTask);

      expect(parsedTask.kind, AlarmEventKind.task);
      expect(parsedTask.isCurtainOnly, isFalse);
      expect(parsedTask.snoozeAllowed, isTrue);
      expect(parsedTask.snoozeCount, 2);
      expect(parsedTask.canSnooze, isTrue);
    });

    test('Handles missing or malformed payload gracefully using deterministic ID range', () {
      final noPayloadRoutine = _mockAlarmSettings(
        id: 302005,
        payload: null,
        title: 'Morning Routine',
      );
      final parsed = AlarmService.parseAlarmSettings(noPayloadRoutine);

      expect(parsed.kind, AlarmEventKind.routine);
      expect(parsed.snoozeAllowed, isFalse);
      expect(parsed.title, 'Morning Routine');
    });
  });

  group('AlarmPolicyTable Invariants Tests', () {
    test('Adhan policy never loops audio, disallows snooze, and allows user volume control', () {
      final fajrPolicy = AlarmPolicyTable.forEvent(
        kind: AlarmEventKind.prayer,
        sourceId: 'fajr',
      );
      final maghribPolicy = AlarmPolicyTable.forEvent(
        kind: AlarmEventKind.prayer,
        sourceId: 'maghrib',
      );

      expect(fajrPolicy.loopAudioDefault, isFalse);
      expect(fajrPolicy.snoozeAllowedDefault, isFalse);
      expect(fajrPolicy.volumePolicyDefault, AlarmVolumePolicy.userAdjustable);
      expect(fajrPolicy.fadeDuration, const Duration(seconds: 15));
      expect(maghribPolicy.fadeDuration, const Duration(seconds: 6));
    });

    test('Tasks and Habits allow snooze and loop audio by default', () {
      final taskPolicy = AlarmPolicyTable.forEvent(kind: AlarmEventKind.task);
      expect(taskPolicy.loopAudioDefault, isTrue);
      expect(taskPolicy.snoozeAllowedDefault, isTrue);
    });
  });

  group('Scheduler Deterministic IDs & Same-Second Collision Resolution', () {
    test('stableNightPartCode produces unique, deterministic integers for all 5 Qiyam parts', () {
      const canonicalParts = [
        'half_2',
        'third_3',
        'sixth_4',
        'sixth_5',
        'sixth_6',
      ];
      final codes = canonicalParts
          .map(NotificationScheduler.stableNightPartCode)
          .toSet();
      expect(codes.length, canonicalParts.length);
    });

    test('resolveCollisionSafeTime keeps first event at +0s and staggers coinciding events by +2s', () {
      final occupied = <int>{};
      final baseTime = DateTime(2026, 10, 21, 18, 15, 0);

      final prayerTime = NotificationScheduler.resolveCollisionSafeTime(
        baseTime,
        occupied,
      );
      final coincidingRoutineTime =
          NotificationScheduler.resolveCollisionSafeTime(
        baseTime,
        occupied,
      );
      final coincidingTaskTime = NotificationScheduler.resolveCollisionSafeTime(
        baseTime,
        occupied,
      );

      expect(prayerTime, baseTime);
      expect(
        coincidingRoutineTime,
        baseTime.add(const Duration(seconds: 2)),
      );
      expect(
        coincidingTaskTime,
        baseTime.add(const Duration(seconds: 4)),
      );
    });
  });
}