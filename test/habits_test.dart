import 'package:flutter_test/flutter_test.dart';
import 'package:academic_check/models/habit.dart';
import 'package:academic_check/models/user.dart';
import 'package:academic_check/providers/app_state.dart';
import 'package:academic_check/services/web_storage_service.dart';

void main() {
  group('Habit Model Tests', () {
    test('Calcula contador de días y porcentaje correctamente', () {
      final habit = Habit(
        userId: 1,
        title: 'Beber agua',
        description: '2 litros al día',
        createdAt: DateTime.now(),
        completionDates: [
          DateTime(2026, 6, 15),
          DateTime(2026, 6, 16),
        ],
      );

      expect(habit.completedDaysCount, 2);
      expect(habit.progressPercentage, closeTo((2 / 21) * 100, 0.01));
    });

    test('Calcula la racha actual correctamente (activa hoy)', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final dayBefore = today.subtract(const Duration(days: 2));

      final habit = Habit(
        userId: 1,
        title: 'Estudiar',
        description: 'Flutter',
        createdAt: now,
        completionDates: [today, yesterday, dayBefore],
      );

      expect(habit.currentStreak, 3);
    });

    test('Calcula la racha actual correctamente (activa ayer, no hoy aún)', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final dayBefore = today.subtract(const Duration(days: 2));

      final habit = Habit(
        userId: 1,
        title: 'Estudiar',
        description: 'Flutter',
        createdAt: now,
        completionDates: [yesterday, dayBefore],
      );

      expect(habit.currentStreak, 2);
    });

    test('Calcula racha como 0 si se rompió', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dayBefore = today.subtract(const Duration(days: 2));

      final habit = Habit(
        userId: 1,
        title: 'Estudiar',
        description: 'Flutter',
        createdAt: now,
        completionDates: [dayBefore],
      );

      expect(habit.currentStreak, 0);
    });
  });

  group('AppState Habits Integration Tests', () {
    late WebStorageService storageService;
    late AppState appState;

    setUp(() async {
      storageService = WebStorageService();
      await storageService.init();
      appState = AppState(storageService: storageService);
      await appState.registerOffline('test@example.com', '123');
    });

    test('Restringe a máximo 6 hábitos activos al mismo tiempo', () async {
      // Create 6 active habits
      for (int i = 1; i <= 6; i++) {
        final res = await appState.addHabit(title: 'Habit $i', description: '');
        expect(res, isTrue);
      }
      expect(appState.habits.length, 6);

      // Attempt to create 7th active habit (should fail)
      final res7 = await appState.addHabit(title: 'Habit 7', description: '');
      expect(res7, isFalse);
      expect(appState.habits.length, 6);

      // Complete one habit
      final firstHabit = appState.habits.last;
      await appState.toggleHabitCompletedStatus(firstHabit);

      // Now active habits count is 5. Let's try creating a 7th one again. It should succeed!
      final res8 = await appState.addHabit(title: 'Habit 7', description: '');
      expect(res8, isTrue);
      expect(appState.habits.length, 7); // Total 7 habits, but 6 active (1 completed)
    });
  });
}
