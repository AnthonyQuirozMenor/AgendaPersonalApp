import '../models/user.dart';
import '../models/task.dart';
import '../models/event.dart';
import '../models/habit.dart';

abstract class StorageService {
  Future<void> init();

  // User operations
  Future<User?> createUser(User user);
  Future<User?> getUserByEmail(String email);
  Future<User?> getUser(String email, String passwordHash);
  Future<bool> updateUser(User user);

  // Session operations
  Future<void> saveSession(String email);
  Future<String?> getSession();
  Future<void> clearSession();

  // Task operations
  Future<List<Task>> getTasks(int userId);
  Future<Task> createTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(int taskId);

  // Event operations
  Future<List<Event>> getEvents(int userId);
  Future<Event> createEvent(Event event);
  Future<void> updateEvent(Event event);
  Future<void> deleteEvent(int eventId);

  // Habit operations
  Future<List<Habit>> getHabits(int userId);
  Future<Habit> createHabit(Habit habit);
  Future<void> updateHabit(Habit habit);
  Future<void> deleteHabit(int habitId);
}
