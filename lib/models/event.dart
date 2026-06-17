class Event {
  final int? id;
  final int userId;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;

  Event({
    this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
    );
  }

  Event copyWith({
    int? id,
    int? userId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Event(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
