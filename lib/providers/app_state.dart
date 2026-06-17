import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../config/supabase_config.dart';
import '../models/user.dart';
import '../models/task.dart';
import '../models/event.dart';
import '../models/habit.dart';
import '../services/storage_service.dart';

class AppState extends ChangeNotifier {
  final StorageService storageService;

  User? _currentUser;
  List<Task> _tasks = [];
  List<Event> _events = [];
  List<Habit> _habits = [];
  bool _isDarkMode = true; // Default to dark mode as requested

  bool _isLoading = false;
  String? _authError;

  AppState({required this.storageService});

  // Getters
  User? get currentUser => _currentUser;
  List<Task> get tasks => _tasks;
  List<Event> get events => _events;
  List<Habit> get habits => _habits;
  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;
  String? get authError => _authError;

  bool get _isSupabaseEnabled => false;

  // --- THEME ---
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // --- AUTHENTICATION ---

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  void clearAuthError() {
    _authError = null;
    notifyListeners();
  }

  Future<User> _getOrCreateLocalUser(String email) async {
    final normalizedEmail = email.toLowerCase().trim();
    var localUser = await storageService.getUserByEmail(normalizedEmail);
    if (localUser == null) {
      final newUser = User(
        email: normalizedEmail,
        passwordHash: '', // Handled by Supabase Auth
        createdAt: DateTime.now(),
      );
      final created = await storageService.createUser(newUser);
      localUser = created ?? newUser;
    }
    return localUser;
  }

  Future<void> tryAutoLogin() async {
    try {
      final email = await storageService.getSession();
      if (email != null) {
        final user = await storageService.getUserByEmail(email);
        if (user != null) {
          _currentUser = user;
          await _loadUserData();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Auto-login failed: $e');
    }
  }

  Future<bool> checkEmailUnique(String email) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final normalizedEmail = email.toLowerCase().trim();
      final existingUser = await storageService.getUserByEmail(normalizedEmail);
      _isLoading = false;
      if (existingUser != null) {
        _authError = 'El correo electrónico ya está registrado.';
        notifyListeners();
        return false;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _authError = 'Error al verificar el correo electrónico.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkEmailExists(String email) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    if (_isSupabaseEnabled) {
      // Con Supabase activo, permitimos continuar para que Supabase maneje el envío del OTP
      // de recuperación si el correo existe en su base de datos global.
      _isLoading = false;
      notifyListeners();
      return true;
    }

    try {
      final normalizedEmail = email.toLowerCase().trim();
      final existingUser = await storageService.getUserByEmail(normalizedEmail);
      _isLoading = false;
      if (existingUser == null) {
        _authError = 'El correo electrónico no está registrado.';
        notifyListeners();
        return false;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _authError = 'Error al verificar el correo electrónico.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerOffline(String email, String password) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final normalizedEmail = email.toLowerCase().trim();
      final existingUser = await storageService.getUserByEmail(normalizedEmail);
      if (existingUser != null) {
        _authError = 'El correo electrónico ya está registrado.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final passwordHash = _hashPassword(password);
      final newUser = User(
        email: normalizedEmail,
        passwordHash: passwordHash,
        createdAt: DateTime.now(),
      );

      final created = await storageService.createUser(newUser);
      if (created != null) {
        _currentUser = created;
        await storageService.saveSession(normalizedEmail);
        await _loadUserData();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _authError = 'No se pudo crear el usuario local.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _authError = 'Ocurrió un error inesperado durante el registro.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtpWithSupabase(String email, String token, OtpType type) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    if (!_isSupabaseEnabled) {
      _authError = 'Las credenciales de Supabase no están configuradas en supabase_config.dart.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final res = await Supabase.instance.client.auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: type,
      );

      if (res.session != null) {
        _currentUser = await _getOrCreateLocalUser(email);
        await _loadUserData();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _authError = 'No se pudo verificar el código.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      _authError = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _authError = 'Ocurrió un error al verificar el código.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithSupabase(String email, String password) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    if (!_isSupabaseEnabled) {
      // Offline fallback: authenticate using local SQLite database
      try {
        final normalizedEmail = email.toLowerCase().trim();
        final passwordHash = _hashPassword(password);
        var user = await storageService.getUser(normalizedEmail, passwordHash);

        // For convenience in offline testing, if database is empty, create a default demo user
        if (user == null && normalizedEmail == 'demo@example.com') {
          final newUser = User(
            email: normalizedEmail,
            passwordHash: passwordHash,
            createdAt: DateTime.now(),
          );
          await storageService.createUser(newUser);
          user = await storageService.getUser(normalizedEmail, passwordHash);
        }

        if (user == null) {
          _authError = 'Correo electrónico o contraseña incorrectos.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _currentUser = user;
        await storageService.saveSession(normalizedEmail);
        await _loadUserData();
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e) {
        _authError = 'Error en inicio de sesión local.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }

    try {
      final normalizedEmail = email.toLowerCase().trim();
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );

      if (res.session != null) {
        _currentUser = await _getOrCreateLocalUser(normalizedEmail);
        await _loadUserData();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _authError = 'Credenciales inválidas.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      _authError = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _authError = 'Ocurrió un error inesperado al iniciar sesión.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordResetOtp(String email) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    if (!_isSupabaseEnabled) {
      _authError = 'Las credenciales de Supabase no están configuradas en supabase_config.dart.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email.trim());
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _authError = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _authError = 'Ocurrió un error al enviar el código de restablecimiento.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSupabasePassword(String newPassword) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    if (!_isSupabaseEnabled) {
      // Offline fallback: Update password in SQLite
      if (_currentUser != null) {
        final passwordHash = _hashPassword(newPassword);
        final updatedUser = _currentUser!.copyWith(passwordHash: passwordHash);
        final success = await storageService.updateUser(updatedUser);
        if (success) {
          _currentUser = updatedUser;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _authError = 'No se pudo actualizar la contraseña local.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _authError = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _authError = 'Ocurrió un error al restablecer la contraseña.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _tasks = [];
    _events = [];
    _habits = [];
    await storageService.clearSession();
    if (_isSupabaseEnabled) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (e) {
        debugPrint('Error in Supabase logout: $e');
      }
    }
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) return;
    final userId = _currentUser!.id!;
    _tasks = await storageService.getTasks(userId);
    _events = await storageService.getEvents(userId);
    _habits = await storageService.getHabits(userId);
  }

  // --- TASKS CRUD ---

  Future<void> loadTasks() async {
    if (_currentUser == null) return;
    _tasks = await storageService.getTasks(_currentUser!.id!);
    notifyListeners();
  }

  Future<void> addTask({
    required String title,
    required String description,
    required DateTime dueDate,
    required String priority,
  }) async {
    if (_currentUser == null) return;
    final task = Task(
      userId: _currentUser!.id!,
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
    );
    await storageService.createTask(task);
    await loadTasks();
  }

  Future<void> toggleTaskCompleted(Task task) async {
    final updated = task.copyWith(completed: !task.completed);
    await storageService.updateTask(updated);
    await loadTasks();
  }

  Future<void> updateTask(Task task) async {
    await storageService.updateTask(task);
    await loadTasks();
  }

  Future<void> deleteTask(int taskId) async {
    await storageService.deleteTask(taskId);
    await loadTasks();
  }

  // --- EVENTS CRUD ---

  Future<void> loadEvents() async {
    if (_currentUser == null) return;
    _events = await storageService.getEvents(_currentUser!.id!);
    notifyListeners();
  }

  Future<void> addEvent({
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (_currentUser == null) return;
    final event = Event(
      userId: _currentUser!.id!,
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
    );
    await storageService.createEvent(event);
    await loadEvents();
  }

  Future<void> updateEvent(Event event) async {
    await storageService.updateEvent(event);
    await loadEvents();
  }

  Future<void> deleteEvent(int eventId) async {
    await storageService.deleteEvent(eventId);
    await loadEvents();
  }

  // --- HABITS CRUD ---

  Future<void> loadHabits() async {
    if (_currentUser == null) return;
    _habits = await storageService.getHabits(_currentUser!.id!);
    notifyListeners();
  }

  Future<bool> addHabit({
    required String title,
    required String description,
  }) async {
    if (_currentUser == null) return false;
    
    // Check constraint: max 6 active habits
    final activeCount = _habits.where((h) => !h.isCompleted).length;
    if (activeCount >= 6) {
      return false;
    }

    final habit = Habit(
      userId: _currentUser!.id!,
      title: title,
      description: description,
      createdAt: DateTime.now(),
      completionDates: [],
    );

    await storageService.createHabit(habit);
    await loadHabits();
    return true;
  }

  Future<void> updateHabit(Habit habit) async {
    await storageService.updateHabit(habit);
    await loadHabits();
  }

  Future<void> deleteHabit(int habitId) async {
    await storageService.deleteHabit(habitId);
    await loadHabits();
  }

  Future<void> toggleHabitCompletedStatus(Habit habit) async {
    final updated = habit.copyWith(isCompleted: !habit.isCompleted);
    await storageService.updateHabit(updated);
    await loadHabits();
  }

  Future<bool> toggleHabitCompletionDate(Habit habit, DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final updatedDates = List<DateTime>.from(habit.completionDates);

    if (updatedDates.any((d) => d.year == dateOnly.year && d.month == dateOnly.month && d.day == dateOnly.day)) {
      updatedDates.removeWhere((d) => d.year == dateOnly.year && d.month == dateOnly.month && d.day == dateOnly.day);
    } else {
      updatedDates.add(dateOnly);
    }

    final updatedHabit = habit.copyWith(completionDates: updatedDates);
    final prevStreak = habit.currentStreak;
    final newStreak = updatedHabit.currentStreak;
    
    bool streakCompleted = (newStreak == 21 && prevStreak < 21);
    final finalHabit = updatedHabit.copyWith(
      isCompleted: streakCompleted ? true : updatedHabit.isCompleted,
    );

    await storageService.updateHabit(finalHabit);
    await loadHabits();

    return streakCompleted;
  }
}
