import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

enum TaskPriority { low, medium, high }

enum TaskRecurrence { none, daily, weekly }

enum TaskStatus { pending, completed, canceled }

class TaskEntity extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime dateTime;
  final TaskPriority priority;
  final TaskRecurrence recurrence;
  final DateTime? reminderTime;
  final TaskStatus status;
  final int consecutivePendingDays;
  final int consecutiveCompletedDays;
  final bool assignedToCalendar;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskEntity({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.dateTime,
    required this.priority,
    this.recurrence = TaskRecurrence.none,
    this.reminderTime,
    this.status = TaskStatus.pending,
    this.consecutivePendingDays = 0,
    this.consecutiveCompletedDays = 0,
    this.assignedToCalendar = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskEntity.create({
    required String userId,
    required String title,
    String? description,
    required DateTime dateTime,
    required TaskPriority priority,
    TaskRecurrence recurrence = TaskRecurrence.none,
    DateTime? reminderTime,
    bool assignedToCalendar = false,
  }) {
    final now = DateTime.now();
    return TaskEntity(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      description: description,
      dateTime: dateTime,
      priority: priority,
      recurrence: recurrence,
      reminderTime: reminderTime,
      assignedToCalendar: assignedToCalendar,
      createdAt: now,
      updatedAt: now,
    );
  }

  TaskEntity copyWith({
    String? title,
    String? description,
    DateTime? dateTime,
    TaskPriority? priority,
    TaskRecurrence? recurrence,
    DateTime? reminderTime,
    TaskStatus? status,
    int? consecutivePendingDays,
    int? consecutiveCompletedDays,
    bool? assignedToCalendar,
    DateTime? updatedAt,
  }) {
    return TaskEntity(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      priority: priority ?? this.priority,
      recurrence: recurrence ?? this.recurrence,
      reminderTime: reminderTime ?? this.reminderTime,
      status: status ?? this.status,
      consecutivePendingDays: consecutivePendingDays ?? this.consecutivePendingDays,
      consecutiveCompletedDays: consecutiveCompletedDays ?? this.consecutiveCompletedDays,
      assignedToCalendar: assignedToCalendar ?? this.assignedToCalendar,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  bool get isOverdue =>
      status == TaskStatus.pending && dateTime.isBefore(DateTime.now());

  bool get hasReminder => reminderTime != null;

  String get priorityLabel {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'date_time': dateTime.toIso8601String(),
      'priority': priority.name,
      'recurrence': recurrence.name,
      'reminder_time': reminderTime?.toIso8601String(),
      'status': status.name,
      'consecutive_pending_days': consecutivePendingDays,
      'consecutive_completed_days': consecutiveCompletedDays,
      'assigned_to_calendar': assignedToCalendar,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TaskEntity.fromMap(Map<String, dynamic> map) {
    return TaskEntity(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      dateTime: DateTime.parse(map['date_time']),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      recurrence: TaskRecurrence.values.firstWhere(
        (e) => e.name == map['recurrence'],
        orElse: () => TaskRecurrence.none,
      ),
      reminderTime: map['reminder_time'] != null
          ? DateTime.parse(map['reminder_time'])
          : null,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TaskStatus.pending,
      ),
      consecutivePendingDays: map['consecutive_pending_days'] ?? 0,
      consecutiveCompletedDays: map['consecutive_completed_days'] ?? 0,
      assignedToCalendar: map['assigned_to_calendar'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  @override
  List<Object?> get props => [id, userId, title, status, priority, dateTime];
}
