import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/task_entity.dart';

class TaskRepository {
  final SupabaseClient _supabase;

  TaskRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  String get _tasksTable => 'tasks';

  Future<TaskEntity> createTask(TaskEntity task) async {
    try {
      await _supabase.from(_tasksTable).insert(task.toMap());
      return task;
    } on PostgrestException catch (e) {
      throw Exception(_mapTableError(e));
    }
  }

  Future<TaskEntity> updateTask(TaskEntity task) async {
    final updated = task.copyWith(updatedAt: DateTime.now());
    try {
      await _supabase
          .from(_tasksTable)
          .update(updated.toMap())
          .eq('id', task.id);
      return updated;
    } on PostgrestException catch (e) {
      throw Exception(_mapTableError(e));
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _supabase.from(_tasksTable).delete().eq('id', taskId);
    } on PostgrestException catch (e) {
      throw Exception(_mapTableError(e));
    }
  }

  Stream<List<TaskEntity>> getTasksStream(String userId) {
    return _supabase
        .from(_tasksTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('date_time', ascending: true)
        .map((data) => data.map((map) => TaskEntity.fromMap(map)).toList());
  }

  Future<List<TaskEntity>> getTasksForDate(String userId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    try {
      final data = await _supabase
          .from(_tasksTable)
          .select()
          .eq('user_id', userId)
          .gte('date_time', start.toIso8601String())
          .lt('date_time', end.toIso8601String())
          .order('date_time');

      return (data as List).map((map) => TaskEntity.fromMap(map)).toList();
    } on PostgrestException catch (e) {
      throw Exception(_mapTableError(e));
    }
  }

  Future<List<TaskEntity>> getTasksForRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final data = await _supabase
          .from(_tasksTable)
          .select()
          .eq('user_id', userId)
          .gte('date_time', start.toIso8601String())
          .lt('date_time', end.toIso8601String())
          .order('date_time');

      return (data as List).map((map) => TaskEntity.fromMap(map)).toList();
    } on PostgrestException catch (e) {
      throw Exception(_mapTableError(e));
    }
  }

  Future<bool> hasTimeConflict(
    String userId,
    DateTime dateTime, {
    String? excludeTaskId,
  }) async {
    final buffer = const Duration(minutes: 30);
    final start = dateTime.subtract(buffer);
    final end = dateTime.add(buffer);

    try {
      final data = await _supabase
          .from(_tasksTable)
          .select()
          .eq('user_id', userId)
          .gte('date_time', start.toIso8601String())
          .lt('date_time', end.toIso8601String())
          .eq('status', TaskStatus.pending.name);

      final tasks = (data as List)
          .map((map) => TaskEntity.fromMap(map))
          .where((t) => t.id != excludeTaskId)
          .toList();

      return tasks.isNotEmpty;
    } on PostgrestException catch (e) {
      throw Exception(_mapTableError(e));
    }
  }

  Future<TaskEntity> completeTask(TaskEntity task) async {
    final updated = task.copyWith(
      status: TaskStatus.completed,
      consecutiveCompletedDays: task.consecutiveCompletedDays + 1,
      consecutivePendingDays: 0,
    );
    try {
      await _supabase
          .from(_tasksTable)
          .update(updated.toMap())
          .eq('id', task.id);
      return updated;
    } on PostgrestException catch (e) {
      throw Exception(_mapTableError(e));
    }
  }

  Future<TaskEntity> cancelTask(TaskEntity task) async {
    final updated = task.copyWith(status: TaskStatus.canceled);
    try {
      await _supabase
          .from(_tasksTable)
          .update(updated.toMap())
          .eq('id', task.id);
      return updated;
    } on PostgrestException catch (e) {
      throw Exception(_mapTableError(e));
    }
  }

  Future<Map<String, int>> getProductivityStats(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase.from(_tasksTable).select().eq('user_id', userId);

      if (startDate != null) {
        query = query.gte('date_time', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lt('date_time', endDate.toIso8601String());
      }

      final data = await query;
      final tasks = (data as List).map((t) => TaskEntity.fromMap(t)).toList();

      return {
        'total': tasks.length,
        'completed':
            tasks.where((t) => t.status == TaskStatus.completed).length,
        'pending': tasks.where((t) => t.status == TaskStatus.pending).length,
        'canceled': tasks.where((t) => t.status == TaskStatus.canceled).length,
      };
    } on PostgrestException catch (e) {
      throw Exception(_mapTableError(e));
    }
  }

  String _mapTableError(PostgrestException error) {
    final message = error.message.toLowerCase();
    if (message.contains('relation') && message.contains('does not exist')) {
      return 'Supabase table "tasks" is missing. Create the tasks table before using task features.';
    }
    if (message.contains('row-level security') ||
        message.contains('permission denied')) {
      return 'Supabase blocked access to "tasks". Add authenticated select/insert/update/delete policies.';
    }
    return error.message;
  }
}
