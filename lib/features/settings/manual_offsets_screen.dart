import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:suwaya/features/settings/settings_provider.dart';


class _PrayerOffsetPreset {
  final String id;
  final String labelKey;
  final Color uiColor;

  const _PrayerOffsetPreset({required this.id, required this.labelKey, required this.uiColor});
}

class ManualOffsetsScreen extends ConsumerWidget {
  const ManualOffsetsScreen({super.key});

  static const List<_PrayerOffsetPreset> _allowedPrayers = [
    _PrayerOffsetPreset(id: '1', labelKey: 'periods.fajr', uiColor: Color(0xFF64B5F6)),
    _PrayerOffsetPreset(id: '3', labelKey: 'periods.dhuhr', uiColor: Color(0xFFFFCA28)),
    _PrayerOffsetPreset(id: '4', labelKey: 'periods.asr', uiColor: Color(0xFFFF9800)),
    _PrayerOffsetPreset(id: '5', labelKey: 'periods.maghrib', uiColor: Color(0xFFE53935)),
    _PrayerOffsetPreset(id: 'isha', labelKey: 'prayers.isha', uiColor: Color(0xFF1A237E)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = isDark ? Colors.white54 : Colors.black54;
    final primaryColor = Theme.of(context).primaryColor;
    final borderColor = Theme.of(context).dividerColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(context.locale.languageCode == 'ar' ? LucideIcons.arrow_right : LucideIcons.arrow_left, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('settings.manual_offset'.tr(), style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.rotate_ccw),
            color: primaryColor,
            tooltip: 'settings.reset_all_offsets'.tr(),
            onPressed: () {
               HapticFeedback.heavyImpact();
              notifier.resetAllOffsets();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('settings.offsets_reset_success'.tr()), backgroundColor: Colors.green.shade800),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.info, color: primaryColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('settings.manual_offset_desc'.tr(), style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12, height: 1.5)),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
             child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 50, left: 20, right: 20),
              itemCount: _allowedPrayers.length, 
              itemBuilder: (context, index) {
                final prayer = _allowedPrayers[index];
                final String pId = prayer.id;
                final int currentOffset = settings.getManualOffset(pId);

                final bool canDecrease = currentOffset > -30;
                final bool canIncrease = currentOffset < 30;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: prayer.uiColor, shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(prayer.labelKey.tr(), style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              currentOffset == 0 
                                  ? 'settings.no_offset'.tr() 
                                  : (currentOffset > 0 ? '+ $currentOffset ${'details.minute'.tr()}' : '$currentOffset ${'details.minute'.tr()}'),
                              style: TextStyle(
                                color: currentOffset == 0 ? hintColor : (currentOffset > 0 ? Colors.green : Colors.redAccent), 
                                fontSize: 12, fontWeight: currentOffset == 0 ? FontWeight.normal : FontWeight.bold
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Row(
                        children: [
                          _buildAdjustButton(
                            icon: LucideIcons.minus, 
                            color: canDecrease ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)) : Colors.transparent,
                            iconColor: canDecrease ? textColor : hintColor.withValues(alpha: 0.3),
                            onTap: canDecrease ? () {
                              HapticFeedback.lightImpact();
                              notifier.updateManualOffset(pId, currentOffset - 1);
                            } : () {} 
                          ),
                          SizedBox(
                            width: 45,
                            child: Text(
                              currentOffset.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                            ),
                          ),
                          _buildAdjustButton(
                            icon: LucideIcons.plus, 
                            color: canIncrease ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)) : Colors.transparent,
                            iconColor: canIncrease ? textColor : hintColor.withValues(alpha: 0.3),
                            onTap: canIncrease ? () {
                              HapticFeedback.lightImpact();
                              notifier.updateManualOffset(pId, currentOffset + 1);
                            } : () {} 
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustButton({required IconData icon, required Color color, required Color iconColor, required VoidCallback onTap}) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 36, height: 36,
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: iconColor),
        ),
      ),
    );
  }
}