import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../models/user.dart';
import '../models/task.dart';
import '../models/event.dart';
import '../models/habit.dart';
import 'storage_service.dart';

class SqliteStorageService implements StorageService {
  Database? _db;

  @override
  Future<void> init() async {
    if (_db != null) return;

    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (kIsWeb) {
      path = inMemoryDatabasePath;
    } else {
      final dbFolder = await getApplicationDocumentsDirectory();
      path = join(dbFolder.path, 'agenda_personal.db');
    }

    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT UNIQUE,
            passwordHash TEXT,
            createdAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER,
            title TEXT,
            description TEXT,
            dueDate TEXT,
            priority TEXT,
            completed INTEGER,
            FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER,
            title TEXT,
            description TEXT,
            startDate TEXT,
            endDate TEXT,
            FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE users ADD COLUMN name TEXT;');
          } catch (e) {
            debugPrint('Failed to run migration: $e');
          }
        }
      },
    );

    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS session (
        id INTEGER PRIMARY KEY,
        email TEXT
      )
    ''');

    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        title TEXT,
        description TEXT,
        createdAt TEXT,
        completionDates TEXT,
        isCompleted INTEGER,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- USER OPERATIONS ---

  @override
  Future<User?> createUser(User user) async {
    final db = _db!;
    try {
      final id = await db.insert(
        'users',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
      return user.copyWith(id: id);
    } catch (e) {
      // Typically duplicate email constraint failure
      return null;
    }
  }

  @override
  Future<User?> getUserByEmail(String email) async {
    final db = _db!;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<User?> getUser(String email, String passwordHash) async {
    final db = _db!;
    final maps = await db.query(
      'users',
      where: 'email = ? AND passwordHash = ?',
      whereArgs: [email, passwordHash],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<bool> updateUser(User user) async {
    final db = _db!;
    try {
      final count = await db.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  // --- TASK OPERATIONS ---

  @override
  Future<List<Task>> getTasks(int userId) async {
    final db = _db!;
    final maps = await db.query(
      'tasks',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'dueDate ASC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  @override
  Future<Task> createTask(Task task) async {
    final db = _db!;
    final id = await db.insert('tasks', task.toMap());
    return task.copyWith(id: id);
  }

  @override
  Future<void> updateTask(Task task) async {
    final db = _db!;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  @override
  Future<void> deleteTask(int taskId) async {
    final db = _db!;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  // --- EVENT OPERATIONS ---

  @override
  Future<List<Event>> getEvents(int userId) async {
    final db = _db!;
    final maps = await db.query(
      'events',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'startDate ASC',
    );
    return maps.map((map) => Event.fromMap(map)).toList();
  }

  @override
  Future<Event> createEvent(Event event) async {
    final db = _db!;
    final id = await db.insert('events', event.toMap());
    return event.copyWith(id: id);
  }

  @override
  Future<void> updateEvent(Event event) async {
    final db = _db!;
    await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  @override
  Future<void> deleteEvent(int eventId) async {
    final db = _db!;
    await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  @override
  Future<void> saveSession(String email) async {
    final db = _db!;
    await db.transaction((txn) async {
      await txn.delete('session');
      await txn.insert('session', {'email': email});
    });
  }

  @override
  Future<String?> getSession() async {
    final db = _db!;
    final maps = await db.query('session');
    if (maps.isNotEmpty) {
      return maps.first['email'] as String?;
    }
    return null;
  }

  @override
  Future<void> clearSession() async {
    final db = _db!;
    await db.delete('session');
  }

  // --- HABIT OPERATIONS ---

  @override
  Future<List<Habit>> getHabits(int userId) async {
    final db = _db!;
    final maps = await db.query(
      'habits',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Habit.fromMap(map)).toList();
  }

  @override
  Future<Habit> createHabit(Habit habit) async {
    final db = _db!;
    final id = await db.insert('habits', habit.toMap());
    return habit.copyWith(id: id);
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    final db = _db!;
    await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  @override
  Future<void> deleteHabit(int habitId) async {
    final db = _db!;
    await db.delete(
      'habits',
      where: 'id = ?',
      whereArgs: [habitId],
    );
  }
}
