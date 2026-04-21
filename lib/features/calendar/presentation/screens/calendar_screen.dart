import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../tasks/presentation/cubit/tasks_cubit.dart';
import '../../../tasks/presentation/cubit/tasks_state.dart';
import '../../../tasks/domain/entities/task_entity.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _format = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<TaskEntity> _getTasksForDay(DateTime day, List<TaskEntity> allTasks) {
    return allTasks.where((t) {
      return t.dateTime.year == day.year && t.dateTime.month == day.month && t.dateTime.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar'), actions: [
        IconButton(icon: const Icon(Icons.today_rounded),
          onPressed: () => setState(() { _focusedDay = DateTime.now(); _selectedDay = DateTime.now(); })),
      ]),
      body: BlocBuilder<TasksCubit, TasksState>(builder: (context, state) {
        final selectedTasks = _getTasksForDay(_selectedDay ?? _focusedDay, state.tasks);
        return Column(children: [
          // Calendar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider)),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _format,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (sel, foc) => setState(() { _selectedDay = sel; _focusedDay = foc; }),
              onFormatChanged: (f) => setState(() => _format = f),
              onPageChanged: (f) => _focusedDay = f,
              eventLoader: (day) => _getTasksForDay(day, state.tasks),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(color: AppColors.primary.withOpacity(0.3), shape: BoxShape.circle),
                selectedDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                markerDecoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                markerSize: 6, markersMaxCount: 3,
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: AppColors.accent),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonDecoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary), borderRadius: BorderRadius.circular(8)),
                formatButtonTextStyle: TextStyle(color: AppColors.primary, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Tasks for selected day
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(DateFormat('MMMM d, yyyy').format(_selectedDay ?? _focusedDay),
                style: Theme.of(context).textTheme.titleMedium),
              Text('${selectedTasks.length} tasks', style: Theme.of(context).textTheme.bodySmall),
            ])),
          const SizedBox(height: 8),
          Expanded(child: selectedTasks.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.event_available, size: 48, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                const SizedBox(height: 8),
                Text('No tasks on this day', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: selectedTasks.length,
                itemBuilder: (_, i) {
                  final task = selectedTasks[i];
                  final pc = AppColors.getPriorityColor(task.priorityLabel);
                  return StaggeredItem(index: i, child: GlassCard(child: Row(children: [
                    Container(width: 4, height: 40, decoration: BoxDecoration(color: pc, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(task.title, style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null)),
                      const SizedBox(height: 4),
                      Text(DateFormat('h:mm a').format(task.dateTime), style: Theme.of(context).textTheme.labelSmall),
                    ])),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: pc.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                      child: Text(task.priorityLabel, style: TextStyle(color: pc, fontSize: 11, fontWeight: FontWeight.w600))),
                  ])));
                }),
          ),
        ]);
      }),
    );
  }
}
