import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/services/permissions_provider.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() => ref.read(permissionsProvider.notifier).checkAllPermissions());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionsProvider.notifier).checkAllPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final permState = ref.watch(permissionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).cardColor;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('permissions.title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          Text(
            'permissions.desc'.tr(),
            style: const TextStyle(height: 1.5, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          _buildPermissionCard(
            title: 'permissions.location'.tr(),
            description: 'permissions.location_desc'.tr(),
            icon: LucideIcons.map_pin,
            status: permState.location,
            onAction: () => ref.read(permissionsProvider.notifier).ensureLocationPermission(),
            isDark: isDark, surfaceColor: surfaceColor, primaryColor: primaryColor,
          ),

          _buildPermissionCard(
            title: 'permissions.notifications'.tr(),
            description: 'permissions.notifications_desc'.tr(),
            icon: LucideIcons.bell,
            status: permState.notification,
            onAction: () => ref.read(permissionsProvider.notifier).ensureNotificationPermission(),
            isDark: isDark, surfaceColor: surfaceColor, primaryColor: primaryColor,
          ),

          _buildPermissionCard(
            title: 'permissions.exact_alarms'.tr(),
            description: 'permissions.exact_alarms_desc'.tr(),
            icon: LucideIcons.alarm_clock,
            status: permState.exactAlarm,
            onAction: () => ref.read(permissionsProvider.notifier).ensureExactAlarmPermission(),
            isDark: isDark, surfaceColor: surfaceColor, primaryColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title, required String description, required IconData icon,
    required PermissionStatus status, required VoidCallback onAction,
    required bool isDark, required Color surfaceColor, required Color primaryColor,
  }) {
    final isGranted = status.isGranted;
    final isPermanentlyDenied = status.isPermanentlyDenied;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isGranted ? Colors.green.withValues(alpha: 0.5) : (isDark ? Colors.white12 : Colors.black12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: isGranted ? Colors.green.withValues(alpha: 0.1) : primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: isGranted ? Colors.green : primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(isGranted ? Icons.check_circle : Icons.error, size: 14, color: isGranted ? Colors.green : Colors.red),
                        const SizedBox(width: 4),
                        Text(isGranted ? 'permissions.granted'.tr() : 'permissions.not_granted'.tr(), style: TextStyle(color: isGranted ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12, height: 1.5)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isGranted ? null : onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: isGranted ? (isDark ? Colors.grey[800] : Colors.grey[200]) : primaryColor,
                foregroundColor: isGranted ? Colors.grey : Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isGranted ? 'permissions.active'.tr() : (isPermanentlyDenied ? 'permissions.open_settings'.tr() : 'permissions.grant'.tr()), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}