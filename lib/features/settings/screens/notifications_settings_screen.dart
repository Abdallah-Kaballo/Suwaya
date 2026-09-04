import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import '../settings_provider.dart';

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

    final bgColor = isDark ? Colors.black : const Color(0xFFF5F7FA);
    final surfaceColor = isDark ? const Color(0xFF1E2530) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    const accentColor = Color(0xFFD4AF37);

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
        leading: IconButton(icon: Icon(LucideIcons.arrow_right, color: textColor), onPressed: () => Navigator.pop(context)),
        title: Text('notifications.title'.tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsSection(
            context: context, isDark: isDark, surfaceColor: surfaceColor, textColor: textColor, accentColor: accentColor,
            icon: LucideIcons.moon_star,
            title: 'notifications.prayers'.tr(),
            subtitle: 'notifications.prayers_desc'.tr(),
            currentLevel: prayersLevel,
            currentTone: prayersTone,
            currentVolume: prayersVolume,
            onSave: (level, tone, vol) {
              final ids = ['1', '3', '4', '5', 'isha'];
              for (var id in ids) {
                ref.read(settingsProvider.notifier).updatePeriodNotificationSettings(periodId: id, isEnabled: true, alertLevel: level, soundPath: tone, volume: vol);
              }
            },
          ),
          const SizedBox(height: 16),

          _buildSettingsSection(
            context: context, isDark: isDark, surfaceColor: surfaceColor, textColor: textColor, accentColor: const Color(0xFF5E35B1),
            icon: LucideIcons.sparkles,
            title: 'notifications.qiyam'.tr(),
            subtitle: 'notifications.qiyam_desc'.tr(),
            currentLevel: qiyamLevel,
            currentTone: qiyamTone,
            currentVolume: qiyamVolume,
            isFadeInForced: true, 
            onSave: (level, tone, vol) {
              final nightIds = ['half_1', 'half_2', 'third_1', 'third_2', 'third_3', 'sixth_1', 'sixth_2', 'sixth_3', 'sixth_4', 'sixth_5', 'sixth_6'];
              for (var id in nightIds) {
                ref.read(settingsProvider.notifier).updatePeriodNotificationSettings(periodId: id, isEnabled: true, alertLevel: level, soundPath: tone, volume: vol);
              }
            },
          ),
          const SizedBox(height: 32),

          Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text('notifications.productivity'.tr(), style: const TextStyle(color: accentColor, fontWeight: FontWeight.bold))),

          _buildDefaultsSection(settings, isDark, surfaceColor, textColor, accentColor),
          const SizedBox(height: 16),

          _buildSnoozeSection(settings, isDark, surfaceColor, textColor, accentColor),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required BuildContext context, required bool isDark, required Color surfaceColor, required Color textColor, required Color accentColor,
    required IconData icon, required String title, required String subtitle, required int currentLevel, required String currentTone, required double currentVolume,
    bool isFadeInForced = false, required Function(int, String, double) onSave,
  }) {
    int tempLevel = currentLevel;
    String tempTone = _availableTones.containsKey(currentTone) ? currentTone : 'assets/audio/default.mp3';
    double tempVol = currentVolume;

    return Container(
      decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: accentColor.withValues(alpha: 0.2))),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: accentColor, collapsedIconColor: textColor.withValues(alpha: 0.5),
          leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), shape: BoxShape.circle), child: Icon(icon, color: accentColor, size: 22)),
          title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(subtitle, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 11)),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text('notifications.alert_level'.tr(), style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildChoiceChip(context: context, title: 'notifications.silent'.tr(), isActive: tempLevel == 0, color: accentColor, textColor: textColor, onTap: () => setState(() => tempLevel = 0)),
                        const SizedBox(width: 8),
                        _buildChoiceChip(context: context, title: 'notifications.quiet'.tr(), isActive: tempLevel == 1, color: accentColor, textColor: textColor, onTap: () => setState(() => tempLevel = 1)),
                        const SizedBox(width: 8),
                        _buildChoiceChip(context: context, title: 'notifications.interactive'.tr(), isActive: tempLevel == 2, color: accentColor, textColor: textColor, onTap: () => setState(() => tempLevel = 2)),
                      ],
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      child: tempLevel == 2 ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          Text('notifications.alarm_tone'.tr(), style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold)),
                          DropdownButton<String>(
                            value: tempTone, isExpanded: true, dropdownColor: surfaceColor,
                            style: TextStyle(color: textColor, fontFamily: 'Tajawal', fontWeight: FontWeight.w600),
                            items: _availableTones.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                            onChanged: (val) => setState(() => tempTone = val!),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(LucideIcons.volume_1, color: textColor.withValues(alpha: 0.5), size: 18),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderThemeData(activeTrackColor: accentColor, thumbColor: accentColor),
                                  child: Slider(value: tempVol, min: 0.1, max: 1.0, onChanged: (val) => setState(() => tempVol = val)),
                                ),
                              ),
                              Icon(LucideIcons.volume_2, color: textColor.withValues(alpha: 0.5), size: 18),
                            ],
                          ),
                          if (isFadeInForced)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Icon(LucideIcons.info, color: accentColor, size: 14),
                                  const SizedBox(width: 6),
                                  Text('notifications.fade_in'.tr(), style: TextStyle(color: accentColor, fontSize: 11)),
                                ],
                              ),
                            )
                        ],
                      ) : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity, height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: accentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          onSave(tempLevel, tempTone, tempVol);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${'notifications.saved'.tr()} $title'), backgroundColor: accentColor));
                        },
                        child: Text('notifications.save_changes'.tr(), style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultsSection(dynamic settings, bool isDark, Color surfaceColor, Color textColor, Color accentColor) {
    return Container(
      decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: accentColor.withValues(alpha: 0.2))),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(LucideIcons.repeat, color: Colors.teal),
            title: Text('notifications.continuous_habits'.tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            subtitle: Text('notifications.habit_default'.tr(), style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 11)),
            trailing: IconButton(
              icon: Icon(LucideIcons.settings_2, color: textColor.withValues(alpha: 0.5)),
              onPressed: () => _showDefaultsDialog(context, settings, true, isDark, surfaceColor, textColor, Colors.teal),
            ),
          ),
          Divider(color: textColor.withValues(alpha: 0.1), height: 1),
          ListTile(
            leading: const Icon(LucideIcons.circle_check, color: Colors.blue),
            title: Text('notifications.casual_tasks'.tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            subtitle: Text('notifications.task_default'.tr(), style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 11)),
            trailing: IconButton(
              icon: Icon(LucideIcons.settings_2, color: textColor.withValues(alpha: 0.5)),
              onPressed: () => _showDefaultsDialog(context, settings, false, isDark, surfaceColor, textColor, Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  void _showDefaultsDialog(BuildContext context, dynamic settings, bool isHabit, bool isDark, Color surfaceColor, Color textColor, Color accentColor) {
    int tempLevel = isHabit ? settings.defaultHabitAlertLevel : settings.defaultTaskAlertLevel;
    String tempTone = isHabit ? settings.defaultHabitTone : settings.defaultTaskTone;
    if (!_availableTones.containsKey(tempTone)) tempTone = 'assets/audio/default.mp3';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('notifications.defaults_title'.tr(), style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('notifications.default_level'.tr(), style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 13)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(border: Border.all(color: textColor.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: tempLevel, dropdownColor: surfaceColor, isExpanded: true,
                    style: TextStyle(color: textColor, fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                    items: [
                      DropdownMenuItem(value: 0, child: Text('notifications.silent'.tr())),
                      DropdownMenuItem(value: 1, child: Text('notifications.quiet'.tr())),
                      DropdownMenuItem(value: 2, child: Text('notifications.wake_screen'.tr())),
                    ],
                    onChanged: (val) => setState(() => tempLevel = val!),
                  ),
                ),
              ),
              if (tempLevel == 2) ...[
                const SizedBox(height: 16),
                Text('notifications.default_tone'.tr(), style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(border: Border.all(color: textColor.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: tempTone, dropdownColor: surfaceColor, isExpanded: true,
                      style: TextStyle(color: textColor, fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                      items: _availableTones.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: (val) => setState(() => tempTone = val!),
                    ),
                  ),
                ),
              ]
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('common.cancel'.tr(), style: TextStyle(color: textColor.withValues(alpha: 0.5)))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              onPressed: () {
                ref.read(settingsProvider.notifier).updateProductivityDefaults(isTask: !isHabit, alertLevel: tempLevel, tone: tempTone, volume: 1.0);
                Navigator.pop(context);
              },
              child: Text('notifications.save'.tr(), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnoozeSection(dynamic settings, bool isDark, Color surfaceColor, Color textColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: accentColor.withValues(alpha: 0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.clock, color: accentColor), 
              const SizedBox(width: 12),
              Text('notifications.snooze_system'.tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('notifications.snooze_duration'.tr(), style: TextStyle(color: textColor.withValues(alpha: 0.8))),
              DropdownButton<int>(
                value: settings.snoozeDurationMinutes, dropdownColor: surfaceColor, underline: const SizedBox(),
                style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
                items: [
                  DropdownMenuItem(value: 5, child: Text('notifications.mins_5'.tr())),
                  DropdownMenuItem(value: 10, child: Text('notifications.mins_10'.tr())),
                  DropdownMenuItem(value: 15, child: Text('notifications.mins_15'.tr())),
                  DropdownMenuItem(value: 30, child: Text('notifications.mins_30'.tr())),
                ],
                onChanged: (val) => ref.read(settingsProvider.notifier).updateSnoozeSettings(durationMinutes: val!, maxCount: settings.maxSnoozeCount),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('notifications.snooze_max'.tr(), style: TextStyle(color: textColor.withValues(alpha: 0.8))),
              DropdownButton<int>(
                value: settings.maxSnoozeCount, dropdownColor: surfaceColor, underline: const SizedBox(),
                style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
                items: [
                  DropdownMenuItem(value: 1, child: Text('notifications.once'.tr())),
                  DropdownMenuItem(value: 3, child: Text('notifications.times_3'.tr())),
                  DropdownMenuItem(value: 5, child: Text('notifications.times_5'.tr())),
                  DropdownMenuItem(value: 99, child: Text('notifications.no_limit'.tr())),
                ],
                onChanged: (val) => ref.read(settingsProvider.notifier).updateSnoozeSettings(durationMinutes: settings.snoozeDurationMinutes, maxCount: val!),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip({required BuildContext context, required String title, required bool isActive, required Color color, required Color textColor, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: isActive ? color : Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: isActive ? color : textColor.withValues(alpha: 0.2))),
          alignment: Alignment.center,
          child: Text(title, style: TextStyle(color: isActive ? (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white) : textColor.withValues(alpha: 0.6), fontSize: 11, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }
}