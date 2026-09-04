import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/astro_engine/astro_provider.dart';
import '../settings_provider.dart';

class ManualOffsetsScreen extends ConsumerWidget {
  const ManualOffsetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final astro = ref.watch(astroProvider);
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
        title: Text('التعديل اليدوي للمواقيت', style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.rotate_ccw),
            color: primaryColor,
            tooltip: 'تصفير كل التعديلات',
            onPressed: () {
               HapticFeedback.heavyImpact();
              notifier.resetAllOffsets();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('تم تصفير كل التعديلات بنجاح'), backgroundColor: Colors.green.shade800),
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
                    child: Text('قم بضبط الدقائق يدوياً إذا كانت تختلف عن مسجد حيك المعتاد. (الحد الأقصى 59 دقيقة)', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12, height: 1.5)),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
             child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 50, left: 20, right: 20),
              itemCount: astro.periods.length,
              itemBuilder: (context, index) {
                final period = astro.periods[index];
                final String pId = period.id.toString();
                // 🌟 تم تصحيح الأقواس هنا
                final int currentOffset = settings.getManualOffset(pId);

                final bool canDecrease = currentOffset > -59;
                final bool canIncrease = currentOffset < 59;

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
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: period.color, shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(period.nameKey.tr(), style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              currentOffset == 0 
                                  ? 'بدون تعديل' 
                                  : (currentOffset > 0 ? '+ $currentOffset دقيقة' : '$currentOffset دقيقة'),
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