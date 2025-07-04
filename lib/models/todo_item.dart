import 'package:todo/models/priority.dart';

class TodoItem {
  final String id;
  final String title;
  final bool isCompleted;
  final Priority priority;
  final DateTime? dueDate;
  final DateTime createdAt;

  const TodoItem({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.priority,
    required this.createdAt,
    this.dueDate,
  });

  TodoItem copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    Priority? priority,
    DateTime? dueDate,
    DateTime? createdAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: dueDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'priority': priority.name,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
    };
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    Priority priority;
    final priorityString = json['priority'] as String;

    try {
      priority = Priority.values.firstWhere((p) => p.name == priorityString);
    } catch (e) {
      throw ArgumentError('Invalid priority: $priorityString');
    }

    return TodoItem(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool,
      priority: priority,
      createdAt: DateTime.parse(json['createdAt'] as String),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
    );
  }

  bool get isOverdue {
    if (isCompleted || dueDate == null) {
      return false;
    }
    return DateTime.now().isAfter(dueDate!);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TodoItem &&
        other.id == id &&
        other.title == title &&
        other.isCompleted == isCompleted &&
        other.priority == priority &&
        other.dueDate == dueDate &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, isCompleted, priority, dueDate, createdAt);
  }

  @override
  String toString() {
    return 'TodoItem('
        'id: $id, '
        'title: $title, '
        'isCompleted: $isCompleted, '
        'priority: $priority, '
        'dueDate: $dueDate, '
        'createdAt: $createdAt'
        ')';
  }
}
