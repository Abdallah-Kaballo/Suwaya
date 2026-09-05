import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart'; // 🌟

import '../routines_provider.dart';
import '../../../core/astro_engine/astro_provider.dart'; 
import '../../tasks/screens/universal_add_screen.dart'; 

class RoutinesListSheet extends ConsumerWidget {
  const RoutinesListSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routines = ref.watch(routinesProvider);
    final astroState = ref.watch(astroProvider); 
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).cardColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = isDark ? Colors.white54 : Colors.black54;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Material(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: hintColor.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 20),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('routines.manage_special_periods'.tr(), style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text('${routines.length} ${'routines.periods_count'.tr()}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (routines.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.calendar_range, size: 64, color: hintColor.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('routines.no_routines'.tr(), style: TextStyle(color: hintColor)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: routines.length,
                    itemBuilder: (context, index) {
                      final r = routines[index];
                      final rColor = Color(r.colorValue);
                      
                      String timeText = '';
                      if (r.isAstroTime) {
                        final ss = (r.startSuwaya ?? 0).toString().padLeft(2, '0');
                        final sm = (r.startVirtualMinute ?? 0).toString().padLeft(2, '0');
                        final es = (r.endSuwaya ?? 0).toString().padLeft(2, '0');
                        final em = (r.endVirtualMinute ?? 0).toString().padLeft(2, '0');
                        timeText = '${'common.astro'.tr()} (${'common.from'.tr()} $ss:$sm ${'common.to'.tr()} $es:$em)';
                      } else {
                        final sh = (r.startTimeMinutes! ~/ 60).toString().padLeft(2, '0');
                        final sm = (r.startTimeMinutes! % 60).toString().padLeft(2, '0');
                        final eh = (r.endTimeMinutes! ~/ 60).toString().padLeft(2, '0');
                        final em = (r.endTimeMinutes! % 60).toString().padLeft(2, '0');
                        timeText = '${'common.civil'.tr()} (${'common.from'.tr()} $sh:$sm ${'common.to'.tr()} $eh:$em)';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: rColor.withValues(alpha: 0.3))),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(width: 16, height: 16, decoration: BoxDecoration(color: rColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: rColor.withValues(alpha: 0.5), blurRadius: 6)])),
                          title: Text(r.title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            // 🌟 التعديل هنا: الخط الفلكي (Playfair Display) والمدني (Inter)
                            child: Directionality(textDirection: ui.TextDirection.ltr, child: Text(timeText, textAlign: TextAlign.right, style: TextStyle(color: hintColor, fontSize: 13, fontWeight: r.isAstroTime ? FontWeight.w900 : FontWeight.w600, fontFamily: r.isAstroTime ? 'Playfair Display' : 'Inter', letterSpacing: r.isAstroTime ? 1.0 : 0.0))),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(LucideIcons.pencil, color: textColor.withValues(alpha: 0.7), size: 20),
                                onPressed: () {
                                  Navigator.pop(context);
                                  showModalBottomSheet(
                                    context: context, 
                                    isScrollControlled: true, 
                                    backgroundColor: Colors.transparent, 
                                    builder: (_) => UniversalAddScreen(
                                      currentPeriodId: astroState.currentPeriod.id,
                                      currentSuwaya: astroState.currentSuwaya,
                                      existingRoutine: r,
                                    )
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}