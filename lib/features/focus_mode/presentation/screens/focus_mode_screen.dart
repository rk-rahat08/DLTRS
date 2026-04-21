import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/services/notification_service.dart';
import '../../../tasks/domain/entities/task_entity.dart';

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({super.key});
  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen>
    with WidgetsBindingObserver {
  int _selectedMin = 25;
  int _remaining = 0; // seconds
  bool _running = false;
  bool _finished = false;
  Timer? _timer;
  int _sessionsCompleted = 0;
  int _totalFocusedSec = 0;
  int _focusBrokenCount = 0;
  int _dailyFocusMinutes = 0;
  int _dailyGoalMinutes = 120; // Default 2-hour daily goal

  final _options = [15, 25, 45, 60];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    setState(() {
      _sessionsCompleted = prefs.getInt('focus_sessions_$today') ?? 0;
      _totalFocusedSec = prefs.getInt('focus_total_sec_$today') ?? 0;
      _dailyFocusMinutes = _totalFocusedSec ~/ 60;
      _focusBrokenCount = prefs.getInt('focus_broken_$today') ?? 0;
      _dailyGoalMinutes = prefs.getInt('focus_daily_goal') ?? 120;
    });
  }

  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setInt('focus_sessions_$today', _sessionsCompleted);
    await prefs.setInt('focus_total_sec_$today', _totalFocusedSec);
    await prefs.setInt('focus_broken_$today', _focusBrokenCount);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _running) {
      _timer?.cancel();
      // Track the session that was broken
      _focusBrokenCount++;
      _saveStats();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _running = false;
            _remaining = 0;
            _finished = false;
          });

          // Show notification that focus was broken
          NotificationService().showInstantNotification(
            title: '⚠️ Focus Session Broken',
            body:
                'You left the app during a focus session. Try to stay focused!',
            priority: TaskPriority.high,
          );

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              icon: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning, size: 48),
              title: const Text('Focus Broken!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'You left the app during your focus session. Your session has been canceled.',
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.broken_image_rounded,
                            color: AppColors.error),
                        const SizedBox(width: 8),
                        Text(
                          'Focus broken $_focusBrokenCount time(s) today',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _start();
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }
      });
    }
  }

  void _start() {
    setState(() {
      _remaining = _selectedMin * 60;
      _running = true;
      _finished = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 0) {
        _timer?.cancel();
        _sessionsCompleted++;
        _totalFocusedSec += _selectedMin * 60;
        _dailyFocusMinutes = _totalFocusedSec ~/ 60;
        _saveStats();

        NotificationService().showInstantNotification(
          title: '🎉 Focus Session Complete!',
          body:
              'Great job! You focused for $_selectedMin minutes. Total today: $_dailyFocusMinutes min',
          priority: TaskPriority.medium,
        );

        setState(() {
          _running = false;
          _finished = true;
        });
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _resume() {
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 0) {
        _timer?.cancel();
        _sessionsCompleted++;
        _totalFocusedSec += _selectedMin * 60;
        _dailyFocusMinutes = _totalFocusedSec ~/ 60;
        _saveStats();
        setState(() {
          _running = false;
          _finished = true;
        });
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _remaining = 0;
      _running = false;
      _finished = false;
    });
  }

  String _fmt(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = _remaining > 0
        ? 1 - (_remaining / (_selectedMin * 60))
        : (_finished ? 1.0 : 0.0);
    final goalProgress = _dailyGoalMinutes > 0
        ? (_dailyFocusMinutes / _dailyGoalMinutes).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Mode'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (_running) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Leave Focus?'),
                  content: const Text(
                      'Your focus session is still running. Leaving will cancel it.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Stay'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _reset();
                        context.pop();
                      },
                      child: const Text('Leave',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Timer ring
              ProgressRing(
                progress: progress,
                size: 220,
                strokeWidth: 14,
                color: _finished ? AppColors.success : AppColors.secondary,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_remaining > 0 || _running)
                      Text(_fmt(_remaining),
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ))
                    else if (_finished)
                      Column(children: [
                        const Icon(Icons.celebration_rounded,
                            size: 36, color: AppColors.success),
                        const SizedBox(height: 8),
                        Text('Done!',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(color: AppColors.success)),
                      ])
                    else
                      Text('${_selectedMin}:00',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              )),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Duration selector
              if (!_running && !_finished && _remaining == 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _options.map((m) {
                    final sel = _selectedMin == m;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedMin = m),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.secondary.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sel
                                ? AppColors.secondary
                                : (isDark
                                    ? AppColors.darkDivider
                                    : AppColors.lightDivider),
                            width: sel ? 2 : 1,
                          ),
                        ),
                        child: Text('${m}m',
                            style: TextStyle(
                              color: sel ? AppColors.secondary : null,
                              fontWeight:
                                  sel ? FontWeight.w700 : FontWeight.w400,
                              fontSize: 15,
                            )),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 32),

              // Controls
              if (!_running && !_finished && _remaining == 0)
                GradientButton(
                  text: 'Start Focus',
                  gradient: AppColors.secondaryGradient,
                  icon: Icons.play_arrow_rounded,
                  onPressed: _start,
                )
              else if (_running)
                GradientButton(
                  text: 'Pause',
                  gradient: AppColors.accentGradient,
                  icon: Icons.pause_rounded,
                  onPressed: _pause,
                )
              else if (!_running && _remaining > 0)
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                        onPressed: _reset, child: const Text('Reset')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientButton(
                      text: 'Resume',
                      gradient: AppColors.secondaryGradient,
                      icon: Icons.play_arrow_rounded,
                      onPressed: _resume,
                    ),
                  ),
                ])
              else if (_finished)
                GradientButton(
                  text: 'Start Another',
                  gradient: AppColors.secondaryGradient,
                  icon: Icons.replay_rounded,
                  onPressed: _reset,
                ),

              const Spacer(),

              // Daily Goal Progress
              GlassCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Daily Focus Goal',
                            style: Theme.of(context).textTheme.titleSmall),
                        Text(
                          '$_dailyFocusMinutes / $_dailyGoalMinutes min',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: goalProgress,
                        minHeight: 8,
                        backgroundColor: isDark
                            ? AppColors.darkDivider
                            : AppColors.lightDivider,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          goalProgress >= 1.0
                              ? AppColors.success
                              : AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Session stats
              GlassCard(
                margin: EdgeInsets.zero,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Sessions',
                      value: '$_sessionsCompleted',
                      icon: Icons.timer_outlined,
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: isDark
                          ? AppColors.darkDivider
                          : AppColors.lightDivider,
                    ),
                    _StatItem(
                      label: 'Total',
                      value: '${_totalFocusedSec ~/ 60}m',
                      icon: Icons.hourglass_bottom_rounded,
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: isDark
                          ? AppColors.darkDivider
                          : AppColors.lightDivider,
                    ),
                    _StatItem(
                      label: 'Broken',
                      value: '$_focusBrokenCount',
                      icon: Icons.broken_image_outlined,
                      color: _focusBrokenCount > 0
                          ? AppColors.error
                          : AppColors.secondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.secondary;
    return Column(children: [
      Icon(icon, color: c, size: 20),
      const SizedBox(height: 4),
      Text(value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700)),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ]);
  }
}
