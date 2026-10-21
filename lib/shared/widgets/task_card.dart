import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task_model.dart';
import '../../features/tasks/tasks_provider.dart';

class TaskCard extends ConsumerStatefulWidget {
  final TaskModel task;
  const TaskCard({super.key, required this.task});

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard> {
  bool _isLocalCompleted = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = t.category.uiColor(isDark);
    final surfaceColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: catColor.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact();
              setState(() => _isLocalCompleted = true);
              Future.delayed(
                const Duration(milliseconds: 400),
                () => ref.read(tasksProvider.notifier).toggleTaskStatus(t),
              );
            },
            child: Container(
              margin: const EdgeInsetsDirectional.only(end: 16),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: catColor, width: 2),
                color: _isLocalCompleted ? catColor : Colors.transparent,
              ),
              child: _isLocalCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    color: _isLocalCompleted ? Colors.grey : textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    decoration:
                        _isLocalCompleted ? TextDecoration.lineThrough : null,
                  ),
                  child: Text(t.title),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    t.category.displayName,
                    style: TextStyle(
                      color: catColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (t.alarmMode || t.notifyMode)
            Icon(
              t.alarmMode ? Icons.alarm : Icons.notifications_active,
              color: catColor.withValues(alpha: 0.65),
              size: 18,
            ),
        ],
      ),
    );
  }
}