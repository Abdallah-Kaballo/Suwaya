import 'dart:convert';
import 'package:alarm/alarm.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';

/// 🌟 أنواع الأحداث الصريحة (مستقلة تماماً عن اللغة أو طريقة العرض)
enum AlarmEventKind {
  prayer,
  qiyam,
  task,
  habit,
  routine,
  unknown;

  static AlarmEventKind fromString(String? value) {
    for (final k in AlarmEventKind.values) {
      if (k.name == value) return k;
    }
    return AlarmEventKind.unknown;
  }
}

/// 🌟 طريقة تقديم التنبيه (مستقلة عن نوع الحدث)
enum AlarmDeliveryMode {
  notification,
  curtainAudio,
  fullscreenAlarm;

  static AlarmDeliveryMode fromString(String? value) {
    switch (value) {
      case 'notification':
        return AlarmDeliveryMode.notification;
      case 'curtain':
      case 'curtainAudio':
        return AlarmDeliveryMode.curtainAudio;
      case 'fullscreen':
      case 'fullscreenAlarm':
      default:
        return AlarmDeliveryMode.fullscreenAlarm;
    }
  }
}

/// 🌟 سياسة التحكم في الصوت أثناء الرنين
enum AlarmVolumePolicy {
  userAdjustable,
  enforced;

  static AlarmVolumePolicy fromString(String? value) {
    return value == 'enforced'
        ? AlarmVolumePolicy.enforced
        : AlarmVolumePolicy.userAdjustable;
  }
}

/// 🌟 السياسة المرجعية لكل نوع تنبيه (Single Source of Truth)
class AlarmTypePolicy {
  final AlarmEventKind kind;
  final bool loopAudioDefault;
  final bool snoozeAllowedDefault;
  final AlarmVolumePolicy volumePolicyDefault;
  final Duration fadeDuration;

  const AlarmTypePolicy({
    required this.kind,
    required this.loopAudioDefault,
    required this.snoozeAllowedDefault,
    required this.volumePolicyDefault,
    required this.fadeDuration,
  });
}

class AlarmPolicyTable {
  static AlarmTypePolicy forEvent({
    required AlarmEventKind kind,
    String? sourceId,
  }) {
    switch (kind) {
      case AlarmEventKind.prayer:
        final isFajr = sourceId?.toLowerCase() == 'fajr' || sourceId == '1';
        return AlarmTypePolicy(
          kind: AlarmEventKind.prayer,
          // الأذان يعمل مرة واحدة كاملاً ولا يتكرر تلقائياً حتى في وضع الشاشة الكاملة
          loopAudioDefault: false,
          // لا غفوة للأذان افتراضياً
          snoozeAllowedDefault: false,
          // السماح للمستخدم بخفض/رفع صوت الأذان بأزرار الهاتف
          volumePolicyDefault: AlarmVolumePolicy.userAdjustable,
          // تدرج هادئ 15 ثانية للفجر و6 ثوانٍ لبقية الصلوات
          fadeDuration: Duration(seconds: isFajr ? 15 : 6),
        );
      case AlarmEventKind.qiyam:
        return const AlarmTypePolicy(
          kind: AlarmEventKind.qiyam,
          loopAudioDefault: true,
          snoozeAllowedDefault: true,
          volumePolicyDefault: AlarmVolumePolicy.userAdjustable,
          fadeDuration: Duration(seconds: 10),
        );
      case AlarmEventKind.routine:
        return const AlarmTypePolicy(
          kind: AlarmEventKind.routine,
          loopAudioDefault: true,
          snoozeAllowedDefault: false,
          volumePolicyDefault: AlarmVolumePolicy.userAdjustable,
          fadeDuration: Duration(seconds: 4),
        );
      case AlarmEventKind.task:
      case AlarmEventKind.habit:
      case AlarmEventKind.unknown:
        return AlarmTypePolicy(
          kind: kind,
          loopAudioDefault: true,
          snoozeAllowedDefault: true,
          volumePolicyDefault: AlarmVolumePolicy.userAdjustable,
          fadeDuration: const Duration(seconds: 4),
        );
    }
  }
}

/// 🌟 النموذج الموحد لبيانات التنبيه (Schema V2) مع دعم كامل لقراءة الصيغ القديمة
class ParsedAlarmData {
  static const int currentSchemaVersion = 2;

  final int schemaVersion;
  final int eventId;
  final AlarmEventKind kind;
  final AlarmDeliveryMode deliveryMode;
  final String sourceId;
  final String title;
  final String body;
  final int colorValue;
  final bool snoozeAllowed;
  final int snoozeDurationMinutes;
  final int snoozeCount;
  final int maxSnoozes;
  final bool loopAudio;
  final AlarmVolumePolicy volumePolicy;

  const ParsedAlarmData({
    this.schemaVersion = currentSchemaVersion,
    required this.eventId,
    required this.kind,
    required this.deliveryMode,
    required this.sourceId,
    required this.title,
    required this.body,
    required this.colorValue,
    required this.snoozeAllowed,
    required this.snoozeDurationMinutes,
    required this.snoozeCount,
    required this.maxSnoozes,
    required this.loopAudio,
    required this.volumePolicy,
  });

  bool get isCurtainOnly => deliveryMode == AlarmDeliveryMode.curtainAudio;
  bool get canSnooze => snoozeAllowed && snoozeCount < maxSnoozes;

  ParsedAlarmData copyWith({
    int? eventId,
    int? snoozeCount,
    int? snoozeDurationMinutes,
    int? maxSnoozes,
    AlarmDeliveryMode? deliveryMode,
  }) {
    return ParsedAlarmData(
      schemaVersion: currentSchemaVersion,
      eventId: eventId ?? this.eventId,
      kind: kind,
      deliveryMode: deliveryMode ?? this.deliveryMode,
      sourceId: sourceId,
      title: title,
      body: body,
      colorValue: colorValue,
      snoozeAllowed: snoozeAllowed,
      snoozeDurationMinutes:
          snoozeDurationMinutes ?? this.snoozeDurationMinutes,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      maxSnoozes: maxSnoozes ?? this.maxSnoozes,
      loopAudio: loopAudio,
      volumePolicy: volumePolicy,
    );
  }

  String toPayloadString() {
    final map = <String, dynamic>{
      'v': schemaVersion,
      'eId': eventId,
      'k': kind.name,
      'm': deliveryMode.name,
      'sId': sourceId,
      't': title,
      'b': body,
      'c': colorValue,
      'sa': snoozeAllowed,
      'sd': snoozeDurationMinutes,
      'sc': snoozeCount,
      'ms': maxSnoozes,
      'l': loopAudio,
      'vp': volumePolicy.name,
    };
    return jsonEncode(map);
  }
}

class SnoozeResult {
  final bool success;
  final String? errorMessage;
  final DateTime? scheduledAt;

  const SnoozeResult({
    required this.success,
    this.errorMessage,
    this.scheduledAt,
  });
}

class AlarmService {
  static const int defaultMaxSnoozes = 3;
  static const int defaultSnoozeMinutes = 5;

  static Future<void> init() async {
    await Alarm.init();
  }

  /// 🌟 استنتاج نوع الحدث من نطاق المعرف الرقمي الحتمي عند قراءة بيانات قديمة لا تحتوي على kind
  static AlarmEventKind inferKindFromAlarmId(int id) {
    if (id >= 100000 && id < 200000) return AlarmEventKind.prayer;
    if (id >= 200000 && id < 300000) return AlarmEventKind.qiyam;
    if (id >= 300000 && id < 400000) return AlarmEventKind.routine;
    if (id >= 400000 && id < 600000) return AlarmEventKind.task;
    return AlarmEventKind.unknown;
  }

  /// 🌟 تحليل آمن يدعم JSON V2 والصيغ القديمة (curtain|... / fullscreen|...) والبيانات الفارغة
  static ParsedAlarmData parseAlarmSettings(AlarmSettings settings) {
    final notifTitle = settings.notificationSettings.title;
    final notifBody = settings.notificationSettings.body;

    final fallbackTitle =
        notifTitle.isNotEmpty ? notifTitle : 'alarm.default_title'.tr();
    final fallbackBody =
        notifBody.isNotEmpty ? notifBody : 'alarm.swipe_to_stop'.tr();

    final inferredKind = inferKindFromAlarmId(settings.id);
    final defaultPolicy = AlarmPolicyTable.forEvent(kind: inferredKind);

    final rawPayload = settings.payload?.trim();
    if (rawPayload == null || rawPayload.isEmpty) {
      return ParsedAlarmData(
        eventId: settings.id,
        kind: inferredKind,
        deliveryMode: settings.androidFullScreenIntent
            ? AlarmDeliveryMode.fullscreenAlarm
            : AlarmDeliveryMode.curtainAudio,
        sourceId: settings.id.toString(),
        title: fallbackTitle,
        body: fallbackBody,
        colorValue: 0xFFD4AF37,
        snoozeAllowed: defaultPolicy.snoozeAllowedDefault,
        snoozeDurationMinutes: defaultSnoozeMinutes,
        snoozeCount: 0,
        maxSnoozes: defaultMaxSnoozes,
        loopAudio: settings.loopAudio,
        volumePolicy: defaultPolicy.volumePolicyDefault,
      );
    }

    // 1. محاولة قراءة مخطط V2 JSON الجديد
    if (rawPayload.startsWith('{')) {
      try {
        final decoded = jsonDecode(rawPayload) as Map<String, dynamic>;
        final kind = AlarmEventKind.fromString(decoded['k'] as String?);
        final effectiveKind =
            kind == AlarmEventKind.unknown ? inferredKind : kind;
        final policy = AlarmPolicyTable.forEvent(
          kind: effectiveKind,
          sourceId: decoded['sId'] as String?,
        );
        final parsedTitle = (decoded['t'] as String?)?.trim();
        final parsedBody = (decoded['b'] as String?)?.trim();

        return ParsedAlarmData(
          schemaVersion: (decoded['v'] as int?) ?? 2,
          eventId: (decoded['eId'] as int?) ?? settings.id,
          kind: effectiveKind,
          deliveryMode: AlarmDeliveryMode.fromString(decoded['m'] as String?),
          sourceId: (decoded['sId'] as String?) ?? settings.id.toString(),
          title: (parsedTitle != null && parsedTitle.isNotEmpty)
              ? parsedTitle
              : fallbackTitle,
          body: (parsedBody != null && parsedBody.isNotEmpty)
              ? parsedBody
              : fallbackBody,
          colorValue: (decoded['c'] as int?) ?? 0xFFD4AF37,
          snoozeAllowed:
              (decoded['sa'] as bool?) ?? policy.snoozeAllowedDefault,
          snoozeDurationMinutes:
              ((decoded['sd'] as int?) ?? defaultSnoozeMinutes).clamp(1, 120),
          snoozeCount: ((decoded['sc'] as int?) ?? 0).clamp(0, 99),
          maxSnoozes: ((decoded['ms'] as int?) ?? defaultMaxSnoozes).clamp(0, 20),
          loopAudio: (decoded['l'] as bool?) ?? policy.loopAudioDefault,
          volumePolicy: AlarmVolumePolicy.fromString(decoded['vp'] as String?),
        );
      } catch (e) {
        debugPrint('⚠️ Fallback to legacy payload parser: $e');
      }
    }

    // 2. التوافق العكسي مع الصيغة القديمة: (curtain|title|color|snooze) أو (fullscreen|title|color|snooze)
    final isLegacyCurtain = rawPayload.startsWith('curtain|');
    final cleanPayload = rawPayload.replaceFirst(
      RegExp(r'^(curtain|fullscreen)\|'),
      '',
    );
    final parts = cleanPayload.split('|');

    final payloadTitle =
        (parts.isNotEmpty && parts[0].isNotEmpty && parts[0] != 'تنبيه')
            ? parts[0]
            : fallbackTitle;
    final colorVal = parts.length > 1
        ? (int.tryParse(parts[1]) ?? 0xFFD4AF37)
        : 0xFFD4AF37;
    final snoozes =
        parts.length > 2 ? (int.tryParse(parts[2]) ?? 0).clamp(0, 99) : 0;

    return ParsedAlarmData(
      schemaVersion: 1,
      eventId: settings.id,
      kind: inferredKind,
      deliveryMode: isLegacyCurtain
          ? AlarmDeliveryMode.curtainAudio
          : AlarmDeliveryMode.fullscreenAlarm,
      sourceId: settings.id.toString(),
      title: payloadTitle,
      body: fallbackBody,
      colorValue: colorVal,
      snoozeAllowed: defaultPolicy.snoozeAllowedDefault,
      snoozeDurationMinutes: defaultSnoozeMinutes,
      snoozeCount: snoozes,
      maxSnoozes: defaultMaxSnoozes,
      loopAudio: settings.loopAudio,
      volumePolicy: defaultPolicy.volumePolicyDefault,
    );
  }

  /// 🌟 جدولة منبه موحد مع التحقق من النتيجة
  static Future<bool> scheduleAlarm({
    required int id,
    required DateTime dateTime,
    required AlarmEventKind kind,
    required String sourceId,
    required String title,
    required String body,
    required int colorValue,
    required String tonePath,
    required double volume,
    AlarmDeliveryMode deliveryMode = AlarmDeliveryMode.fullscreenAlarm,
    bool? loopAudioOverride,
    bool? snoozeAllowedOverride,
    int snoozeDurationMinutes = defaultSnoozeMinutes,
    int maxSnoozes = defaultMaxSnoozes,
    bool vibrate = true,
  }) async {
    DateTime safeTime = dateTime;
    if (safeTime.isBefore(DateTime.now())) {
      safeTime = safeTime.add(const Duration(days: 1));
    }

    final policy = AlarmPolicyTable.forEvent(kind: kind, sourceId: sourceId);
    final effectiveLoop = loopAudioOverride ?? policy.loopAudioDefault;
    final effectiveSnoozeAllowed =
        snoozeAllowedOverride ?? policy.snoozeAllowedDefault;
    final isFullscreen = deliveryMode == AlarmDeliveryMode.fullscreenAlarm;
    final enforceVolume =
        policy.volumePolicyDefault == AlarmVolumePolicy.enforced;

    final payloadData = ParsedAlarmData(
      eventId: id,
      kind: kind,
      deliveryMode: deliveryMode,
      sourceId: sourceId,
      title: title,
      body: body,
      colorValue: colorValue,
      snoozeAllowed: effectiveSnoozeAllowed,
      snoozeDurationMinutes: snoozeDurationMinutes,
      snoozeCount: 0,
      maxSnoozes: maxSnoozes,
      loopAudio: effectiveLoop,
      volumePolicy: policy.volumePolicyDefault,
    );

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: safeTime,
      assetAudioPath: tonePath,
      loopAudio: effectiveLoop,
      vibrate: vibrate,
      androidFullScreenIntent: isFullscreen,
      payload: payloadData.toPayloadString(),
      volumeSettings: VolumeSettings.fade(
        volume: volume.clamp(0.05, 1.0),
        fadeDuration: policy.fadeDuration,
        volumeEnforced: enforceVolume,
      ),
      notificationSettings: NotificationSettings(
        title: title,
        body: body,
        stopButton: 'alarm.stop'.tr(),
      ),
    );

    try {
      return await Alarm.set(alarmSettings: alarmSettings);
    } catch (e) {
      debugPrint('🚨 AlarmService.scheduleAlarm failed for ID $id: $e');
      return false;
    }
  }

  /// 🌟 غفوة ذرية آمنة: لا توقف المنبه الأصلي ولا تعيد النجاح إلا إذا ثبتت جدولة الغفوة الجديدة فعلياً
  static Future<SnoozeResult> snooze(
    AlarmSettings currentSettings, {
    int? snoozeMinutesOverride,
    int? maxSnoozesOverride,
  }) async {
    final parsed = parseAlarmSettings(currentSettings);

    final effectiveMaxSnoozes = maxSnoozesOverride ?? parsed.maxSnoozes;
    final effectiveSnoozeMins =
        (snoozeMinutesOverride ?? parsed.snoozeDurationMinutes).clamp(1, 120);

    if (!parsed.snoozeAllowed) {
      return const SnoozeResult(
        success: false,
        errorMessage: 'Snooze is not enabled for this alert type.',
      );
    }

    if (parsed.snoozeCount >= effectiveMaxSnoozes) {
      return const SnoozeResult(
        success: false,
        errorMessage: 'Maximum snooze limit reached.',
      );
    }

    final targetTime = DateTime.now().add(
      Duration(minutes: effectiveSnoozeMins),
    );

    final updatedPayload = parsed
        .copyWith(
          snoozeCount: parsed.snoozeCount + 1,
          snoozeDurationMinutes: effectiveSnoozeMins,
          maxSnoozes: effectiveMaxSnoozes,
        )
        .toPayloadString();

    final newSettings = currentSettings.copyWith(
      dateTime: targetTime,
      payload: () => updatedPayload,
    );

    try {
      // في حزمة alarm، إعادة استدعاء Alarm.set بنفس الـ id يستبدل المنبه الحالي بالموعد الجديد بأمان
      final isScheduled = await Alarm.set(alarmSettings: newSettings);
      if (!isScheduled) {
        return const SnoozeResult(
          success: false,
          errorMessage: 'Failed to schedule snoozed alarm.',
        );
      }
      return SnoozeResult(success: true, scheduledAt: targetTime);
    } catch (e) {
      debugPrint('🚨 AlarmService.snooze error: $e');
      return SnoozeResult(success: false, errorMessage: e.toString());
    }
  }
}