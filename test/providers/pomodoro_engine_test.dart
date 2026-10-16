import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suwaya/features/pomodoro/pomodoro_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PomodoroEngine & Suwaya Flow Calculation Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('calculateSuwayaFlowOptions selects N closest to 1.00x as recommended first option', () {
      final start = DateTime.utc(2026, 10, 16, 12, 0);
      final end = DateTime.utc(2026, 10, 16, 13, 30); // 90 دقيقة فعلية = 3 بومودورو عند سرعة 1.00x

      final options = PomodoroEngine.calculateSuwayaFlowOptions(start, end);

      expect(options, isNotEmpty);
      expect(options.first.tag, 'recommended');
      expect(options.first.pomodoroCount, 3);
      expect(options.first.flowSpeed, closeTo(1.0, 0.001));

      // التحقق من وجود خيار أبطأ (N=2 -> 0.67x) وخيار أسرع (N=4 -> 1.33x)
      expect(options.any((o) => o.tag == 'slower' && o.pomodoroCount == 2), isTrue);
      expect(options.any((o) => o.tag == 'faster' && o.pomodoroCount == 4), isTrue);
    });

    test('calculateSuwayaFlowOptions returns empty list if duration is under 15 minutes', () {
      final start = DateTime.utc(2026, 10, 16, 12, 0);
      final end = DateTime.utc(2026, 10, 16, 12, 14);

      final options = PomodoroEngine.calculateSuwayaFlowOptions(start, end);
      expect(options, isEmpty);
    });

    test('Traditional Pomodoro cycles through work, short break, and triggers long break after 4 cycles', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(pomodoroProvider.notifier);
      notifier.openTraditionalMode();

      expect(container.read(pomodoroProvider).status, PomodoroStatus.idle);
      expect(container.read(pomodoroProvider).phase, PomodoroPhase.work);
      expect(container.read(pomodoroProvider).currentCycle, 1);
      expect(container.read(pomodoroProvider).remainingSeconds, 25 * 60.0);

      // تخطي 3 دورات (عمل -> راحة قصيرة -> عمل...)
      for (int c = 1; c <= 3; c++) {
        expect(container.read(pomodoroProvider).currentCycle, c);
        expect(container.read(pomodoroProvider).phase, PomodoroPhase.work);
        notifier.skipTraditionalPhase(); // ينتقل للراحة القصيرة
        expect(container.read(pomodoroProvider).phase, PomodoroPhase.shortBreak);
        notifier.skipTraditionalPhase(); // ينتقل لدورة العمل التالية
      }

      // الآن نحن في الدورة الرابعة (4/4)
      expect(container.read(pomodoroProvider).currentCycle, 4);
      expect(container.read(pomodoroProvider).phase, PomodoroPhase.work);

      // تخطي عمل الدورة الرابعة يجب أن ينقلنا إلى الراحة الطويلة (Long Break - 30 دقيقة)
      notifier.skipTraditionalPhase();
      expect(container.read(pomodoroProvider).phase, PomodoroPhase.longBreak);
      expect(container.read(pomodoroProvider).remainingSeconds, 30 * 60.0);

      // بعد الراحة الطويلة يعود للدورة 1
      notifier.skipTraditionalPhase();
      expect(container.read(pomodoroProvider).phase, PomodoroPhase.work);
      expect(container.read(pomodoroProvider).currentCycle, 1);
    });
  });
}