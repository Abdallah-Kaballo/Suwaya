import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suwaya/models/task_model.dart';
import 'package:suwaya/features/tasks/tasks_provider.dart';
import 'package:suwaya/core/repositories/task_repository.dart';
import 'package:suwaya/core/astro_engine/astro_provider.dart';
import 'package:suwaya_time/suwaya_time.dart';
import 'package:suwaya/models/settings_model.dart';
import 'package:suwaya/features/settings/settings_provider.dart';

// 1. قاعدة بيانات وهمية للمهام (Fake Repository)
class FakeTaskRepository implements TaskRepository {
  List<TaskModel> fakeDatabase = [];

  @override
  Future<List<TaskModel>> getActiveTasks() async => fakeDatabase;

  @override
  Future<void> saveTask(TaskModel task) async {
    final index = fakeDatabase.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      fakeDatabase[index] = task;
    } else {
      fakeDatabase.add(task);
    }
  }

  @override
  Future<void> deleteTask(int id) async {
    fakeDatabase.removeWhere((t) => t.id == id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// 2. تجميد الزمن الفلكي (Fake Astro)
class FakeAstroNotifier extends AstroNotifier {
  @override
  AstroState build() {
    final now = DateTime(2026, 1, 1, 12, 0);
    final dummyPeriod = AstroPeriod(
      id: 3, name: 'الظهر', nameKey: 'period_dhuhr',
      startTime: now.subtract(const Duration(hours: 1)),
      endTime: now.add(const Duration(hours: 2)),
      suwayasCount: 7, colorValue: 0
    );
    return AstroState(
      virtualTime: now, periods: [dummyPeriod], currentPeriod: dummyPeriod,
      currentSuwaya: 1, elapsedVirtualTime: Duration.zero, suwayaProgress: 0,
      timeSpeedMultiplier: 1.0, 
      ibadatTimings: IbadatTimings(
        fajr: now, sunrise: now, dhuhr: now, asr: now, maghrib: now, isha: now, nextFajr: now, nightParts: []
      ),
      currentFormattedVirtualTime: '00:00'
    );
  }
}

// 3. 🌟 (الجديد) مزود إعدادات وهمي لمنع الاتصال بقاعدة البيانات الحقيقية
class FakeSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() {
    return SettingsModel(); // يعيد إعدادات افتراضية نظيفة
  }

  @override
  Future<void> updateGlobalStreak() async {
    // 🌟 تم إضافة Future<void> و async ليتطابق مع الكلاس الأصلي
    // نوقف العملية هنا لكي لا يحاول Riverpod الكتابة في قاعدة البيانات
  }
}

void main() {
  group('اختبارات مزود المهام (TasksNotifier Business Logic)', () {
    
    test('1. إنجاز عادة دائمة يجب أن يرفع الاستريك ويسجلها لليوم بنجاح', () async {
      final fakeRepo = FakeTaskRepository();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      
      final task = TaskModel()
        ..id = 1
        ..title = 'قراءة القرآن'
        ..type = TaskType.permanent
        ..currentStreak = 5
        ..longestStreak = 5
        // 🌟 نملأ السجل بـ 5 تواريخ وهمية سابقة لكي يعمل المنطق الرياضي بشكل صحيح
        ..completionHistory = List.generate(5, (index) => yesterday); 
        
      fakeRepo.fakeDatabase.add(task);

      final container = ProviderContainer(
        overrides: [
          taskRepositoryProvider.overrideWithValue(fakeRepo),
          astroProvider.overrideWith(() => FakeAstroNotifier()),
          // 🌟 حقن الإعدادات الوهمية
          settingsProvider.overrideWith(() => FakeSettingsNotifier()), 
        ],
      );

      final notifier = container.read(tasksProvider.notifier);
      await notifier.loadTasks();

      var state = container.read(tasksProvider);
      await notifier.toggleTaskStatus(state.allTasks.first);

      state = container.read(tasksProvider);
      final updatedTask = state.allTasks.first;
      
      expect(updatedTask.currentStreak, equals(6), reason: 'يجب أن يزيد الاستريك بواحد');
      expect(updatedTask.longestStreak, equals(6), reason: 'الرقم القياسي يجب أن يتحدث مع الاستريك الحالي');
      expect(updatedTask.isCompletedToday, isTrue, reason: 'يجب أن تُسجل كمنجزة لليوم الحاضر');
    });

    test('2. التراجع عن مهمة دائمة (Undo) يكسر الاستريك الأخير ويمسح سجل اليوم', () async {
      final fakeRepo = FakeTaskRepository();
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      
      final task = TaskModel()
        ..id = 2
        ..title = 'رياضة'
        ..type = TaskType.permanent
        ..currentStreak = 10
        ..longestStreak = 15
        ..lastCompletedDate = today
        // 🌟 محاكاة سجل به 9 تواريخ قديمة + إنجاز اليوم = 10
        ..completionHistory = [...List.generate(9, (index) => yesterday), today]; 
        
      fakeRepo.fakeDatabase.add(task);

      final container = ProviderContainer(
        overrides: [
          taskRepositoryProvider.overrideWithValue(fakeRepo),
          astroProvider.overrideWith(() => FakeAstroNotifier()),
          settingsProvider.overrideWith(() => FakeSettingsNotifier()),
        ],
      );

      final notifier = container.read(tasksProvider.notifier);
      await notifier.loadTasks();

      // التراجع عن الإنجاز
      await notifier.toggleTaskStatus(container.read(tasksProvider).allTasks.first);

      final updatedTask = container.read(tasksProvider).allTasks.first;
      expect(updatedTask.currentStreak, equals(9), reason: 'يجب أن يُخصم الاستريك الأخير عند التراجع');
      expect(updatedTask.longestStreak, equals(15), reason: 'الرقم القياسي التاريخي لا يجب أن يتأثر بالتراجع');
      expect(updatedTask.isCompletedToday, isFalse);
    });
    
    test('3. فصل المهام حسب التوقيت (Today Tasks vs Horizon Tasks)', () async {
      final fakeRepo = FakeTaskRepository();
      final permanentTask = TaskModel()..id = 1..type = TaskType.permanent; 
      final tomorrowTask = TaskModel()..id = 2..type = TaskType.casual..targetDate = DateTime.now().add(const Duration(days: 1)); 
      
      fakeRepo.fakeDatabase.addAll([permanentTask, tomorrowTask]);

      final container = ProviderContainer(
        overrides: [
          taskRepositoryProvider.overrideWithValue(fakeRepo),
          astroProvider.overrideWith(() => FakeAstroNotifier()),
          settingsProvider.overrideWith(() => FakeSettingsNotifier()),
        ],
      );

      final notifier = container.read(tasksProvider.notifier);
      await notifier.loadTasks();

      final state = container.read(tasksProvider);
      
      expect(state.todayTasks.length, equals(1), reason: 'المهمة الدائمة فقط تظهر في قائمة اليوم');
      expect(state.todayTasks.first.id, equals(1));
      
      expect(state.horizonTasks.length, equals(1), reason: 'مهمة الغد العابرة يجب أن تذهب لقائمة الأفق');
      expect(state.horizonTasks.first.id, equals(2));
    });

  });
}