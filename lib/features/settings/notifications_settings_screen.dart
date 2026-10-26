import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:suwaya/models/settings_model.dart';

import 'settings_provider.dart';
import '../../core/location/permissions_provider.dart';

class NotificationsSettingsScreen extends ConsumerStatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  ConsumerState<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends ConsumerState<NotificationsSettingsScreen> {
  late final Map<String, String> _availableTones;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _availableTones = {
      'assets/audio/default.mp3': 'alerts.default_ring'.tr(),
      'assets/audio/adhan.mp3': 'alerts.makkah_adhan'.tr(),
      'assets/audio/soft.mp3': 'alerts.soft_bell'.tr(),
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

    final int prayersLevel = settings.getPeriodAlertLevel('fajr', 1);
    final String prayersTone = settings.getPeriodSound(
      'fajr',
      'assets/audio/adhan.mp3',
    );
    final double prayersVolume = settings.getPeriodVolume('fajr', 1.0);

    final int qiyamLevel = settings.getPeriodAlertLevel('third_3', 0);
    final String qiyamTone = settings.getPeriodSound(
      'third_3',
      'assets/audio/soft.mp3',
    );
    final double qiyamVolume = settings.getPeriodVolume('third_3', 0.5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            context.locale.languageCode == 'ar'
                ? LucideIcons.arrow_right
                : LucideIcons.arrow_left,
            color: textColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'notifications.title'.tr(),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _buildPremiumCard(
            context: context,
            isDark: isDark,
            surfaceColor: surfaceColor,
            textColor: textColor,
            accentColor: accentColor,
            icon: LucideIcons.moon_star,
            title: 'notifications.prayers'.tr(),
            subtitle: 'notifications.prayers_desc'.tr(),
            currentLevel: prayersLevel,
            currentTone: prayersTone,
            currentVolume: prayersVolume,
            onSave: (level, tone, vol) async {
              if (level > 0) await _requestPermissions(ref);
              await ref
                  .read(settingsProvider.notifier)
                  .updateBatchPeriodNotificationSettings(
                    periodIds: const [
                      'fajr',
                      'dhuhr',
                      'asr',
                      'maghrib',
                      'isha',
                    ],
                    isEnabled: level > 0,
                    alertLevel: level,
                    soundPath: tone,
                    volume: vol,
                  );
            },
          ),
          const SizedBox(height: 20),
          _buildPremiumCard(
            context: context,
            isDark: isDark,
            surfaceColor: surfaceColor,
            textColor: textColor,
            accentColor: const Color(0xFF8B5CF6),
            icon: LucideIcons.sparkles,
            title: 'notifications.qiyam'.tr(),
            subtitle: 'notifications.qiyam_desc'.tr(),
            currentLevel: qiyamLevel,
            currentTone: qiyamTone,
            currentVolume: qiyamVolume,
            isFadeInForced: true,
            onSave: (level, tone, vol) async {
              if (level > 0) await _requestPermissions(ref);
              await ref
                  .read(settingsProvider.notifier)
                  .updateBatchPeriodNotificationSettings(
                    periodIds: const [
                      'half_2',
                      'third_3',
                      'sixth_4',
                      'sixth_5',
                      'sixth_6',
                    ],
                    isEnabled: level > 0,
                    alertLevel: level,
                    soundPath: tone,
                    volume: vol,
                  );
            },
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'notifications.productivity'.tr(),
              style: TextStyle(
                color: textColor.withValues(alpha: 0.5),
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 1.2,
              ),
            ),
          ),
          _buildDefaultsSection(
            settings,
            isDark,
            surfaceColor,
            textColor,
            accentColor,
          ),
          const SizedBox(height: 20),
          _buildSnoozeSection(settings, surfaceColor, textColor, accentColor),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSnoozeSection(
    SettingsModel settings,
    Color surfaceColor,
    Color textColor,
    Color accentColor,
  ) {
    final durationOptions = {
      5: 'notifications.mins_5'.tr(),
      10: 'notifications.mins_10'.tr(),
      15: 'notifications.mins_15'.tr(),
      30: 'notifications.mins_30'.tr(),
    };
    final maxCountOptions = {
      1: 'notifications.once'.tr(),
      3: 'notifications.times_3'.tr(),
      5: 'notifications.times_5'.tr(),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.snooze_rounded, color: accentColor, size: 22),
              const SizedBox(width: 10),
              Text(
                'notifications.snooze_system'.tr(),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'notifications.snooze_duration'.tr(),
            style: TextStyle(
              color: textColor.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: durationOptions.entries.map((entry) {
              final isSelected = settings.snoozeDurationMinutes == entry.key;
              return ChoiceChip(
                label: Text(entry.value),
                selected: isSelected,
                selectedColor: accentColor.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? accentColor : textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  ref
                      .read(settingsProvider.notifier)
                      .updateSnoozeSettings(
                        durationMinutes: entry.key,
                        maxCount: settings.maxSnoozeCount,
                      );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'notifications.snooze_max'.tr(),
            style: TextStyle(
              color: textColor.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: maxCountOptions.entries.map((entry) {
              final isSelected = settings.maxSnoozeCount == entry.key;
              return ChoiceChip(
                label: Text(entry.value),
                selected: isSelected,
                selectedColor: accentColor.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? accentColor : textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  ref
                      .read(settingsProvider.notifier)
                      .updateSnoozeSettings(
                        durationMinutes: settings.snoozeDurationMinutes,
                        maxCount: entry.key,
                      );
                },
              );
            }).toList(),
          ),
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
    required BuildContext context,
    required bool isDark,
    required Color surfaceColor,
    required Color textColor,
    required Color accentColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required int currentLevel,
    required String currentTone,
    required double currentVolume,
    bool isFadeInForced = false,
    required Function(int, String, double) onSave,
  }) {
    final bool isEnabled = currentLevel > 0;
    final int mode = currentLevel == 0 ? 1 : currentLevel;
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
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
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
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
            child: isEnabled
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: textColor.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              _buildSegmentButton(
                                context,
                                'notifications.quiet'.tr(),
                                mode == 1,
                                textColor,
                                accentColor,
                                () {
                                  HapticFeedback.selectionClick();
                                  onSave(1, currentTone, currentVolume);
                                },
                              ),
                              _buildSegmentButton(
                                context,
                                'notifications.wake_screen'.tr(),
                                mode == 2,
                                textColor,
                                accentColor,
                                () {
                                  HapticFeedback.selectionClick();
                                  onSave(2, currentTone, currentVolume);
                                },
                              ),
                            ],
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          child: mode == 2
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 20),
                                    GestureDetector(
                                      onTap: () => _showTonePicker(
                                        context,
                                        currentTone,
                                        surfaceColor,
                                        textColor,
                                        accentColor,
                                        (selectedTone) {
                                          onSave(
                                            mode,
                                            selectedTone,
                                            currentVolume,
                                          );
                                        },
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: textColor.withValues(
                                              alpha: 0.1,
                                            ),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              LucideIcons.mic,
                                              color: textColor.withValues(
                                                alpha: 0.5,
                                              ),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'notifications.alarm_tone'.tr(),
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              _availableTones[currentTone] ??
                                                  'alerts.default_ring'.tr(),
                                              style: TextStyle(
                                                color: accentColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              isRTL
                                                  ? LucideIcons.chevron_left
                                                  : LucideIcons.chevron_right,
                                              color: textColor.withValues(
                                                alpha: 0.3,
                                              ),
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isFadeInForced)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 10.0,
                                          right: 4,
                                        ),
                                        child: Text(
                                          '✨ ${'notifications.fade_in'.tr()}',
                                          style: TextStyle(
                                            color: accentColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(
    BuildContext context,
    String title,
    bool isActive,
    Color textColor,
    Color accentColor,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF334155)
                      : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ]
                : [],
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

  void _showTonePicker(
    BuildContext context,
    String currentTone,
    Color surfaceColor,
    Color textColor,
    Color accentColor,
    Function(String) onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'notifications.default_tone'.tr(),
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._availableTones.entries.map(
              (e) => ListTile(
                title: Text(
                  e.value,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: currentTone == e.key
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: currentTone == e.key
                    ? Icon(LucideIcons.check, color: accentColor)
                    : null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(e.key);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultsSection(
    SettingsModel settings, // 🌟 نوع صريح بدلاً من dynamic
    bool isDark,
    Color surfaceColor,
    Color textColor,
    Color accentColor,
  ) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final chevronIcon = isRTL
        ? LucideIcons.chevron_left
        : LucideIcons.chevron_right;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.repeat,
                color: Colors.teal,
                size: 20,
              ),
            ),
            title: Text(
              'notifications.continuous_habits'.tr(),
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'notifications.habit_default'.tr(),
              style: TextStyle(
                color: textColor.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
            trailing: Icon(
              chevronIcon,
              color: textColor.withValues(alpha: 0.3),
              size: 20,
            ),
            onTap: () => _showDefaultsDialog(
              context,
              settings,
              true,
              isDark,
              surfaceColor,
              textColor,
              Colors.teal,
            ),
          ),
          Divider(
            color: textColor.withValues(alpha: 0.05),
            height: 1,
            indent: 20,
            endIndent: 20,
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.circle_check,
                color: Colors.blue,
                size: 20,
              ),
            ),
            title: Text(
              'notifications.casual_tasks'.tr(),
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'notifications.task_default'.tr(),
              style: TextStyle(
                color: textColor.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
            trailing: Icon(
              chevronIcon,
              color: textColor.withValues(alpha: 0.3),
              size: 20,
            ),
            onTap: () => _showDefaultsDialog(
              context,
              settings,
              false,
              isDark,
              surfaceColor,
              textColor,
              Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  void _showDefaultsDialog(
    BuildContext context,
    SettingsModel settings, // 🌟 نوع صريح بدلاً من dynamic
    bool isHabit,
    bool isDark,
    Color surfaceColor,
    Color textColor,
    Color accentColor,
  ) {
    int tempLevel = isHabit
        ? settings.defaultHabitAlertLevel
        : settings.defaultTaskAlertLevel;
    String tempTone = isHabit
        ? settings.defaultHabitTone
        : settings.defaultTaskTone;
    double tempVolume = isHabit
        ? settings.defaultHabitVolume
        : settings.defaultTaskVolume;
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
                    border: Border.all(
                      color: textColor.withValues(alpha: 0.12),
                    ),
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
                      onChanged: (val) => setSheetState(() => tempTone = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
                  'common.save'.tr(),
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
