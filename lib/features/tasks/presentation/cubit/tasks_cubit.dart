import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/notification_service.dart';
import '../../data/repositories/task_repository.dart';
import '../../domain/entities/task_entity.dart';
import 'tasks_state.dart';

class TasksCubit extends Cubit<TasksState> {
  final TaskRepository _taskRepository;
  StreamSubscription<List<TaskEntity>>? _tasksSub;

  TasksCubit({required TaskRepository taskRepository})
      : _taskRepository = taskRepository,
        super(const TasksState());

  void loadTasks(String userId) {
    emit(state.copyWith(status: TasksStatus.loading));
    _tasksSub?.cancel();
    _tasksSub = _taskRepository.getTasksStream(userId).listen(
      (tasks) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));

        final todayTasks = tasks.where((t) {
          return t.dateTime.isAfter(
                today.subtract(const Duration(seconds: 1)),
              ) &&
              t.dateTime.isBefore(tomorrow);
        }).toList();

        tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        todayTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        emit(state.copyWith(
          status: TasksStatus.loaded,
          tasks: tasks,
          todayTasks: todayTasks,
        ));

        NotificationService().syncTaskReminders(tasks);
      },
      onError: (error) {
        emit(state.copyWith(
          status: TasksStatus.error,
          errorMessage: error.toString(),
        ));
      },
    );
  }

  void _emitTasks(List<TaskEntity> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final todayTasks = tasks.where((t) {
      return t.dateTime.isAfter(today.subtract(const Duration(seconds: 1))) &&
          t.dateTime.isBefore(tomorrow);
    }).toList();

    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    todayTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    emit(state.copyWith(
      status: TasksStatus.loaded,
      tasks: tasks,
      todayTasks: todayTasks,
      hasConflict: false,
      conflictMessage: null,
    ));
  }

  Future<bool> createTask(TaskEntity task) async {
    try {
      final hasConflict = await _taskRepository.hasTimeConflict(
        task.userId,
        task.dateTime,
      );

      if (hasConflict) {
        emit(state.copyWith(
          hasConflict: true,
          conflictMessage:
              'There is a scheduling conflict within 30 minutes of this time.',
        ));
        return false;
      }

      await _taskRepository.createTask(task);
      if (task.hasReminder) {
        await NotificationService().scheduleTaskReminder(task);
      }
      _emitTasks([...state.tasks, task]);
      return true;
    } catch (e) {
      emit(state.copyWith(
        status: TasksStatus.error,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  Future<bool> forceCreateTask(TaskEntity task) async {
    try {
      await _taskRepository.createTask(task);
      if (task.hasReminder) {
        await NotificationService().scheduleTaskReminder(task);
      }
      _emitTasks([...state.tasks, task]);
      return true;
    } catch (e) {
      emit(state.copyWith(
        status: TasksStatus.error,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  Future<void> updateTask(TaskEntity task) async {
    try {
      await _taskRepository.updateTask(task);
      if (task.hasReminder) {
        await NotificationService().scheduleTaskReminder(task);
      } else {
        await NotificationService().cancelTaskReminder(task);
      }
      final updatedTasks = state.tasks
          .map((existing) => existing.id == task.id ? task : existing)
          .toList();
      _emitTasks(updatedTasks);
    } catch (e) {
      emit(state.copyWith(
        status: TasksStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final task = state.tasks.firstWhere((t) => t.id == taskId);
      await NotificationService().cancelTaskReminder(task);
      await _taskRepository.deleteTask(taskId);
      final updatedTasks =
          state.tasks.where((existing) => existing.id != taskId).toList();
      _emitTasks(updatedTasks);
    } catch (e) {
      emit(state.copyWith(
        status: TasksStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> completeTask(TaskEntity task) async {
    try {
      await NotificationService().cancelTaskReminder(task);
      final updated = await _taskRepository.completeTask(task);
      final updatedTasks = state.tasks
          .map((existing) => existing.id == updated.id ? updated : existing)
          .toList();
      _emitTasks(updatedTasks);
    } catch (e) {
      emit(state.copyWith(
        status: TasksStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> cancelTask(TaskEntity task) async {
    try {
      await NotificationService().cancelTaskReminder(task);
      final updated = await _taskRepository.cancelTask(task);
      final updatedTasks = state.tasks
          .map((existing) => existing.id == updated.id ? updated : existing)
          .toList();
      _emitTasks(updatedTasks);
    } catch (e) {
      emit(state.copyWith(
        status: TasksStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void clearConflict() {
    emit(state.copyWith(hasConflict: false, conflictMessage: null));
  }

  @override
  Future<void> close() {
    _tasksSub?.cancel();
    return super.close();
  }
}
