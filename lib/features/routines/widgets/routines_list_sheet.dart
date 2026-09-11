import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:suwaya_time/suwaya_time.dart'; 

import '../routines_provider.dart';
import '../../tasks/tasks_provider.dart';
import '../../../models/task_model.dart';
import '../../../core/astro_engine/astro_provider.dart'; 
import '../../tasks/universal_add_screen.dart'; 

class RoutinesListSheet extends ConsumerStatefulWidget {
  const RoutinesListSheet({super.key});

  @override
  ConsumerState<RoutinesListSheet> createState() => _RoutinesListSheetState();
}

class _RoutinesListSheetState extends ConsumerState<RoutinesListSheet> {
  int _selectedFilter = 0; 

  @override
  Widget build(BuildContext context) {
    final routines = ref.watch(routinesProvider);
    final tasks = ref.watch(tasksProvider).allTasks;
    final astroState = ref.watch(astroProvider); 
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).cardColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = isDark ? Colors.white54 : Colors.black54;
    final primaryColor = Theme.of(context).primaryColor;

    List<dynamic> items = [];
    if (_selectedFilter == 0) {
      items = routines;
    // ignore: curly_braces_in_flow_control_structures
    } else if (_selectedFilter == 1) items = tasks.where((t) => t.type == TaskType.permanent).toList();
    // ignore: curly_braces_in_flow_control_structures
    else items = tasks.where((t) => t.type == TaskType.casual && !t.isCompleted).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Material(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
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
                    Text('home.manage_periods'.tr(), style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text('${items.length}', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildFilterChip('tasks.tab_routines'.tr(), 0, primaryColor),
                    const SizedBox(width: 8),
                    _buildFilterChip('tasks.tab_habits'.tr(), 1, primaryColor),
                    const SizedBox(width: 8),
                    _buildFilterChip('tasks.tab_casual'.tr(), 2, primaryColor),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (items.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.calendar_range, size: 64, color: hintColor.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('tasks.empty_routines'.tr(), style: TextStyle(color: hintColor)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      
                      if (_selectedFilter == 0) {
                        return _buildRoutineCard(item, context, astroState, surfaceColor, textColor, hintColor);
                      } else {
                        return _buildTaskCard(item, context, astroState, surfaceColor, textColor, hintColor);
                      }
                    },
                  ),
                ),

              // 🌟 زر الإضافة المدمج أسفل الشاشة
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // إغلاق نافذة الإدارة أولاً
                      
                      // تحديد التبويب الافتراضي بناءً على الفلتر الحالي
                      int targetTab = _selectedFilter == 0 ? 2 : (_selectedFilter == 1 ? 1 : 0);
                      
                      showModalBottomSheet(
                        context: context, 
                        isScrollControlled: true, 
                        backgroundColor: Colors.transparent, 
                        builder: (_) => UniversalAddScreen(
                          currentPeriodId: astroState.currentPeriod.id, 
                          currentSuwaya: astroState.currentSuwaya,
                          initialTab: targetTab,
                        )
                      );
                    },
                    icon: const Icon(LucideIcons.plus, color: Colors.white),
                    label: Text('add_screen.new_addition'.tr(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index, Color color) {
    bool isSelected = _selectedFilter == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: color.withValues(alpha: 0.2),
      backgroundColor: Colors.transparent,
      labelStyle: TextStyle(color: isSelected ? color : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? color.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.2))),
      onSelected: (_) => setState(() => _selectedFilter = index),
    );
  }

  Widget _buildRoutineCard(dynamic r, BuildContext context, AstroState astroState, Color surfaceColor, Color textColor, Color hintColor) {
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
          child: Directionality(textDirection: ui.TextDirection.ltr, child: Text(timeText, textAlign: TextAlign.right, style: TextStyle(color: hintColor, fontSize: 13, fontWeight: r.isAstroTime ? FontWeight.w900 : FontWeight.w600, fontFamily: r.isAstroTime ? 'Playfair Display' : 'Inter', letterSpacing: r.isAstroTime ? 1.0 : 0.0))),
        ),
        trailing: IconButton(
          icon: Icon(LucideIcons.pencil, color: textColor.withValues(alpha: 0.7), size: 20),
          onPressed: () {
            Navigator.pop(context);
            showModalBottomSheet(
              context: context, 
              isScrollControlled: true, 
              backgroundColor: Colors.transparent, 
              builder: (_) => UniversalAddScreen(currentPeriodId: astroState.currentPeriod.id, currentSuwaya: astroState.currentSuwaya, existingRoutine: r)
            );
          },
        ),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel t, BuildContext context, AstroState astroState, Color surfaceColor, Color textColor, Color hintColor) {
    Color tColor = _getNeonColor(t.category);
    String timeText = '';
    
    if (t.isAstroTime && t.targetSuwayas.isNotEmpty) {
      final sm = t.targetVirtualMinute.toString().padLeft(2, '0');
      timeText = '${'common.astro'.tr()} (${'common.suwaya'.tr()} ${t.targetSuwayas.first}:$sm)';
    } else if (!t.isAstroTime && t.targetCivilTimeMinutes != null) {
      final sh = (t.targetCivilTimeMinutes! ~/ 60).toString().padLeft(2, '0');
      final sm = (t.targetCivilTimeMinutes! % 60).toString().padLeft(2, '0');
      timeText = '${'common.civil'.tr()} ($sh:$sm)';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: tColor.withValues(alpha: 0.3))),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(width: 16, height: 16, decoration: BoxDecoration(color: tColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: tColor.withValues(alpha: 0.5), blurRadius: 6)])),
        title: Text(t.title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Directionality(textDirection: ui.TextDirection.ltr, child: Text(timeText, textAlign: TextAlign.right, style: TextStyle(color: hintColor, fontSize: 13, fontWeight: t.isAstroTime ? FontWeight.w900 : FontWeight.w600, fontFamily: t.isAstroTime ? 'Playfair Display' : 'Inter', letterSpacing: t.isAstroTime ? 1.0 : 0.0))),
        ),
        trailing: IconButton(
          icon: Icon(LucideIcons.pencil, color: textColor.withValues(alpha: 0.7), size: 20),
          onPressed: () {
            Navigator.pop(context);
            showModalBottomSheet(
              context: context, 
              isScrollControlled: true, 
              backgroundColor: Colors.transparent, 
              builder: (_) => UniversalAddScreen(currentPeriodId: astroState.currentPeriod.id, currentSuwaya: astroState.currentSuwaya, existingTask: t, initialTab: t.type == TaskType.permanent ? 1 : 0)
            );
          },
        ),
      ),
    );
  }

  Color _getNeonColor(TaskCategory category) {
    final catStr = category.toString().toLowerCase();
    if (catStr.contains('work')) return const Color(0xFF00E5FF);
    if (catStr.contains('study')) return const Color(0xFF00E676);
    if (catStr.contains('sport')) return const Color(0xFFFF3D00);
    if (catStr.contains('worship')) return const Color(0xFFFFC400);
    if (catStr.contains('entertainment')) return const Color(0xFFFF4081);
    if (catStr.contains('personal')) return const Color(0xFFD500F9);
    if (catStr.contains('social')) return const Color(0xFF76FF03);
    return const Color(0xFF18FFFF);
  }
}