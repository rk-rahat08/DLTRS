import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/tasks_cubit.dart';
import '../cubit/tasks_state.dart';
import '../../domain/entities/task_entity.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});
  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  TaskPriority _priority = TaskPriority.medium;
  TaskRecurrence _recurrence = TaskRecurrence.none;
  bool _addCal = false;
  bool _enableReminder = true;
  int _reminderMinsBefore = 15;
  final List<int> _reminderOptions = [0, 5, 10, 15, 30, 60];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AuthCubit>().state.user;
    if (user == null) return;

    final dt = DateTime(
        _date.year, _date.month, _date.day, _time.hour, _time.minute);

    final reminderTime = _buildReminderTime(dt);

    if (reminderTime != null) {
      await _showReminderReadinessPrompts();
    }

    final task = TaskEntity.create(
      userId: user.id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isNotEmpty
          ? _descCtrl.text.trim()
          : null,
      dateTime: dt,
      priority: _priority,
      recurrence: _recurrence,
      reminderTime: reminderTime,
      assignedToCalendar: _addCal,
    );
    final created = await context.read<TasksCubit>().createTask(task);
    if (created && mounted) {
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheduledDateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    final reminderTime = _buildReminderTime(scheduledDateTime);

    return BlocListener<TasksCubit, TasksState>(
      listener: (context, state) {
        if (state.hasConflict && state.conflictMessage != null) {
          _showConflictDialog(state.conflictMessage!);
        }
        if (state.status == TasksStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Task'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                TextFormField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter a title' : null,
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Schedule section
                Text('Schedule',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _tile(
                        Icons.calendar_today_rounded,
                        DateFormat('MMM d, yyyy').format(_date),
                        () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 1)),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365)),
                          );
                          if (d != null) setState(() => _date = d);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _tile(
                        Icons.access_time_rounded,
                        _time.format(context),
                        () async {
                          final t = await showTimePicker(
                              context: context, initialTime: _time);
                          if (t != null) setState(() => _time = t);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Priority
                Text('Priority',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  children: TaskPriority.values.map((p) {
                    final sel = _priority == p;
                    final c = AppColors.getPriorityColor(
                      p == TaskPriority.low
                          ? 'Low'
                          : p == TaskPriority.medium
                              ? 'Medium'
                              : 'High',
                    );
                    final l = p == TaskPriority.low
                        ? 'Low'
                        : p == TaskPriority.medium
                            ? 'Medium'
                            : 'High';
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _priority = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: sel
                                ? c.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel
                                  ? c
                                  : (isDark
                                      ? AppColors.darkDivider
                                      : AppColors.lightDivider),
                              width: sel ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle, color: c),
                              ),
                              const SizedBox(height: 6),
                              Text(l,
                                  style: TextStyle(
                                    color: sel ? c : null,
                                    fontWeight: sel
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    fontSize: 13,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                _sectionCard(
                  title: 'Recurrence',
                  subtitle: 'Choose whether this task repeats.',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TaskRecurrence.values.map((r) {
                      final l = r == TaskRecurrence.none
                          ? 'None'
                          : r == TaskRecurrence.daily
                              ? 'Daily'
                              : 'Weekly';
                      return ChoiceChip(
                        label: Text(l),
                        selected: _recurrence == r,
                        onSelected: (_) => setState(() => _recurrence = r),
                        selectedColor: AppColors.primary.withOpacity(0.18),
                        backgroundColor: isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface,
                        side: BorderSide(
                          color: _recurrence == r
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkDivider
                                  : AppColors.lightDivider),
                        ),
                        labelStyle: TextStyle(
                          color: _recurrence == r
                              ? AppColors.primary
                              : Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: _recurrence == r
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                _sectionCard(
                  title: 'Reminder',
                  subtitle: _enableReminder
                      ? reminderTime != null
                          ? 'Will ring at ${DateFormat('MMM d, h:mm a').format(reminderTime)}'
                          : 'Reminder will trigger as soon as possible.'
                      : 'No reminder set for this task.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        title: const Text('Enable Reminder'),
                        subtitle: Text(
                          _enableReminder
                              ? _reminderMinsBefore == 0
                                  ? 'At task time'
                                  : '$_reminderMinsBefore minutes before'
                              : 'Disabled',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        value: _enableReminder,
                        onChanged: (v) => setState(() => _enableReminder = v),
                        activeTrackColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_enableReminder) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _reminderOptions.map((mins) {
                            final label = mins == 0
                                ? 'At time'
                                : mins >= 60
                                    ? '${mins ~/ 60}h'
                                    : '${mins}m';
                            return ChoiceChip(
                              label: Text(label),
                              selected: _reminderMinsBefore == mins,
                              onSelected: (_) =>
                                  setState(() => _reminderMinsBefore = mins),
                              selectedColor:
                                  AppColors.secondary.withOpacity(0.18),
                              backgroundColor: isDark
                                  ? AppColors.darkSurface
                                  : AppColors.lightSurface,
                              side: BorderSide(
                                color: _reminderMinsBefore == mins
                                    ? AppColors.secondary
                                    : (isDark
                                        ? AppColors.darkDivider
                                        : AppColors.lightDivider),
                              ),
                              labelStyle: TextStyle(
                                color: _reminderMinsBefore == mins
                                    ? AppColors.secondary
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                fontWeight: _reminderMinsBefore == mins
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          reminderTime != null && reminderTime.isBefore(DateTime.now())
                              ? 'This task is very close, so the reminder will fire immediately.'
                              : 'Reminder notifications depend on Android notification and alarm permissions.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Calendar toggle
                SwitchListTile(
                  title: const Text('Add to Calendar'),
                  value: _addCal,
                  onChanged: (v) => setState(() => _addCal = v),
                  activeTrackColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),

                // Create button
                GradientButton(
                  text: 'Create Task',
                  onPressed: _create,
                  icon: Icons.add_task_rounded,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConflictDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Scheduling Conflict'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TasksCubit>().clearConflict();
            },
            child: const Text('Change Time'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final user = context.read<AuthCubit>().state.user;
              if (user == null) return;
              final dt = DateTime(_date.year, _date.month, _date.day,
                  _time.hour, _time.minute);
              final reminderTime = _buildReminderTime(dt);
              final task = TaskEntity.create(
                userId: user.id,
                title: _titleCtrl.text.trim(),
                description: _descCtrl.text.trim().isNotEmpty
                    ? _descCtrl.text.trim()
                    : null,
                dateTime: dt,
                priority: _priority,
                recurrence: _recurrence,
                reminderTime: reminderTime,
                assignedToCalendar: _addCal,
              );
              final created = await context.read<TasksCubit>().forceCreateTask(task);
              if (created && mounted) {
                context.pop(true);
              }
            },
            child: Text('Create Anyway',
                style: TextStyle(color: AppColors.warning)),
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurface
              : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _buildReminderTime(DateTime taskDateTime) {
    if (!_enableReminder) return null;
    return taskDateTime.subtract(Duration(minutes: _reminderMinsBefore));
  }

  Future<void> _showReminderReadinessPrompts() async {
    final notificationService = NotificationService();
    final notificationsEnabled =
        await notificationService.areNotificationsEnabled();

    if (!notificationsEnabled && mounted) {
      final openSettings = await _showSettingsDialog(
        title: 'Notifications are blocked',
        body:
            'Task alarms cannot appear until notifications are enabled for DLTRS.',
        confirmText: 'Open Settings',
      );

      if (openSettings == true) {
        await notificationService.openNotificationSettings();
      }
    }

    final exactAlarmAllowed =
        await notificationService.canScheduleExactAlarmsNative();
    if (!exactAlarmAllowed && mounted) {
      final openSettings = await _showSettingsDialog(
        title: 'Exact alarms are disabled',
        body:
            'Android 12+ requires exact alarm permission for reminders to ring at the correct time.',
        confirmText: 'Allow Exact Alarms',
      );

      if (openSettings == true) {
        await notificationService.openExactAlarmSettings();
      }
    }

    final ignoringBatteryOptimizations =
        await notificationService.isIgnoringBatteryOptimizations();
    if (!ignoringBatteryOptimizations && mounted) {
      final openSettings = await _showSettingsDialog(
        title: 'Battery optimization may block alarms',
        body:
            'Disable battery optimization for DLTRS so alarms can ring while the app is closed or the phone is idle.',
        confirmText: 'Open Settings',
      );

      if (openSettings == true) {
        await notificationService.openBatteryOptimizationSettings();
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final showedMiuiHelp = prefs.getBool('showed_miui_alarm_help') ?? false;
    if (!showedMiuiHelp && mounted) {
      final openSettings = await _showSettingsDialog(
        title: 'Xiaomi / MIUI users',
        body:
            'If you use Xiaomi/MIUI, enable Auto-start for DLTRS and allow background activity for reliable alarms.',
        confirmText: 'Open Auto-start',
      );
      await prefs.setBool('showed_miui_alarm_help', true);

      if (openSettings == true) {
        await notificationService.openMiuiAutostartSettings();
      }
    }
  }

  Future<bool?> _showSettingsDialog({
    required String title,
    required String body,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not Now'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
