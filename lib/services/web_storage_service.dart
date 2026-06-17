import '../models/user.dart';
import '../models/task.dart';
import '../models/event.dart';
import '../models/habit.dart';
import 'storage_service.dart';

class WebStorageService implements StorageService {
  final List<User> _users = [];
  final List<Task> _tasks = [];
  final List<Event> _events = [];
  final List<Habit> _habits = [];

  int _userIdCounter = 1;
  int _taskIdCounter = 1;
  int _eventIdCounter = 1;
  int _habitIdCounter = 1;
  String? _sessionEmail;

  @override
  Future<void> init() async {
    // No-op for in-memory storage
  }

  @override
  Future<User?> createUser(User user) async {
    if (_users.any((u) => u.email.toLowerCase() == user.email.toLowerCase())) {
      return null; // Email already exists
    }
    final newUser = user.copyWith(id: _userIdCounter++);
    _users.add(newUser);
    return newUser;
  }

  @override
  Future<User?> getUserByEmail(String email) async {
    try {
      return _users.firstWhere((u) => u.email.toLowerCase() == email.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<User?> getUser(String email, String passwordHash) async {
    try {
      return _users.firstWhere((u) => u.email.toLowerCase() == email.toLowerCase() && u.passwordHash == passwordHash);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> updateUser(User user) async {
    final idx = _users.indexWhere((u) => u.id == user.id);
    if (idx != -1) {
      _users[idx] = user;
      return true;
    }
    return false;
  }

  @override
  Future<List<Task>> getTasks(int userId) async {
    return _tasks.where((t) => t.userId == userId).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  @override
  Future<Task> createTask(Task task) async {
    final newTask = task.copyWith(id: _taskIdCounter++);
    _tasks.add(newTask);
    return newTask;
  }

  @override
  Future<void> updateTask(Task task) async {
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      _tasks[idx] = task;
    }
  }

  @override
  Future<void> deleteTask(int taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
  }

  @override
  Future<List<Event>> getEvents(int userId) async {
    return _events.where((e) => e.userId == userId).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  @override
  Future<Event> createEvent(Event event) async {
    final newEvent = event.copyWith(id: _eventIdCounter++);
    _events.add(newEvent);
    return newEvent;
  }

  @override
  Future<void> updateEvent(Event event) async {
    final idx = _events.indexWhere((e) => e.id == event.id);
    if (idx != -1) {
      _events[idx] = event;
    }
  }

  @override
  Future<void> deleteEvent(int eventId) async {
    _events.removeWhere((e) => e.id == eventId);
  }

  @override
  Future<void> saveSession(String email) async {
    _sessionEmail = email;
  }

  @override
  Future<String?> getSession() async {
    return _sessionEmail;
  }

  @override
  Future<void> clearSession() async {
    _sessionEmail = null;
  }

  // --- HABIT OPERATIONS ---

  @override
  Future<List<Habit>> getHabits(int userId) async {
    return _habits.where((h) => h.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Habit> createHabit(Habit habit) async {
    final newHabit = habit.copyWith(id: _habitIdCounter++);
    _habits.add(newHabit);
    return newHabit;
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    final idx = _habits.indexWhere((h) => h.id == habit.id);
    if (idx != -1) {
      _habits[idx] = habit;
    }
  }

  @override
  Future<void> deleteHabit(int habitId) async {
    _habits.removeWhere((h) => h.id == habitId);
  }
}
