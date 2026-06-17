class Task {
  final int? id;
  final int userId;
  final String title;
  final String description;
  final DateTime dueDate;
  final String priority; // 'Alta', 'Media', 'Baja'
  final bool completed;

  Task({
    this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    this.completed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority,
      'completed': completed ? 1 : 0,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      dueDate: DateTime.parse(map['dueDate'] as String),
      priority: map['priority'] as String,
      completed: (map['completed'] as int) == 1,
    );
  }

  Task copyWith({
    int? id,
    int? userId,
    String? title,
    String? description,
    DateTime? dueDate,
    String? priority,
    bool? completed,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
    );
  }
}
