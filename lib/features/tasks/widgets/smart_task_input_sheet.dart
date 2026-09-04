import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../models/task_model.dart';
import '../tasks_provider.dart';
import '../../../core/astro_engine/astro_provider.dart';

class SmartTaskInputSheet extends ConsumerStatefulWidget {
  const SmartTaskInputSheet({super.key});

  @override
  ConsumerState<SmartTaskInputSheet> createState() => _SmartTaskInputSheetState();
}

class _SmartTaskInputSheetState extends ConsumerState<SmartTaskInputSheet> {
  final TextEditingController _titleController = TextEditingController();
  
  DateTime? _selectedDate;
  int? _selectedPeriodId;
  int? _selectedSuwaya;
  
  TaskCategory _selectedCategory = TaskCategory.unspecified; 
  bool _isPermanent = false;
  
  // 🌟 تم التعديل: استخدام المتغيرات الثلاثة الجديدة
  bool _notifyMode = true;
  final bool _alarmMode = false;
  final bool _vibrateMode = false;

  final Map<int, String> _periods = {
    1: 'الفترة الأولى', 2: 'الفترة الثانية', 3: 'الفترة الثالثة', 4: 'الفترة الرابعة', 5: 'الفترة الخامسة', 6: 'الفترة السادسة', 7: 'الفترة السابعة'
  };

  bool _isSelectingPeriod = false;
  bool _isSelectingSuwaya = false;
  bool _isSelectingCategory = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _saveTask() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final newTask = TaskModel()
      ..title = title
      ..type = _isPermanent ? TaskType.permanent : TaskType.casual  
      ..category = _selectedCategory
      // 🌟 تم التعديل: حفظ الخيارات الجديدة
      ..notifyMode = _notifyMode
      ..alarmMode = _alarmMode
      ..vibrateMode = _vibrateMode
      ..targetDate = _selectedDate != null 
          ? DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day) 
          : null
      ..targetPeriodId = _selectedPeriodId
      ..targetSuwayas = _selectedSuwaya != null ? [_selectedSuwaya!] : []; 

    ref.read(tasksProvider.notifier).addTask(newTask);
    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark 
            ? ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(primary: Colors.amber, onPrimary: Colors.black, surface: Color(0xFF1E2530), onSurface: Colors.white),
              )
            : ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(primary: Colors.amber, onPrimary: Colors.white, surface: Colors.white, onSurface: Colors.black),
              ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInputEmpty = _titleController.text.trim().isEmpty;
    final astroState = ref.watch(astroProvider);
    final selectedAstroPeriod = astroState.periods.where((p) => p.id == _selectedPeriodId).firstOrNull;
    final suwayasCount = selectedAstroPeriod?.suwayasCount ?? 7; 
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E2530) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black38;
    final dividerColor = isDark ? Colors.white12 : Colors.black12;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w500),
              onChanged: (value) => setState(() {}),
              onSubmitted: (_) => _saveTask(),
              decoration: InputDecoration(
                hintText: 'what_on_your_mind'.tr(),
                hintStyle: TextStyle(color: hintColor, fontSize: 18),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildActionChip(
                    icon: LucideIcons.calendar,
                    label: _selectedDate != null 
                        ? (_selectedDate!.day == DateTime.now().day ? 'today'.tr() : DateFormat('d MMM', context.locale.languageCode).format(_selectedDate!))
                        : 'no_date'.tr(),
                    color: _selectedDate != null ? Colors.greenAccent : (isDark ? Colors.white70 : Colors.black54),
                    isActive: _selectedDate != null,
                    onTap: _pickDate,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),

                  _buildActionChip(
                    icon: LucideIcons.moon,
                    label: _selectedPeriodId != null ? _periods[_selectedPeriodId]! : 'add_to_period'.tr(),
                    color: _selectedPeriodId != null ? Colors.amber : (isDark ? Colors.white70 : Colors.black54),
                    isActive: _selectedPeriodId != null || _isSelectingPeriod,
                    onTap: () => setState(() {
                      _isSelectingPeriod = !_isSelectingPeriod;
                      _isSelectingSuwaya = false;
                      _isSelectingCategory = false;
                    }),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),

                  if (_selectedPeriodId != null) ...[
                    _buildActionChip(
                      icon: LucideIcons.clock,
                      label: _selectedSuwaya != null ? 'سُويعَة $_selectedSuwaya' : 'سُويعَة مرنة',
                      color: _selectedSuwaya != null ? Colors.blueAccent : (isDark ? Colors.white70 : Colors.black54),
                      isActive: _selectedSuwaya != null || _isSelectingSuwaya,
                      onTap: () => setState(() {
                        _isSelectingSuwaya = !_isSelectingSuwaya;
                        _isSelectingPeriod = false;
                        _isSelectingCategory = false;
                      }),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                  ],

                  _buildActionChip(
                    icon: LucideIcons.tag,
                    label: _selectedCategory.displayName, 
                    color: Colors.purpleAccent,
                    isActive: _isSelectingCategory,
                    onTap: () => setState(() {
                      _isSelectingCategory = !_isSelectingCategory;
                      _isSelectingPeriod = false;
                      _isSelectingSuwaya = false;
                    }),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),

                  _buildActionChip(
                    icon: LucideIcons.repeat,
                    label: 'recurring'.tr(),
                    color: _isPermanent ? Colors.orangeAccent : (isDark ? Colors.white70 : Colors.black54),
                    isActive: _isPermanent,
                    onTap: () => setState(() => _isPermanent = !_isPermanent),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),

                  // 🌟 زر الجرس يعكس حالة الإشعار
                  _buildActionChip(
                    icon: _notifyMode ? LucideIcons.bell : LucideIcons.bell_off,
                    label: _notifyMode ? 'تنبيه مفعل' : 'صامت',
                    color: _notifyMode ? Colors.amber : (isDark ? Colors.white38 : Colors.black38),
                    isActive: _notifyMode,
                    onTap: () => setState(() => _notifyMode = !_notifyMode),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCirc,
              child: Column(
                children: [
                  if (_isSelectingPeriod)
                    _buildSelectionList(
                      items: _periods.values.toList(),
                      selectedIndex: _selectedPeriodId != null ? _selectedPeriodId! - 1 : -1,
                      color: Colors.amber,
                      isDark: isDark,
                      onSelected: (index) => setState(() {
                        _selectedPeriodId = index + 1;
                        _isSelectingPeriod = false;
                        _isSelectingSuwaya = true; 
                      }),
                    ),

                  if (_isSelectingSuwaya && _selectedPeriodId != null)
                    _buildSelectionList(
                      items: List.generate(suwayasCount, (i) => 'سُويعَة ${i + 1}'),
                      selectedIndex: _selectedSuwaya != null ? _selectedSuwaya! - 1 : -1,
                      color: Colors.blueAccent,
                      isDark: isDark,
                      onSelected: (index) => setState(() {
                        _selectedSuwaya = index + 1;
                        _isSelectingSuwaya = false;
                      }),
                    ),

                  if (_isSelectingCategory)
                    _buildSelectionList(
                      items: TaskCategory.values.map((c) => c.displayName).toList(), 
                      selectedIndex: TaskCategory.values.indexOf(_selectedCategory),
                      color: Colors.purpleAccent,
                      isDark: isDark,
                      onSelected: (index) => setState(() {
                        _selectedCategory = TaskCategory.values[index];
                        _isSelectingCategory = false;
                      }),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Divider(color: dividerColor, height: 1),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.inbox, color: hintColor, size: 18),
                    const SizedBox(width: 8),
                    Text(_selectedPeriodId != null ? 'مهام ${_periods[_selectedPeriodId]}' : 'inbox'.tr(), 
                      style: TextStyle(color: hintColor, fontSize: 14)),
                  ],
                ),
                GestureDetector(
                  onTap: isInputEmpty ? null : _saveTask,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isInputEmpty ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)) : Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.send,
                      color: isInputEmpty ? (isDark ? Colors.white38 : Colors.black38) : Colors.black87,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip({required IconData icon, required String label, required Color color, required bool isActive, required VoidCallback onTap, required bool isDark}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.1) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
          border: Border.all(color: isActive ? color.withValues(alpha: 0.3) : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05))),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionList({required List<String> items, required int selectedIndex, required Color color, required Function(int) onSelected, required bool isDark}) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          bool isSelected = index == selectedIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(items[index]),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: color.withValues(alpha: 0.2),
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              labelStyle: TextStyle(color: isSelected ? color : (isDark ? Colors.white70 : Colors.black87), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? color.withValues(alpha: 0.5) : Colors.transparent)),
              onSelected: (_) => onSelected(index),
            ),
          );
        },
      ),
    );
  }
}