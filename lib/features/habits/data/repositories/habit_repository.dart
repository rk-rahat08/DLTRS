import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/habit_entry.dart';

class HabitRepository {
  final SupabaseClient _supabase;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  HabitRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  String get _habitsTable => 'habits';

  Future<HabitEntry> logHabit(HabitEntry entry) async {
    final dateKey = _formatDate(entry.date);

    try {
      final existingData = await _supabase
          .from(_habitsTable)
          .select()
          .eq('user_id', entry.userId)
          .eq('type', entry.type.name)
          .eq('date', dateKey)
          .limit(1);

      if ((existingData as List).isNotEmpty) {
        final id = existingData.first['id'] as String;
        final payload = {
          'value': entry.value,
          'unit': entry.unit,
          'date': dateKey,
        };
        await _supabase.from(_habitsTable).update(payload).eq('id', id);
      } else {
        await _supabase.from(_habitsTable).insert({
          ...entry.toMap(),
          'date': dateKey,
        });
      }
      return entry;
    } on PostgrestException catch (e) {
      throw Exception(_mapTableError(e));
    }
  }

  Future<List<HabitEntry>> getTodayHabits(String userId) async {
    final today = DateTime.now();
    final dateKey = _formatDate(today);

    try {
      final data = await _supabase
          .from(_habitsTable)
          .select()
          .eq('user_id', userId)
          .eq('date', dateKey);

      return (data as List).map((d) => HabitEntry.fromMap(d)).toList();
    } on PostgrestException catch (e) {
      throw Exception(_mapTableError(e));
    }
  }

  Future<List<HabitEntry>> getHabitsForRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final data = await _supabase
          .from(_habitsTable)
          .select()
          .eq('user_id', userId)
          .gte('date', _formatDate(start))
          .lt('date', _formatDate(end))
          .order('date');

      return (data as List).map((d) => HabitEntry.fromMap(d)).toList();
    } on PostgrestException catch (e) {
      throw Exception(_mapTableError(e));
    }
  }

  Future<Map<HabitType, List<HabitEntry>>> getWeeklySummary(
    String userId,
  ) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = start.add(const Duration(days: 7));

    final entries = await getHabitsForRange(userId, start, end);

    final map = <HabitType, List<HabitEntry>>{};
    for (final type in HabitType.values) {
      map[type] = entries.where((e) => e.type == type).toList();
    }
    return map;
  }

  Future<double> getHabitCompletionScore(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 7));
    final end = endDate ?? DateTime.now().add(const Duration(days: 1));

    final entries = await getHabitsForRange(userId, start, end);

    if (entries.isEmpty) return 0.0;

    double totalCompletion = 0;
    for (final entry in entries) {
      totalCompletion += entry.completionPercentage;
    }

    final days = end.difference(start).inDays;
    final expectedEntries = HabitType.values.length * days;

    return expectedEntries > 0
        ? (totalCompletion / expectedEntries * 100).clamp(0, 100)
        : 0;
  }

  String _formatDate(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
    return _dateFormat.format(normalized);
  }

  String _mapTableError(PostgrestException error) {
    final message = error.message.toLowerCase();
    if (message.contains('relation') && message.contains('does not exist')) {
      return 'Supabase table "habits" is missing. Create the habits table before using habit tracking.';
    }
    if (message.contains('row-level security') ||
        message.contains('permission denied')) {
      return 'Supabase blocked access to "habits". Add authenticated select/insert/update/delete policies.';
    }
    return error.message;
  }
}
