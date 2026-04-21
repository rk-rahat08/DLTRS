import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/services/service_locator.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/repositories/habit_repository.dart';
import '../../domain/entities/habit_entry.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});
  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final _repo = getIt<HabitRepository>();
  List<HabitEntry> _todayEntries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final user = context.read<AuthCubit>().state.user;
    if (user == null) return;
    try {
      final entries = await _repo.getTodayHabits(user.id);
      setState(() { _todayEntries = entries; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  double _getValue(HabitType type) {
    final entry = _todayEntries.where((e) => e.type == type).firstOrNull;
    return entry?.value ?? 0;
  }

  Future<void> _logHabit(HabitType type, double value) async {
    final user = context.read<AuthCubit>().state.user;
    if (user == null) return;
    final entry = HabitEntry.create(
      userId: user.id,
      type: type,
      value: value,
      date: DateTime.now(),
    );
    try {
      await _repo.logHabit(entry);
      await _loadHabits();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habit Tracker')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHabits,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  // Overall score
                  StaggeredItem(index: 0, child: GlassCard(child: Row(children: [
                    ProgressRing(progress: _overallScore(), size: 70, strokeWidth: 8,
                      color: AppColors.secondary,
                      child: Text('${(_overallScore() * 100).toInt()}%',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Today's Habit Score", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('Keep up your healthy routines!', style: Theme.of(context).textTheme.bodySmall),
                    ])),
                  ]))),

                  // Habit cards
                  ...HabitType.values.asMap().entries.map((e) {
                    final i = e.key;
                    final type = e.value;
                    return StaggeredItem(index: i + 1, child: _HabitCard(
                      type: type, currentValue: _getValue(type),
                      onLog: (v) => _logHabit(type, v),
                    ));
                  }),
                ],
              ),
            ),
    );
  }

  double _overallScore() {
    if (_todayEntries.isEmpty) return 0;
    double total = 0;
    int count = 0;
    for (final type in HabitType.values) {
      final val = _getValue(type);
      if (val > 0) {
        total += (val / HabitEntry.getTarget(type)).clamp(0, 1);
        count++;
      }
    }
    return count > 0 ? total / HabitType.values.length : 0;
  }
}

class _HabitCard extends StatelessWidget {
  final HabitType type;
  final double currentValue;
  final Function(double) onLog;

  const _HabitCard({required this.type, required this.currentValue, required this.onLog});

  @override
  Widget build(BuildContext context) {
    final target = HabitEntry.getTarget(type);
    final progress = (currentValue / target).clamp(0.0, 1.0);
    final color = _getColor(type);

    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(HabitEntry.getIcon(type), style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(HabitEntry.getLabel(type), style: Theme.of(context).textTheme.titleMedium),
            Text('${currentValue.toStringAsFixed(currentValue == currentValue.toInt() ? 0 : 1)} / ${target.toInt()} ${HabitEntry.create(userId: '', type: type, value: 0, date: DateTime.now()).unit}',
              style: Theme.of(context).textTheme.bodySmall),
          ])),
          // Quick add buttons
          Row(children: [
            _QuickBtn(label: '-1', onTap: () { if (currentValue > 0) onLog(currentValue - 1); }),
            const SizedBox(width: 8),
            _QuickBtn(label: '+1', onTap: () => onLog(currentValue + 1), isPrimary: true),
          ]),
        ]),
        const SizedBox(height: 12),
        // Progress bar
        ClipRRect(borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic,
            builder: (_, val, __) => LinearProgressIndicator(
              value: val, minHeight: 8, backgroundColor: color.withOpacity(0.12), color: color),
          ),
        ),
        if (progress >= 1.0) ...[
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 16), const SizedBox(width: 4),
            Text('Goal reached!', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ],
      ]),
    );
  }

  Color _getColor(HabitType type) {
    switch (type) {
      case HabitType.waterIntake: return const Color(0xFF0EA5E9);
      case HabitType.exercise: return AppColors.success;
      case HabitType.sleepHours: return AppColors.accent;
      case HabitType.studyHours: return AppColors.warning;
    }
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  const _QuickBtn({required this.label, required this.onTap, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primary.withOpacity(0.12) : null,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isPrimary ? AppColors.primary : AppColors.lightDivider)),
      child: Text(label, style: TextStyle(color: isPrimary ? AppColors.primary : null, fontWeight: FontWeight.w600, fontSize: 13)),
    ));
  }
}
