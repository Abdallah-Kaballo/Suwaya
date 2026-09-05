import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection; 
import 'dart:ui' as ui;

import 'tasks_provider.dart';
import '../../models/task_model.dart';
import '../../models/routine_model.dart';
import '../../core/astro_engine/astro_provider.dart';
import '../../core/astro_engine/astro_models.dart';
import '../routines/routines_provider.dart';
import 'screens/universal_add_screen.dart';

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

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});
  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  bool _isSelectionMode = false;
  final Set<int> _selectedTaskIds = {};
  final Set<int> _selectedRoutineIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) _clearSelection();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _clearSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedTaskIds.clear();
      _selectedRoutineIds.clear();
    });
  }

  void _toggleSelection(int id, bool isRoutine) {
    HapticFeedback.selectionClick();
    setState(() {
      final targetSet = isRoutine ? _selectedRoutineIds : _selectedTaskIds;
      if (targetSet.contains(id)) {
        targetSet.remove(id);
        if (_selectedTaskIds.isEmpty && _selectedRoutineIds.isEmpty) _isSelectionMode = false;
      } else {
        targetSet.add(id);
      }
    });
  }

  void _deleteSelectedItems() {
    HapticFeedback.heavyImpact();
    if (_tabController.index == 2) {
      for (var id in _selectedRoutineIds) {
        ref.read(routinesProvider.notifier).deleteRoutine(id);
      }
    } else {
      ref.read(tasksProvider.notifier).deleteMultipleTasks(_selectedTaskIds.toList());
    }
    _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).cardColor;
    final accentColor = Theme.of(context).primaryColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    final allTasks = ref.watch(tasksProvider).allTasks;
    final routines = ref.watch(routinesProvider);
    final astroState = ref.watch(astroProvider);
    final periods = astroState.periods;

    List<TaskModel> casualTasks = allTasks.where((t) => t.type == TaskType.casual && !t.isCompleted).toList();
    List<TaskModel> habits = allTasks.where((t) => t.type == TaskType.permanent && !t.isCompletedToday).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: _isSelectionMode
            ? Text('${_selectedTaskIds.length + _selectedRoutineIds.length} ${'tasks.selected'.tr()}', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold))
            : Text('tasks.suwaya_management'.tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 22)),
        leading: _isSelectionMode 
            ? IconButton(icon: Icon(LucideIcons.x, color: textColor), onPressed: _clearSelection) 
            : null,
        actions: [
          if (_isSelectionMode)
            IconButton(icon: const Icon(LucideIcons.trash_2, color: Colors.redAccent), onPressed: _deleteSelectedItems),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: accentColor.withValues(alpha: 0.1))),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(color: accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14), border: Border.all(color: accentColor, width: 2)),
                labelColor: accentColor, unselectedLabelColor: textColor.withValues(alpha: 0.4),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [Tab(text: 'tasks.tab_casual'.tr()), Tab(text: 'tasks.tab_habits'.tr()), Tab(text: 'tasks.tab_routines'.tr())],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTasksList(casualTasks, periods, false),
          _buildTasksList(habits, periods, false),
          _buildRoutinesList(routines, periods),
        ],
      ),
      floatingActionButton: _isSelectionMode ? null : Padding(
        padding: const EdgeInsets.only(bottom: 90.0), // رفع الزر فوق الشريط الزجاجي
        child: FloatingActionButton.extended(
          backgroundColor: accentColor,
          onPressed: () {
            HapticFeedback.heavyImpact();
            showModalBottomSheet(
              context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
              builder: (_) => UniversalAddScreen(currentPeriodId: astroState.currentPeriod.id, currentSuwaya: astroState.currentSuwaya, initialTab: _tabController.index),
            );
          },
          icon: const Icon(LucideIcons.plus, color: Colors.white),
          label: Text('common.add'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildTasksList(List<TaskModel> tasks, List<AstroPeriod> periods, bool isHabit) {
    if (tasks.isEmpty) return _buildEmptyState('tasks.empty_tasks'.tr());
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildSwipeableRow(
          id: task.id,
          isRoutine: false,
          child: _TaskRowItem(
            task: task, periods: periods, isSelectionMode: _isSelectionMode, isSelected: _selectedTaskIds.contains(task.id),
            onLongPress: () { _isSelectionMode = true; _toggleSelection(task.id, false); },
            onTap: () { 
              if (_isSelectionMode) {
                _toggleSelection(task.id, false); 
              } else {
                _editTask(task); 
              }
            },
          ),
          onDelete: () => ref.read(tasksProvider.notifier).deleteTask(task.id),
          onEdit: () => _editTask(task),
        );
      },
    );
  }

  Widget _buildRoutinesList(List<RoutineModel> routines, List<AstroPeriod> periods) {
    if (routines.isEmpty) return _buildEmptyState('tasks.empty_routines'.tr());
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: routines.length,
      itemBuilder: (context, index) {
        final r = routines[index];
        return _buildSwipeableRow(
          id: r.id,
          isRoutine: true,
          child: _RoutineRowItem(
            routine: r, periods: periods, isSelectionMode: _isSelectionMode, isSelected: _selectedRoutineIds.contains(r.id),
            onLongPress: () { _isSelectionMode = true; _toggleSelection(r.id, true); },
            onTap: () { 
              if (_isSelectionMode) {
                _toggleSelection(r.id, true); 
              } else {
                _editRoutine(r); 
              }
            },
          ),
          onDelete: () => ref.read(routinesProvider.notifier).deleteRoutine(r.id),
          onEdit: () => _editRoutine(r),
        );
      },
    );
  }

  Widget _buildSwipeableRow({required int id, required bool isRoutine, required Widget child, required VoidCallback onDelete, required VoidCallback onEdit}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Dismissible(
        key: ValueKey('swipe_${isRoutine ? "r" : "t"}_$id'),
        direction: _isSelectionMode ? DismissDirection.none : DismissDirection.horizontal,
        background: Container(color: Colors.redAccent, alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(horizontal: 24), child: const Icon(LucideIcons.trash_2, color: Colors.white)), 
        secondaryBackground: Container(color: Colors.blueAccent, alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 24), child: const Icon(LucideIcons.pencil, color: Colors.white)), 
        confirmDismiss: (dir) async {
          if (dir == DismissDirection.startToEnd) return true; 
          onEdit(); return false; 
        },
        onDismissed: (_) => onDelete(),
        child: child,
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(LucideIcons.layout_list, size: 64, color: Colors.grey.withValues(alpha: 0.2)), const SizedBox(height: 16), Text(msg, style: const TextStyle(color: Colors.grey))]));
  }

  void _editTask(TaskModel task) {
    HapticFeedback.selectionClick();
    final astro = ref.read(astroProvider);
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => UniversalAddScreen(currentPeriodId: astro.currentPeriod.id, currentSuwaya: astro.currentSuwaya, existingTask: task));
  }
  void _editRoutine(RoutineModel r) {
    HapticFeedback.selectionClick();
    final astro = ref.read(astroProvider);
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => UniversalAddScreen(currentPeriodId: astro.currentPeriod.id, currentSuwaya: astro.currentSuwaya, existingRoutine: r));
  }
}

class _TaskRowItem extends ConsumerStatefulWidget {
  final TaskModel task; final List<AstroPeriod> periods; final bool isSelectionMode; final bool isSelected; final VoidCallback onTap; final VoidCallback onLongPress;
  const _TaskRowItem({required this.task, required this.periods, required this.isSelectionMode, required this.isSelected, required this.onTap, required this.onLongPress});
  @override ConsumerState<_TaskRowItem> createState() => _TaskRowItemState();
}
class _TaskRowItemState extends ConsumerState<_TaskRowItem> {
  bool _isLocalCompleted = false; 

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final catColor = _getNeonColor(t.category);
    final surfaceColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    final langCode = context.locale.languageCode;
    final safeIntl = (langCode == 'ff' || langCode == 'ug') ? 'en' : langCode;

    String timeStr = '--:--';
    if (!t.isAstroTime && t.targetCivilTimeMinutes != null) {
      timeStr = '${(t.targetCivilTimeMinutes! ~/ 60).toString().padLeft(2, '0')}:${(t.targetCivilTimeMinutes! % 60).toString().padLeft(2, '0')}';
    } else if (t.isAstroTime && t.targetPeriodId != null && widget.periods.isNotEmpty) {
      int pIdx = widget.periods.indexWhere((p) => p.id == t.targetPeriodId);
      if (pIdx == -1) pIdx = 0;
      timeStr = '${pIdx.toString().padLeft(2, '0')}:${t.targetSuwayas.isNotEmpty ? t.targetSuwayas.first.toString().padLeft(2, '0') : "01"}:${t.targetVirtualMinute.toString().padLeft(2, '0')}';
    }

    String dateStr = 'add_screen.daily'.tr();
    if (t.type == TaskType.casual && t.targetDate != null) {
      dateStr = DateFormat('d/M', safeIntl).format(t.targetDate!); 
    } else if (t.type == TaskType.permanent && t.recurrenceDays != null && t.recurrenceDays!.isNotEmpty) {
      dateStr = '${t.recurrenceDays!.length} ${'common.days'.tr()}';
    }

    return GestureDetector(
      onTap: widget.onTap, onLongPress: widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(color: widget.isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : surfaceColor, border: Border.all(color: widget.isSelected ? Theme.of(context).primaryColor : Colors.transparent)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            if (widget.isSelectionMode)
              Padding(padding: const EdgeInsets.only(left: 12), child: Icon(widget.isSelected ? LucideIcons.circle_check : LucideIcons.circle, color: widget.isSelected ? Theme.of(context).primaryColor : Colors.grey))
            else
              GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  setState(() => _isLocalCompleted = true);
                  Future.delayed(const Duration(milliseconds: 400), () => ref.read(tasksProvider.notifier).toggleTaskStatus(t));
                },
                child: Container(
                  margin: const EdgeInsets.only(left: 16), width: 24, height: 24,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: catColor, width: 2), color: _isLocalCompleted ? catColor : Colors.transparent),
                  child: _isLocalCompleted ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                ),
              ),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(color: _isLocalCompleted ? Colors.grey : textColor, fontSize: 16, fontWeight: FontWeight.bold, decoration: _isLocalCompleted ? TextDecoration.lineThrough : null),
                    child: Text(t.title),
                  ),
                  const SizedBox(height: 6),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: catColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)), child: Text(t.category.displayName, style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            
            Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(timeStr, style: TextStyle(color: textColor, fontSize: 16, fontWeight: t.isAstroTime ? FontWeight.w900 : FontWeight.w600, fontFamily: t.isAstroTime ? 'Playfair Display' : 'Inter', letterSpacing: t.isAstroTime ? 1.0 : 0.0)),
                  const SizedBox(height: 2),
                  Text(dateStr, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineRowItem extends StatelessWidget {
  final RoutineModel routine; final List<AstroPeriod> periods; final bool isSelectionMode; final bool isSelected; final VoidCallback onTap; final VoidCallback onLongPress;
  const _RoutineRowItem({required this.routine, required this.periods, required this.isSelectionMode, required this.isSelected, required this.onTap, required this.onLongPress});
  @override Widget build(BuildContext context) {
    final rColor = Color(routine.colorValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String timeStr = '--:--';
    if (!routine.isAstroTime && routine.startTimeMinutes != null) {
      final sh = (routine.startTimeMinutes! ~/ 60).toString().padLeft(2, '0');
      final sm = (routine.startTimeMinutes! % 60).toString().padLeft(2, '0');
      timeStr = '${'common.civil'.tr()} (${'common.from'.tr()} $sh:$sm)';
    } else if (routine.isAstroTime && routine.startPeriodId != null) {
      int pIdx = periods.indexWhere((p) => p.id == routine.startPeriodId);
      if (pIdx == -1) pIdx = 0;
      final ss = (routine.startSuwaya ?? 1).toString().padLeft(2, '0');
      final sm = (routine.startVirtualMinute ?? 0).toString().padLeft(2, '0');
      timeStr = '${'common.astro'.tr()} (${'common.from'.tr()} ${pIdx.toString().padLeft(2, '0')}:$ss:$sm)';
    }

    String recStr = routine.recurrenceDays == null || routine.recurrenceDays!.isEmpty ? 'add_screen.daily'.tr() : '${routine.recurrenceDays!.length} ${'common.days'.tr()}';

    return GestureDetector(
      onTap: onTap, onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Theme.of(context).cardColor, border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.transparent)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            if (isSelectionMode) Padding(padding: const EdgeInsets.only(left: 12), child: Icon(isSelected ? LucideIcons.circle_check : LucideIcons.circle, color: isSelected ? Theme.of(context).primaryColor : Colors.grey)),
            Container(margin: const EdgeInsets.only(left: 16), width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: rColor, boxShadow: [BoxShadow(color: rColor.withValues(alpha: 0.5), blurRadius: 4)])),
            Expanded(child: Text(routine.title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold))),
            Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(timeStr, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13, fontWeight: routine.isAstroTime ? FontWeight.w900 : FontWeight.w600, fontFamily: routine.isAstroTime ? 'Playfair Display' : 'Inter', letterSpacing: routine.isAstroTime ? 1.0 : 0.0)),
                  const SizedBox(height: 2),
                  Text(recStr, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}