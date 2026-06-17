import 'dart:convert';

class Habit {
  final int? id;
  final int userId;
  final String title;
  final String description;
  final DateTime createdAt;
  final List<DateTime> completionDates; // Only dates (midnight)
  final bool isCompleted;

  Habit({
    this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.completionDates,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'completionDates': jsonEncode(
        completionDates.map((d) => _formatDate(d)).toList(),
      ),
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    List<DateTime> dates = [];
    if (map['completionDates'] != null) {
      try {
        final List<dynamic> list = jsonDecode(map['completionDates'] as String);
        dates = list.map((item) => DateTime.parse(item as String)).toList();
      } catch (_) {
        // Fallback
      }
    }
    return Habit(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      completionDates: dates,
      isCompleted: (map['isCompleted'] as int) == 1,
    );
  }

  Habit copyWith({
    int? id,
    int? userId,
    String? title,
    String? description,
    DateTime? createdAt,
    List<DateTime>? completionDates,
    bool? isCompleted,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      completionDates: completionDates ?? this.completionDates,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Getters
  int get completedDaysCount => completionDates.length;

  double get progressPercentage {
    if (completedDaysCount >= 21) return 100.0;
    return (completedDaysCount / 21.0) * 100.0;
  }

  int get currentStreak {
    if (completionDates.isEmpty) return 0;
    
    // Normalize to date-only representation and sort descending
    final uniqueDates = completionDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // If today is completed, streak starts today.
    // If today is not completed but yesterday was, streak starts yesterday (keeps streak alive).
    // Otherwise, streak is 0 (broken).
    DateTime startRef;
    if (uniqueDates.contains(today)) {
      startRef = today;
    } else if (uniqueDates.contains(yesterday)) {
      startRef = yesterday;
    } else {
      return 0;
    }

    int streak = 0;
    DateTime currentCheck = startRef;

    while (uniqueDates.contains(currentCheck)) {
      streak++;
      currentCheck = currentCheck.subtract(const Duration(days: 1));
    }

    return streak;
  }
}
