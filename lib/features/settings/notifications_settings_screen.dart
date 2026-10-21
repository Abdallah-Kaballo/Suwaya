import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import 'settings_provider.dart';
import '../../core/location/permissions_provider.dart';

class NotificationsSettingsScreen extends ConsumerStatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  ConsumerState<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends ConsumerState<NotificationsSettingsScreen> {
  late final Map<String, String> _availableTones;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _availableTones = {
      'assets/audio/default.mp3': 'alerts.default_ring'.tr(),
      'assets/audio/adhan.mp3': 'alerts.makkah_adhan'.tr(),
      'assets/audio/soft.mp3': 'alerts.soft_bell'.tr(),
      'assets/audio/birds.mp3': 'alerts.birds'.tr(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final accentColor = Theme.of(context).primaryColor;

    final int prayersLevel = settings.getPeriodAlertLevel('1', 0);
    final String prayersTone = settings.getPeriodSound('1', 'assets/audio/adhan.mp3');
    final double prayersVolume = settings.getPeriodVolume('1', 1.0);

    final int qiyamLevel = settings.getPeriodAlertLevel('third_3', 0);
    final String qiyamTone = settings.getPeriodSound('third_3', 'assets/audio/soft.mp3');
    final double qiyamVolume = settings.getPeriodVolume('third_3', 0.5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(LucideIcons.arrow_right, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'notifications.title'.tr(),
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // 🌟 قسم الصلوات المفروضة
          _buildPremiumCard(
            context: context, isDark: isDark, surfaceColor: surfaceColor, textColor: textColor, accentColor: accentColor,
            icon: LucideIcons.moon_star,
            title: 'notifications.prayers'.tr(),
            subtitle: 'notifications.prayers_desc'.tr(),
            currentLevel: prayersLevel,
            currentTone: prayersTone,
            currentVolume: prayersVolume,
            onSave: (level, tone, vol) async {
              if (level > 0) await _requestPermissions(ref);
              final ids = ['1', '3', '4', '5', 'isha'];
              for (var id in ids) {
                ref.read(settingsProvider.notifier).updatePeriodNotificationSettings(periodId: id, isEnabled: true, alertLevel: level, soundPath: tone, volume: vol);
              }
            },
          ),
          
          const SizedBox(height: 20),

          // 🌟 قسم قيام الليل (الأجزاء الخمسة للنصف الثاني من الليل فقط)
          _buildPremiumCard(
            context: context, isDark: isDark, surfaceColor: surfaceColor, textColor: textColor, accentColor: const Color(0xFF8B5CF6),
            icon: LucideIcons.sparkles,
            title: 'notifications.qiyam'.tr(),
            subtitle: 'notifications.qiyam_desc'.tr(),
            currentLevel: qiyamLevel,
            currentTone: qiyamTone,
            currentVolume: qiyamVolume,
            isFadeInForced: true,
            onSave: (level, tone, vol) async {
              if (level > 0) await _requestPermissions(ref);
              const nightIds = ['half_2', 'third_3', 'sixth_4', 'sixth_5', 'sixth_6'];
              for (var id in nightIds) {
                ref.read(settingsProvider.notifier).updatePeriodNotificationSettings(periodId: id, isEnabled: true, alertLevel: level, soundPath: tone, volume: vol);
              }
            },
          ),

          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text('notifications.productivity'.tr(), style: TextStyle(color: textColor.withValues(alpha: 0.5), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
          ),

          // 🌟 قسم الإنتاجية (المهام والعادات)
          _buildDefaultsSection(settings, isDark, surfaceColor, textColor, accentColor),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _requestPermissions(WidgetRef ref) async {
    final perms = ref.read(permissionsProvider.notifier);
    await perms.ensureNotificationPermission();
    await perms.ensureExactAlarmPermission();
  }

  Widget _buildPremiumCard({
    required BuildContext context, required bool isDark, required Color surfaceColor, required Color textColor, required Color accentColor,
    required IconData icon, required String title, required String subtitle, required int currentLevel, required String currentTone, required double currentVolume,
    bool isFadeInForced = false, required Function(int, String, double) onSave,
  }) {
    bool isEnabled = currentLevel > 0;
    int mode = currentLevel == 0 ? 1 : currentLevel;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: accentColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12, height: 1.3)),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: isEnabled,
                  activeTrackColor: accentColor,
                  onChanged: (val) {
                    HapticFeedback.lightImpact();
                    if (val) {
                      onSave(mode, currentTone, currentVolume);
                    } else {
                      onSave(0, currentTone, currentVolume);
                    }
                  },
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isEnabled ? Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: textColor.withValues(alpha: 0.05))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildSegmentButton(context, 'notifications.quiet'.tr(), mode == 1, textColor, accentColor, () {
                          HapticFeedback.selectionClick();
                          onSave(1, currentTone, currentVolume);
                        }),
                        _buildSegmentButton(context, 'notifications.wake_screen'.tr(), mode == 2, textColor, accentColor, () {
                          HapticFeedback.selectionClick();
                          onSave(2, currentTone, currentVolume);
                        }),
                      ],
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: mode == 2 ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () => _showTonePicker(context, currentTone, surfaceColor, textColor, accentColor, (selectedTone) {
                            onSave(2, selectedTone, currentVolume);
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: textColor.withValues(alpha: 0.1)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.music, color: textColor.withValues(alpha: 0.5), size: 18),
                                const SizedBox(width: 12),
                                Expanded(child: Text('notifications.alarm_tone'.tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.w500))),
                                Text(_availableTones[currentTone] ?? 'افتراضي', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(width: 8),
                                Icon(LucideIcons.chevron_left, color: textColor.withValues(alpha: 0.3), size: 18),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(LucideIcons.volume_1, color: textColor.withValues(alpha: 0.4), size: 18),
                            Expanded(
                              child: SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: accentColor,
                                  thumbColor: accentColor,
                                  inactiveTrackColor: textColor.withValues(alpha: 0.1),
                                  trackHeight: 4,
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                ),
                                child: Slider(
                                  value: currentVolume, min: 0.1, max: 1.0,
                                  onChangeEnd: (val) => onSave(2, currentTone, val),
                                  onChanged: (val) {},
                                ),
                              ),
                            ),
                            Icon(LucideIcons.volume_2, color: textColor.withValues(alpha: 0.4), size: 18),
                          ],
                        ),
                        if (isFadeInForced)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, right: 4),
                            child: Text('✨ ${'notifications.fade_in'.tr()}', style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w600)),
                          )
                      ],
                    ) : const SizedBox.shrink(),
                  ),
                ],
              ),
            ) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(BuildContext context, String title, bool isActive, Color textColor, Color accentColor, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? textColor : textColor.withValues(alpha: 0.5),
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  void _showTonePicker(BuildContext context, String currentTone, Color surfaceColor, Color textColor, Color accentColor, Function(String) onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: textColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('notifications.default_tone'.tr(), style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._availableTones.entries.map((e) => ListTile(
              title: Text(e.value, style: TextStyle(color: textColor, fontWeight: currentTone == e.key ? FontWeight.bold : FontWeight.normal)),
              trailing: currentTone == e.key ? Icon(LucideIcons.check, color: accentColor) : null,
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected(e.key);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultsSection(dynamic settings, bool isDark, Color surfaceColor, Color textColor, Color accentColor) {
    return Container(
      decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(LucideIcons.repeat, color: Colors.teal, size: 20)),
            title: Text('notifications.continuous_habits'.tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            subtitle: Text('notifications.habit_default'.tr(), style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 11)),
            trailing: Icon(LucideIcons.chevron_left, color: textColor.withValues(alpha: 0.3), size: 20),
            onTap: () => _showDefaultsDialog(context, settings, true, isDark, surfaceColor, textColor, Colors.teal),
          ),
          Divider(color: textColor.withValues(alpha: 0.05), height: 1, indent: 20, endIndent: 20),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(LucideIcons.circle_check, color: Colors.blue, size: 20)),
            title: Text('notifications.casual_tasks'.tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            subtitle: Text('notifications.task_default'.tr(), style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 11)),
            trailing: Icon(LucideIcons.chevron_left, color: textColor.withValues(alpha: 0.3), size: 20),
            onTap: () => _showDefaultsDialog(context, settings, false, isDark, surfaceColor, textColor, Colors.blue),
          ),
        ],
      ),
    );
  }

  void _showDefaultsDialog(
    BuildContext context,
    dynamic settings,
    bool isHabit,
    bool isDark,
    Color surfaceColor,
    Color textColor,
    Color accentColor,
  ) {
    int tempLevel = isHabit
        ? settings.defaultHabitAlertLevel
        : settings.defaultTaskAlertLevel;
    String tempTone =
        isHabit ? settings.defaultHabitTone : settings.defaultTaskTone;
    double tempVolume =
        isHabit ? settings.defaultHabitVolume : settings.defaultTaskVolume;
    if (!_availableTones.containsKey(tempTone)) {
      tempTone = 'assets/audio/default.mp3';
    }
    final isAr = context.locale.languageCode == 'ar';

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  isHabit
                      ? 'notifications.continuous_habits'.tr()
                      : 'notifications.casual_tasks'.tr(),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildSegmentButton(
                    context,
                    isAr ? 'بدون إشعار' : 'No Notification',
                    tempLevel == 0,
                    textColor,
                    accentColor,
                    () => setSheetState(() => tempLevel = 0),
                  ),
                  const SizedBox(width: 6),
                  _buildSegmentButton(
                    context,
                    isAr ? 'إشعار على الستارة' : 'Curtain Notif',
                    tempLevel == 1,
                    textColor,
                    accentColor,
                    () => setSheetState(() => tempLevel = 1),
                  ),
                  const SizedBox(width: 6),
                  _buildSegmentButton(
                    context,
                    'alerts.alarm'.tr(),
                    tempLevel == 2,
                    textColor,
                    accentColor,
                    () => setSheetState(() => tempLevel = 2),
                  ),
                ],
              ),
              if (tempLevel == 2) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: textColor.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: tempTone,
                      dropdownColor: surfaceColor,
                      isExpanded: true,
                      items: _availableTones.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(
                                e.value,
                                style: TextStyle(color: textColor),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setSheetState(() => tempTone = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Slider(
                  value: tempVolume,
                  min: 0.1,
                  max: 1.0,
                  activeColor: accentColor,
                  onChanged: (v) => setSheetState(() => tempVolume = v),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  ref
                      .read(settingsProvider.notifier)
                      .updateProductivityDefaults(
                        isTask: !isHabit,
                        alertLevel: tempLevel,
                        tone: tempTone,
                        volume: tempVolume,
                      );
                  Navigator.pop(context);
                },
                child: Text(
                  'notifications.save'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}