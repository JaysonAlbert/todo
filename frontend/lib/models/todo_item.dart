import 'package:todo/models/priority.dart';

class TodoItem {
  final String id;
  final String title;
  final bool isCompleted;
  final Priority priority;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? lastModified;
  final bool isSynced;
  final String? serverId; // For mapping local todos to server todos
  final bool isDeleted; // Soft delete for sync purposes

  const TodoItem({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.priority,
    required this.createdAt,
    this.dueDate,
    this.lastModified,
    this.isSynced = false,
    this.serverId,
    this.isDeleted = false,
  });

  TodoItem copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    Priority? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? lastModified,
    bool? isSynced,
    String? serverId,
    bool? isDeleted,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      isSynced: isSynced ?? this.isSynced,
      serverId: serverId ?? this.serverId,
      isDeleted: isDeleted ?? this.isDeleted,
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
      'lastModified': lastModified?.toIso8601String(),
      'isSynced': isSynced,
      'serverId': serverId,
      'isDeleted': isDeleted,
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
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
      isSynced: json['isSynced'] as bool? ?? false,
      serverId: json['serverId'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
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
        other.createdAt == createdAt &&
        other.lastModified == lastModified &&
        other.isSynced == isSynced &&
        other.serverId == serverId &&
        other.isDeleted == isDeleted;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      isCompleted,
      priority,
      dueDate,
      createdAt,
      lastModified,
      isSynced,
      serverId,
      isDeleted,
    );
  }

  @override
  String toString() {
    return 'TodoItem('
        'id: $id, '
        'title: $title, '
        'isCompleted: $isCompleted, '
        'priority: $priority, '
        'dueDate: $dueDate, '
        'createdAt: $createdAt, '
        'lastModified: $lastModified, '
        'isSynced: $isSynced, '
        'serverId: $serverId, '
        'isDeleted: $isDeleted'
        ')';
  }

  // Sync-related convenience methods
  bool get needsSync => !isSynced && !isDeleted;
  bool get isLocal => serverId == null;
  bool get hasServerVersion => serverId != null;

  /// Create a new TodoItem with updated sync status
  TodoItem markAsSynced({String? newServerId}) {
    return copyWith(
      isSynced: true,
      serverId: newServerId ?? serverId,
      lastModified: DateTime.now(),
    );
  }

  /// Create a new TodoItem marked as needing sync
  TodoItem markAsModified() {
    return copyWith(
      isSynced: false,
      lastModified: DateTime.now(),
    );
  }

  /// Create a new TodoItem marked for deletion
  TodoItem markAsDeleted() {
    return copyWith(
      isDeleted: true,
      isSynced: false,
      lastModified: DateTime.now(),
    );
  }
}
