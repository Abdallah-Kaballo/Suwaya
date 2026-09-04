import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/astro_engine/astro_provider.dart';
import '../../core/astro_engine/astro_models.dart';


class AstroTimelineScreen extends ConsumerWidget {
  const AstroTimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final astroState = ref.watch(astroProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 🌟 خلفية رمادية فاتحة جداً في النهار لتعطي عمقاً (Depth) للبطاقات البيضاء
    final bgColor = isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF5F7FA);
    final surfaceColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final borderColor = isDark ? Theme.of(context).dividerColor : Colors.black.withValues(alpha: 0.05);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(context.locale.languageCode == 'ar' ? LucideIcons.arrow_right : LucideIcons.arrow_left, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('full_astro_timeline'.tr(), style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        centerTitle: true,
      ),
      body: astroState.periods.isEmpty
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              itemCount: astroState.periods.length,
              itemBuilder: (context, index) {
                final period = astroState.periods[index];
                final isCurrent = astroState.currentPeriod.id == period.id;
                
                // 🌟 تطبيق اللون الذكي (مضيء ليلاً، داكن نهاراً)
                final adaptedColor = period.color.adapt(context);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isCurrent ? period.color.withValues(alpha: isDark ? 0.15 : 0.08) : surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isCurrent ? adaptedColor.withValues(alpha: 0.5) : borderColor, width: isCurrent ? 1.5 : 1),
                    boxShadow: isDark ? [] : [
                      if (!isCurrent) BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Theme(
                    data: ThemeData().copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: isCurrent,
                      iconColor: isCurrent ? adaptedColor : (isDark ? Colors.white54 : Colors.black54),
                      collapsedIconColor: isDark ? Colors.white54 : Colors.black54,
                      title: Row(
                        children: [
                          Container(
                            width: 12, height: 12,
                            decoration: BoxDecoration(
                              color: adaptedColor, 
                              shape: BoxShape.circle, 
                              boxShadow: isCurrent ? [BoxShadow(color: adaptedColor.withValues(alpha: 0.5), blurRadius: 8)] : []
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${period.id} (${period.nameKey.tr()})',
                            style: TextStyle(color: isCurrent ? adaptedColor : textColor, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                          ),
                          child: Column(
                            children: [
                              _buildTimeRow('starts_at'.tr(), period.startTime, context, isDark, textColor),
                              const SizedBox(height: 8),
                              _buildTimeRow('ends_at'.tr(), period.endTime, context, isDark, textColor),
                              const SizedBox(height: 8),
                              Divider(color: isDark ? Colors.white12 : Colors.black12),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('suwayas_count'.tr(), style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13)),
                                  Text('${period.suwayasCount} سويعات', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTimeRow(String label, DateTime time, BuildContext context, bool isDark, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13)),
        Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Text(TimeOfDay.fromDateTime(time).format(context), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 15)),
        ),
      ],
    );
  }
}