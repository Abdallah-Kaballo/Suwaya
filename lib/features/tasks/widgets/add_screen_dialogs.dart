import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../models/task_model.dart';
import 'pattern_preview_painter.dart';

class AddGridCard extends StatelessWidget {
  final Color surfaceColor;
  final Color accentColor;
  final Color textColor;
  final String title;
  final String value;
  final IconData icon;
  final bool isHighlighted;
  final bool isError;
  final VoidCallback? onTap;
  final Widget? valueWidget;

  const AddGridCard({
    super.key,
    required this.surfaceColor,
    required this.accentColor,
    required this.textColor,
    required this.title,
    required this.value,
    required this.icon,
    required this.isHighlighted,
    required this.isError,
    this.onTap,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    final Color valColor = isError ? Colors.redAccent : textColor;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isError
                  ? Colors.redAccent
                  : (isHighlighted ? accentColor : Colors.transparent),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: isError
                        ? Colors.redAccent
                        : (isHighlighted
                            ? accentColor
                            : textColor.withValues(alpha: 0.5)),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isError
                            ? Colors.redAccent
                            : textColor.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              valueWidget ??
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: valColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showRoutinePatternModal({
  required BuildContext context,
  required Color pColor,
  required Color surface,
  required Color text,
  required Color initialColor,
  required String initialPattern,
  required Map<String, String> availablePatterns,
  required void Function(Color color, String pattern) onChanged,
}) async {
  Color currentColor = initialColor;
  String currentPattern = initialPattern;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) => Dialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'add_screen.pattern_and_color'.tr(),
                style: TextStyle(
                  color: text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Color(0xFF00E5FF),
                    const Color(0xFF00E676),
                    const Color(0xFFFF3D00),
                    const Color(0xFFFFC400),
                    const Color(0xFFFF4081),
                    const Color(0xFFD500F9),
                  ].map((color) {
                    final isSelected = currentColor == color;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() => currentColor = color);
                        onChanged(currentColor, currentPattern);
                      },
                      child: Container(
                        margin: const EdgeInsetsDirectional.only(end: 12),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: isSelected ? 3 : 0,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              ...availablePatterns.entries.map((entry) {
                final isSelected = currentPattern == entry.key;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CustomPaint(
                    size: const Size(30, 30),
                    painter: PatternPreviewPainter(entry.key, currentColor),
                  ),
                  title: Text(
                    entry.value,
                    style: TextStyle(
                      color: isSelected ? pColor : text,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(LucideIcons.circle_check, color: pColor)
                      : null,
                  onTap: () {
                    setDialogState(() => currentPattern = entry.key);
                    onChanged(currentColor, currentPattern);
                  },
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: pColor),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'common.done'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showCategoryDialModal({
  required BuildContext context,
  required Color pColor,
  required Color surface,
  required Color text,
  required TaskCategory initialCategory,
  required bool initialShowOnDial,
  required void Function(TaskCategory category, bool showOnDial) onChanged,
}) async {
  TaskCategory currentCategory = initialCategory;
  bool currentShowOnDial = initialShowOnDial;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) => Dialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'add_screen.category_and_dial'.tr(),
                style: TextStyle(
                  color: text,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: TaskCategory.values.map((cat) {
                    final isSelected = currentCategory == cat;
                    final catColor = cat.uiColor(isDark);
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() => currentCategory = cat);
                        onChanged(currentCategory, currentShowOnDial);
                      },
                      child: Container(
                        margin: const EdgeInsetsDirectional.only(end: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? catColor.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? catColor
                                : text.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: catColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(cat.displayName,
                                style: TextStyle(color: text)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'add_screen.show_on_dial'.tr(),
                  style: TextStyle(
                    color: text,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                value: currentShowOnDial,
                activeThumbColor: pColor,
                onChanged: (val) {
                  setDialogState(() => currentShowOnDial = val);
                  onChanged(currentCategory, currentShowOnDial);
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: pColor),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'common.done'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showAlertsModal({
  required BuildContext context,
  required Color pColor,
  required Color surface,
  required Color text,
  required int initialAlertLevel,
  required String initialTone,
  required double initialVolume,
  required Map<String, String> availableTones,
  required void Function(int level, String tone, double volume) onChanged,
}) async {
  int currentLevel = initialAlertLevel;
  String currentTone = initialTone;
  double currentVolume = initialVolume;

  Widget buildAlertButton(
    int level,
    IconData icon,
    String title,
    StateSetter setDialogState,
  ) {
    final isActive = currentLevel == level;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setDialogState(() => currentLevel = level);
          onChanged(currentLevel, currentTone, currentVolume);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isActive ? pColor.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? pColor : text.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isActive ? pColor : text.withValues(alpha: 0.4),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isActive ? pColor : text.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) => Dialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'add_screen.alert_settings'.tr(),
                style: TextStyle(
                  color: text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  buildAlertButton(
                    0,
                    LucideIcons.bell_off,
                    'alerts.silent'.tr(),
                    setDialogState,
                  ),
                  const SizedBox(width: 8),
                  buildAlertButton(
                    1,
                    LucideIcons.bell,
                    'ibadat.notification'.tr(),
                    setDialogState,
                  ),
                  const SizedBox(width: 8),
                  buildAlertButton(
                    2,
                    LucideIcons.alarm_clock,
                    'alerts.alarm'.tr(),
                    setDialogState,
                  ),
                ],
              ),
              if (currentLevel == 2) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: text.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: currentTone,
                      dropdownColor: surface,
                      isExpanded: true,
                      items: availableTones.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(
                                e.value,
                                style: TextStyle(color: text),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setDialogState(() => currentTone = val);
                        onChanged(currentLevel, currentTone, currentVolume);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: currentVolume,
                  activeColor: pColor,
                  onChanged: (v) {
                    setDialogState(() => currentVolume = v);
                    onChanged(currentLevel, currentTone, currentVolume);
                  },
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: pColor),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'common.done'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
