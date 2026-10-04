import 'package:flutter/material.dart';
import '../../../../models/task_model.dart';

class DialTask {
  final TaskModel taskModel;
  final String shortName;
  final DateTime time;
  final Color color;

  DialTask(
      {required this.taskModel,
      required this.shortName,
      required this.time,
      required this.color});
}

class UnifiedDialItem {
  final String id;
  final String text;
  final DateTime time;
  final Color color;
  final TaskModel? taskModel;
  final bool isPrayer;

  UnifiedDialItem(
      {required this.id,
      required this.text,
      required this.time,
      required this.color,
      this.taskModel,
      this.isPrayer = false});
}

class DialMarkerLayout {
  final UnifiedDialItem item;
  final double angle;
  final double radius;
  final bool isBadge;

  const DialMarkerLayout({
    required this.item,
    required this.angle,
    required this.radius,
    this.isBadge = false,
  });
}

enum DialSelectionType { prayer, task, routine, period }

class DialSelection {
  final String id;
  final DialSelectionType type;
  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  final Color color;

  const DialSelection({
    required this.id,
    required this.type,
    required this.title,
    required this.startTime,
    this.endTime,
    required this.color,
  });
}
