import 'package:equatable/equatable.dart';
import '../../domain/entities/task_entity.dart';

enum TasksStatus { initial, loading, loaded, error }

class TasksState extends Equatable {
  final TasksStatus status;
  final List<TaskEntity> tasks;
  final List<TaskEntity> todayTasks;
  final String? errorMessage;
  final bool hasConflict;
  final String? conflictMessage;

  const TasksState({
    this.status = TasksStatus.initial,
    this.tasks = const [],
    this.todayTasks = const [],
    this.errorMessage,
    this.hasConflict = false,
    this.conflictMessage,
  });

  int get completedCount =>
      tasks.where((t) => t.status == TaskStatus.completed).length;

  int get pendingCount =>
      tasks.where((t) => t.status == TaskStatus.pending).length;

  int get canceledCount =>
      tasks.where((t) => t.status == TaskStatus.canceled).length;

  double get productivityScore {
    if (tasks.isEmpty) return 0;
    return (completedCount / tasks.length * 100);
  }

  TasksState copyWith({
    TasksStatus? status,
    List<TaskEntity>? tasks,
    List<TaskEntity>? todayTasks,
    String? errorMessage,
    bool? hasConflict,
    String? conflictMessage,
  }) {
    return TasksState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      todayTasks: todayTasks ?? this.todayTasks,
      errorMessage: errorMessage,
      hasConflict: hasConflict ?? this.hasConflict,
      conflictMessage: conflictMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, tasks, todayTasks, errorMessage, hasConflict, conflictMessage];
}
