import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

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

    state = state.copyWith(
      location: location,
      notification: notification,
      exactAlarm: exactAlarm,
    );
  }

  Future<bool> ensureNotificationPermission({
    bool openSettingsIfDenied = true,
  }) async {
    var status = await Permission.notification.status;
    if (status.isGranted) return true;

    status = await Permission.notification.request();
    if (!status.isGranted && openSettingsIfDenied) {
      await openAppSettings();
    }
    await checkAllPermissions();
    return await Permission.notification.isGranted;
  }

  Future<bool> ensureExactAlarmPermission({
    bool openSettingsIfDenied = true,
  }) async {
    if (!Platform.isAndroid) return true;

    var status = await Permission.scheduleExactAlarm.status;
    if (status.isGranted) return true;

    status = await Permission.scheduleExactAlarm.request();
    if (!status.isGranted && openSettingsIfDenied) {
      await openAppSettings();
    }
    await checkAllPermissions();
    return await Permission.scheduleExactAlarm.isGranted;
  }

  Future<bool> ensureLocationPermission({
    bool openSettingsIfDenied = true,
  }) async {
    var status = await Permission.location.status;
    if (status.isGranted) return true;

    status = await Permission.location.request();
    if (status.isPermanentlyDenied && openSettingsIfDenied) {
      await openAppSettings();
    }
    await checkAllPermissions();
    return await Permission.location.isGranted;
  }
}

final permissionsProvider =
    NotifierProvider<PermissionsNotifier, PermissionsState>(
      PermissionsNotifier.new,
    );
