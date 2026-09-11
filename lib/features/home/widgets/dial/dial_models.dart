import 'package:flutter/material.dart';
import '../../../../models/task_model.dart';

class DialTask {
  final TaskModel taskModel; 
  final String shortName; 
  final DateTime time;
  final Color color;

  DialTask({
    required this.taskModel, 
    required this.shortName, 
    required this.time, 
    required this.color
  });
}

class UnifiedDialItem {
  final String text;
  final DateTime time;
  final Color color;
  final TaskModel? taskModel; 
  final bool isPrayer; 

  UnifiedDialItem({
    required this.text, 
    required this.time, 
    required this.color, 
    this.taskModel, 
    this.isPrayer = false
  });
}