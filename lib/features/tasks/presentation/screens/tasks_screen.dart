import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../cubit/tasks_cubit.dart';
import '../cubit/tasks_state.dart';
import '../../domain/entities/task_entity.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterPriority = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TaskEntity> _filterTasks(List<TaskEntity> tasks, int tabIndex) {
    List<TaskEntity> filtered;
    switch (tabIndex) {
      case 0:
        filtered = tasks.where((t) => t.status == TaskStatus.pending).toList();
        break;
      case 1:
        filtered = tasks.where((t) => t.status == TaskStatus.completed).toList();
        break;
      case 2:
        filtered = tasks.where((t) => t.status == TaskStatus.canceled).toList();
        break;
      default:
        filtered = tasks;
    }

    if (_filterPriority != 'All') {
      filtered = filtered
          .where((t) => t.priorityLabel == _filterPriority)
          .toList();
    }

    filtered.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            onSelected: (v) => setState(() => _filterPriority = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'All', child: Text('All Priorities')),
              const PopupMenuItem(value: 'High', child: Text('🔴 High')),
              const PopupMenuItem(value: 'Medium', child: Text('🟡 Medium')),
              const PopupMenuItem(value: 'Low', child: Text('🟢 Low')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
            Tab(text: 'Canceled'),
          ],
        ),
      ),
      body: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          if (state.status == TasksStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: List.generate(3, (tabIndex) {
              final filtered = _filterTasks(state.tasks, tabIndex);

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tabIndex == 0
                            ? Icons.inbox_rounded
                            : tabIndex == 1
                                ? Icons.celebration_rounded
                                : Icons.delete_outline_rounded,
                        size: 64,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tabIndex == 0
                            ? 'No pending tasks'
                            : tabIndex == 1
                                ? 'No completed tasks yet'
                                : 'No canceled tasks',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final task = filtered[index];
                  return StaggeredItem(
                    index: index,
                    child: _SwipeableTaskCard(
                      task: task,
                      onComplete: () {
                        context.read<TasksCubit>().completeTask(task);
                      },
                      onDelete: () {
                        context.read<TasksCubit>().deleteTask(task.id);
                      },
                      onCancel: () {
                        context.read<TasksCubit>().cancelTask(task);
                      },
                    ),
                  );
                },
              );
            }),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/create-task');
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _SwipeableTaskCard extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  const _SwipeableTaskCard({
    required this.task,
    required this.onComplete,
    required this.onDelete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = AppColors.getPriorityColor(task.priorityLabel);
    final isCompleted = task.status == TaskStatus.completed;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(task.id),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (!isCompleted) onComplete();
          return false;
        } else {
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Task'),
              content: const Text('Are you sure you want to delete this task?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete',
                      style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          );
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) onDelete();
      },
      child: GlassCard(
        child: Row(
          children: [
            // Status dot
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? AppColors.success : priorityColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                        ),
                  ),
                  if (task.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _MetaItem(
                        icon: Icons.calendar_today,
                        label: DateFormat('MMM d, h:mm a')
                            .format(task.dateTime),
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      if (task.hasReminder)
                        const _MetaIcon(
                          icon: Icons.notifications_active_outlined,
                          color: AppColors.secondary,
                        ),
                      if (task.recurrence != TaskRecurrence.none)
                        _MetaItem(
                          icon: Icons.repeat,
                          label: task.recurrence.name,
                          color: AppColors.info,
                        ),
                      if (task.isOverdue)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'OVERDUE',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                task.priorityLabel,
                style: TextStyle(
                  color: priorityColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (task.status == TaskStatus.pending) ...[
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'cancel') {
                    onCancel();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'cancel',
                    child: Text('Cancel Task'),
                  ),
                ],
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.more_vert_rounded, size: 20),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _MetaIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _MetaIcon({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: 12, color: color);
  }
}
