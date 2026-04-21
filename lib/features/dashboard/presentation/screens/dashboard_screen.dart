import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../app/theme/theme_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../tasks/presentation/cubit/tasks_cubit.dart';
import '../../../tasks/presentation/cubit/tasks_state.dart';
import '../../../tasks/domain/entities/task_entity.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load tasks immediately using current user
    _loadData();
  }

  void _loadData() {
    final user = context.read<AuthCubit>().state.user;
    if (user != null) {
      context.read<TasksCubit>().loadTasks(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        // Reload tasks when auth state changes (user data refreshed)
        if (state.status == AuthStatus.authenticated && state.user != null) {
          final taskState = context.read<TasksCubit>().state;
          if (taskState.status == TasksStatus.initial) {
            context.read<TasksCubit>().loadTasks(state.user!.id);
          }
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, state) {
                            final name = state.user?.fullName ?? 'there';
                            final firstName = name.split(' ').first;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getGreeting(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  firstName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      // Theme toggle
                      BlocBuilder<ThemeCubit, bool>(
                        builder: (context, isDarkMode) {
                          return GestureDetector(
                            onTap: () =>
                                context.read<ThemeCubit>().toggleTheme(),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? AppColors.darkCard
                                    : AppColors.lightShimmer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isDarkMode
                                    ? Icons.light_mode_rounded
                                    : Icons.dark_mode_rounded,
                                size: 22,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      // Profile
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, state) {
                            return Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  state.user?.fullName.isNotEmpty == true
                                      ? state.user!.fullName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Date Bar ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(now),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ),

              // ── Stats Row ──
              SliverToBoxAdapter(
                child: BlocBuilder<TasksCubit, TasksState>(
                  builder: (context, state) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              index: 0,
                              icon: Icons.check_circle_outline,
                              label: 'Completed',
                              value: '${state.completedCount}',
                              color: AppColors.success,
                            ),
                          ),
                          Expanded(
                            child: _StatCard(
                              index: 1,
                              icon: Icons.pending_outlined,
                              label: 'Pending',
                              value: '${state.pendingCount}',
                              color: AppColors.warning,
                            ),
                          ),
                          Expanded(
                            child: _StatCard(
                              index: 2,
                              icon: Icons.cancel_outlined,
                              label: 'Canceled',
                              value: '${state.canceledCount}',
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Productivity Ring ──
              SliverToBoxAdapter(
                child: StaggeredItem(
                  index: 3,
                  child: GlassCard(
                    child: BlocBuilder<TasksCubit, TasksState>(
                      builder: (context, state) {
                        final score = state.productivityScore / 100;
                        return Row(
                          children: [
                            ProgressRing(
                              progress: score,
                              size: 90,
                              strokeWidth: 10,
                              color: _getScoreColor(score),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedCounter(
                                    value: state.productivityScore.toInt(),
                                    suffix: '%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                            fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Productivity Score',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _getScoreMessage(
                                        state.productivityScore),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(fontSize: 13),
                                  ),
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: () =>
                                        context.push('/productivity'),
                                    child: Row(
                                      children: [
                                        Text(
                                          'View Details',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 12,
                                          color: AppColors.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              // ── Quick Actions ──
              SliverToBoxAdapter(
                child: StaggeredItem(
                  index: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        _QuickAction(
                          icon: Icons.add_task_rounded,
                          label: 'New Task',
                          color: AppColors.primary,
                          onTap: () async {
                            await context.push('/create-task');
                            if (!context.mounted) return;
                            _loadData();
                          },
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          icon: Icons.center_focus_strong_rounded,
                          label: 'Focus',
                          color: AppColors.secondary,
                          onTap: () => context.push('/focus-mode'),
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          icon: Icons.note_add_rounded,
                          label: 'Note',
                          color: AppColors.accent,
                          onTap: () => context.push('/note-editor'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Recent Tasks Header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Tasks',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      TextButton(
                        onPressed: () => context.go('/tasks'),
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Task List ──
              BlocBuilder<TasksCubit, TasksState>(
                builder: (context, state) {
                  if (state.status == TasksStatus.loading) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  final activeTasks = state.tasks
                      .where((task) => task.status == TaskStatus.pending)
                      .toList();

                  if (activeTasks.isEmpty) {
                    return SliverToBoxAdapter(
                      child: GlassCard(
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            Icon(
                              Icons.task_alt_rounded,
                              size: 48,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No tasks yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () async {
                                await context.push('/create-task');
                                if (!context.mounted) return;
                                _loadData();
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Task'),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = activeTasks[index];
                        return StaggeredItem(
                          index: index + 5,
                          child: _TaskCard(
                            task: task,
                            onComplete: () {
                              context
                                  .read<TasksCubit>()
                                  .completeTask(task);
                            },
                            onDelete: () {
                              context
                                  .read<TasksCubit>()
                                  .deleteTask(task.id);
                            },
                          ),
                        );
                      },
                      childCount: activeTasks.length.clamp(0, 5),
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await context.push('/create-task');
            if (!context.mounted) return;
            _loadData();
          },
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning 🌅';
    if (hour >= 12 && hour < 17) return 'Good Afternoon ☀️';
    if (hour >= 17 && hour < 21) return 'Good Evening 🌆';
    return 'Good Night 🌙';
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return AppColors.success;
    if (score >= 0.5) return AppColors.warning;
    return AppColors.error;
  }

  String _getScoreMessage(double score) {
    if (score >= 80) return "Outstanding! You're crushing it today! 🎉";
    if (score >= 60) return "Good progress! Keep the momentum going! 💪";
    if (score >= 40) return "You're getting there! Stay focused! 🎯";
    if (score > 0) return "Let's pick up the pace! You've got this! 🚀";
    return "Start your day by completing a task! ✨";
  }
}

class _StatCard extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.index,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return StaggeredItem(
      index: index,
      child: GlassCard(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _TaskCard(
      {required this.task,
      required this.onComplete,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final priorityColor = AppColors.getPriorityColor(task.priorityLabel);
    final isCompleted = task.status == TaskStatus.completed;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key('dashboard_task_${task.id}'),
      direction: isCompleted
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
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
      confirmDismiss: (_) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Task'),
            content:
                const Text('Are you sure you want to delete this task?'),
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
      },
      onDismissed: (_) => onDelete(),
      child: GlassCard(
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: isCompleted ? null : onComplete,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AppColors.success
                      : Colors.transparent,
                  border: Border.all(
                    color:
                        isCompleted ? AppColors.success : priorityColor,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: isCompleted
                              ? (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary)
                              : null,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14,
                          color: AppColors.lightTextSecondary),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('h:mm a').format(task.dateTime),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
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
                    ],
                  ),
                ],
              ),
            ),

            // Priority indicator
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
