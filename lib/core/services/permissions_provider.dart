import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionsState {
  final PermissionStatus location;
  final PermissionStatus notification;
  final PermissionStatus exactAlarm;

  PermissionsState({
    this.location = PermissionStatus.denied,
    this.notification = PermissionStatus.denied,
    this.exactAlarm = PermissionStatus.denied,
  });

  PermissionsState copyWith({
    PermissionStatus? location,
    PermissionStatus? notification,
    PermissionStatus? exactAlarm,
  }) {
    return PermissionsState(
      location: location ?? this.location,
      notification: notification ?? this.notification,
      exactAlarm: exactAlarm ?? this.exactAlarm,
    );
  }
}

class PermissionsNotifier extends Notifier<PermissionsState> {
  @override
  PermissionsState build() {
    checkAllPermissions();
    return PermissionsState();
  }

  Future<void> checkAllPermissions() async {
    final location = await Permission.location.status;
    final notification = await Permission.notification.status;
    PermissionStatus exactAlarm = PermissionStatus.granted; 
    if (Platform.isAndroid) {
      exactAlarm = await Permission.scheduleExactAlarm.status;
    }
    state = state.copyWith(location: location, notification: notification, exactAlarm: exactAlarm);
  }

  // 🌟 1. الطلب الاستباقي: يُستدعى مرة واحدة فقط عند أول فتح للتطبيق
  Future<void> requestInitialPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final hasRequested = prefs.getBool('has_requested_initial_perms') ?? false;
    
    if (!hasRequested) {
      // نطلب الإشعارات أولاً لأنها الأهم
      await Permission.notification.request();
      if (Platform.isAndroid) await Permission.scheduleExactAlarm.request();
      
      // نطلب الموقع
      await Permission.location.request();
      
      await prefs.setBool('has_requested_initial_perms', true);
      await checkAllPermissions();
    }
  }

  // 🌟 2. الطلب التفاعلي: يضمن وجود الإشعار قبل التفعيل، ويوجه للإعدادات إذا كان مرفوضاً نهائياً
  Future<bool> ensureNotificationPermission() async {
    var status = await Permission.notification.status;
    if (!status.isGranted) status = await Permission.notification.request();
    if (status.isPermanentlyDenied) await openAppSettings();
    await checkAllPermissions();
    return status.isGranted || await Permission.notification.isGranted;
  }

  // 🌟 3. الطلب التفاعلي: يضمن وجود المنبهات الدقيقة
  Future<bool> ensureExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    var status = await Permission.scheduleExactAlarm.status;
    if (!status.isGranted) status = await Permission.scheduleExactAlarm.request();
    if (status.isPermanentlyDenied) await openAppSettings();
    await checkAllPermissions();
    return status.isGranted || await Permission.scheduleExactAlarm.isGranted;
  }

  // 🌟 4. الطلب التفاعلي: يضمن وجود الموقع قبل تفعيل الـ GPS
  Future<bool> ensureLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) status = await Permission.location.request();
    if (status.isPermanentlyDenied) await openAppSettings();
    await checkAllPermissions();
    return status.isGranted || await Permission.location.isGranted;
  }
}

final permissionsProvider = NotifierProvider<PermissionsNotifier, PermissionsState>(PermissionsNotifier.new);