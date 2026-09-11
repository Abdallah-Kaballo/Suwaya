import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../models/task_model.dart';
import '../tasks_provider.dart';
import '../../../core/astro_engine/astro_provider.dart';

class TaskEditorSheet extends ConsumerStatefulWidget {
  final TaskModel? existingTask;
  const TaskEditorSheet({super.key, this.existingTask});

  @override
  ConsumerState<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends ConsumerState<TaskEditorSheet> {
  late TextEditingController _titleController;
  
  TaskType _selectedType = TaskType.casual;
  TaskCategory _selectedCategory = TaskCategory.unspecified;
  DateTime? _selectedDate;
  int? _selectedPeriodId;
  List<int> _selectedSuwayas = [];
  List<int> _recurrenceDays = [];

  List<String> _historicalTitles = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _loadHistory();

    if (widget.existingTask != null) {
      final t = widget.existingTask!;
      _titleController.text = t.title;
      _selectedType = t.type;
      _selectedCategory = t.category;
      _selectedDate = t.targetDate ?? DateTime.now();
      _selectedPeriodId = t.targetPeriodId;
      _selectedSuwayas = List.from(t.targetSuwayas);
      _recurrenceDays = List.from(t.recurrenceDays ?? []);
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final titles = await ref.read(tasksProvider.notifier).getUniqueTaskTitles();
    setState(() => _historicalTitles = titles);
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final task = widget.existingTask ?? TaskModel();
    task.title = title;
    
    // 🌟 الإصلاح 10: حفظ نوع المهمة الحقيقي والسويعة الحقيقية
    task.type = _selectedType; 
    task.category = _selectedCategory;
    task.targetPeriodId = _selectedPeriodId;
    task.targetSuwayas = _selectedSuwayas.isNotEmpty ? [_selectedSuwayas.first] : [];

    if (_selectedType == TaskType.casual) {
      task.targetDate = _selectedDate;
      task.recurrenceDays = null;
    } else {
      task.targetDate = null;
      task.recurrenceDays = _recurrenceDays.isEmpty ? null : _recurrenceDays;
    }

    ref.read(tasksProvider.notifier).addTask(task);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final astroState = ref.watch(astroProvider);
    final isHabit = _selectedType == TaskType.permanent;
    final accentColor = isHabit ? Colors.amber : Colors.blueAccent;
    final safeIntl = (context.locale.languageCode == 'ff' || context.locale.languageCode == 'ug') ? 'en' : context.locale.languageCode;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SegmentedButton<TaskType>(
                segments: [
                  ButtonSegment(value: TaskType.casual, label: Text('tasks.casual_task'.tr()), icon: const Icon(LucideIcons.circle_check)),
                  ButtonSegment(value: TaskType.permanent, label: Text('tasks.continuous_habit'.tr()), icon: const Icon(LucideIcons.repeat)),
                ],
                selected: {_selectedType},
                onSelectionChanged: (set) => setState(() => _selectedType = set.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.selected) ? accentColor.withValues(alpha: 0.2) : Colors.transparent),
                  foregroundColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.selected) ? accentColor : Colors.white54),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                return _historicalTitles.where(
                    (title) => title.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (selection) {
                _titleController.text = selection;
                _titleController.selection = TextSelection.fromPosition(
                    TextPosition(offset: selection.length));
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                if (_titleController.text != controller.text) {
                  controller.text = _titleController.text;
                }
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: isHabit ? 'add_screen.what_habit'.tr() : 'add_screen.what_task'.tr(),
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    border: InputBorder.none,
                  ),
                  onChanged: (text) {
                    _titleController.text = text;
                  },
                  onSubmitted: (text) => _save(),
                );
              },
            ),

            const Divider(color: Colors.white12),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  if (!isHabit)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(LucideIcons.calendar, color: Colors.blueAccent),
                      title: Text('add_screen.date'.tr(), style: const TextStyle(color: Colors.white)),
                      trailing: Text(DateFormat('yyyy-MM-dd').format(_selectedDate!),
                          style: const TextStyle(color: Colors.blueAccent)),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate!,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                    )
                  else ...[
                    const SizedBox(height: 8),
                    Text('add_screen.recurrence_days_hint'.tr(), style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: List.generate(7, (index) {
                        final day = index + 1;
                        final isSelected = _recurrenceDays.contains(day);
                        return FilterChip(
                          label: Text(DateFormat('EEEE', safeIntl).format(DateTime(2024, 1, day))),
                          selected: isSelected,
                          selectedColor: Colors.amber.withValues(alpha: 0.2),
                          checkmarkColor: Colors.amber,
                          labelStyle: TextStyle(color: isSelected ? Colors.amber : Colors.white54),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _recurrenceDays.add(day);
                              } else {
                                _recurrenceDays.remove(day);
                              }
                            });
                          },
                        );
                      }),
                    ),
                  ],

                  const SizedBox(height: 20),

                  Text('add_screen.category_appearance'.tr(), style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<TaskCategory>(
                    initialValue: _selectedCategory,
                    dropdownColor: const Color(0xFF2A3441),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: TaskCategory.values.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat.displayName),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val!),
                  ),

                  const SizedBox(height: 20),

                  Text('add_screen.astro_connection'.tr(), style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    initialValue: _selectedPeriodId,
                    dropdownColor: const Color(0xFF2A3441),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text('add_screen.no_specific_period'.tr())),
                      ...astroState.periods.map(
                          (p) => DropdownMenuItem(value: p.id, child: Text(p.nameKey.tr()))),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedPeriodId = val;
                        _selectedSuwayas.clear();
                      });
                    },
                  ),
                  if (_selectedPeriodId != null) ...[
                    const SizedBox(height: 12),
                    Text('add_screen.suwayas_hint'.tr(), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: List.generate(
                        astroState.periods
                            .firstWhere((p) => p.id == _selectedPeriodId)
                            .suwayasCount,
                        (index) {
                          final sNum = index + 1;
                          final isSelected = _selectedSuwayas.contains(sNum);
                          return FilterChip(
                            label: Text('${'common.suwaya'.tr()} $sNum'),
                            selected: isSelected,
                            selectedColor: accentColor.withValues(alpha: 0.2),
                            checkmarkColor: accentColor,
                            labelStyle: TextStyle(
                                color: isSelected ? accentColor : Colors.white54),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedSuwayas.add(sNum);
                                } else {
                                  _selectedSuwayas.remove(sNum);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('common.save'.tr(),
                    style: TextStyle(
                        color: isHabit ? Colors.black : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}