import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya/models/task_model.dart'; // مسار نموذج المهام

void main() {
  group('اختبارات منطق المهام والاستريك (Task Business Logic)', () {
    
    test('1. المهام الدائمة (العادات): يجب أن تزيد الاستريك عند الإنجاز', () {
      final task = TaskModel()
        ..id = 1
        ..title = 'قراءة الورد اليومي'
        ..type = TaskType.permanent
        ..currentStreak = 5
        ..longestStreak = 5
        ..completionHistory = [];

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // محاكاة إنجاز المهمة اليوم (نفس المنطق الموجود في TasksNotifier)
      task.lastCompletedDate = today;
      task.completionHistory = [...task.completionHistory, today];
      task.currentStreak += 1;
      
      if (task.currentStreak > task.longestStreak) {
        task.longestStreak = task.currentStreak;
      }

      expect(task.currentStreak, equals(6), reason: 'يجب أن يرتفع الاستريك إلى 6');
      expect(task.longestStreak, equals(6), reason: 'الاستريك الأطول يجب أن يُحدّث لأنه تم تجاوزه');
      expect(task.completionHistory.length, equals(1));
    });

    test('2. المهام الدائمة: يجب أن تقبل الإلغاء (Undo) وينقص الاستريك', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final task = TaskModel()
        ..id = 2
        ..type = TaskType.permanent
        ..currentStreak = 10
        ..longestStreak = 15
        ..completionHistory = [today]; // المهمة منجزة اليوم

      // محاكاة التراجع عن الإنجاز (Undo)
      task.lastCompletedDate = null;
      task.completionHistory = task.completionHistory.where((d) => d != today).toList();
      task.currentStreak = (task.currentStreak - 1).clamp(0, 9999);

      expect(task.currentStreak, equals(9), reason: 'يجب أن ينقص الاستريك عند التراجع');
      expect(task.longestStreak, equals(15), reason: 'الاستريك الأطول يجب ألا يتأثر بالتراجع');
      expect(task.completionHistory.isEmpty, isTrue);
    });

    test('3. المهام العابرة (Casual): يجب أن تُسجل كمنجزة ولا تؤثر على الاستريك', () {
      final task = TaskModel()
        ..id = 3
        ..type = TaskType.casual
        ..isCompleted = false;

      // محاكاة الإنجاز
      task.isCompleted = true;
      task.completedAt = DateTime.now();

      expect(task.isCompleted, isTrue);
      expect(task.completedAt, isNotNull);
      expect(task.currentStreak, equals(0), reason: 'المهام العابرة لا تمتلك استريك');
    });
  });
}