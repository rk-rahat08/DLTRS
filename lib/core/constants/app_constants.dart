class AppConstants {
  AppConstants._();

  static const String appName = 'DLTRS';
  static const String appTagline = 'Your Daily Life, Organized';

  // Task auto-cancel threshold
  static const int autoCancelDays = 3;
  // Habit streak reminder threshold
  static const int habitStreakReminderDays = 3;

  // Productivity weights
  static const double onTimeWeight = 1.0;
  static const double delayedWeight = 0.5;
  static const double canceledWeight = 0.0;

  // Focus mode defaults
  static const int defaultFocusDuration = 25; // minutes (Pomodoro)
  static const int defaultBreakDuration = 5;

  // Habit types
  static const List<String> habitTypes = [
    'Water Intake',
    'Exercise',
    'Sleep Hours',
    'Study Hours',
  ];

  // Priority levels
  static const List<String> priorityLevels = ['Low', 'Medium', 'High'];

  // Recurrence options
  static const List<String> recurrenceOptions = [
    'None',
    'Daily',
    'Weekly',
  ];
}
