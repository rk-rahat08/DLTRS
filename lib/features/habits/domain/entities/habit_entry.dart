import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

enum HabitType { waterIntake, exercise, sleepHours, studyHours }

class HabitEntry extends Equatable {
  final String id;
  final String userId;
  final HabitType type;
  final double value;
  final String unit;
  final DateTime date;
  final DateTime createdAt;

  const HabitEntry({
    required this.id,
    required this.userId,
    required this.type,
    required this.value,
    required this.unit,
    required this.date,
    required this.createdAt,
  });

  factory HabitEntry.create({
    required String userId,
    required HabitType type,
    required double value,
    required DateTime date,
  }) {
    return HabitEntry(
      id: const Uuid().v4(),
      userId: userId,
      type: type,
      value: value,
      unit: _getUnit(type),
      date: DateTime(date.year, date.month, date.day),
      createdAt: DateTime.now(),
    );
  }

  static String _getUnit(HabitType type) {
    switch (type) {
      case HabitType.waterIntake:
        return 'glasses';
      case HabitType.exercise:
        return 'minutes';
      case HabitType.sleepHours:
        return 'hours';
      case HabitType.studyHours:
        return 'hours';
    }
  }

  static double getTarget(HabitType type) {
    switch (type) {
      case HabitType.waterIntake:
        return 8;
      case HabitType.exercise:
        return 30;
      case HabitType.sleepHours:
        return 8;
      case HabitType.studyHours:
        return 4;
    }
  }

  static String getLabel(HabitType type) {
    switch (type) {
      case HabitType.waterIntake:
        return 'Water Intake';
      case HabitType.exercise:
        return 'Exercise';
      case HabitType.sleepHours:
        return 'Sleep Hours';
      case HabitType.studyHours:
        return 'Study Hours';
    }
  }

  static String getIcon(HabitType type) {
    switch (type) {
      case HabitType.waterIntake:
        return '💧';
      case HabitType.exercise:
        return '🏃';
      case HabitType.sleepHours:
        return '😴';
      case HabitType.studyHours:
        return '📚';
    }
  }

  double get completionPercentage {
    final target = getTarget(type);
    return (value / target).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'value': value,
      'unit': unit,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HabitEntry.fromMap(Map<String, dynamic> map) {
    return HabitEntry(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      type: HabitType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => HabitType.waterIntake,
      ),
      value: (map['value'] ?? 0).toDouble(),
      unit: map['unit'] ?? '',
      date: DateTime.parse(map['date']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  @override
  List<Object?> get props => [id, userId, type, value, date];
}
