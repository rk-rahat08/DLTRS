import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/tasks/domain/entities/task_entity.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static const MethodChannel _platformChannel = MethodChannel('dltrs/platform');
  static const String _highPriorityChannelId = 'task_reminders_high_v3';
  static const String _mediumPriorityChannelId = 'task_reminders_medium_v3';
  static const String _lowPriorityChannelId = 'task_reminders_low_v3';
  static const RawResourceAndroidNotificationSound _highAlarmSound =
      RawResourceAndroidNotificationSound('alarm_sound_high');
  static const RawResourceAndroidNotificationSound _normalAlarmSound =
      RawResourceAndroidNotificationSound('alarm_sound_normal');

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Future<void>? _initFuture;

  Future<void> init() async {
    if (_initialized) return;
    if (_initFuture != null) return _initFuture;

    _initFuture = _doInit();
    return _initFuture;
  }

  Future<void> _doInit() async {
    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _createNotificationChannels();
    await _requestPermissions();
    _initialized = true;
    _initFuture = null;
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timezoneName =
          await _platformChannel.invokeMethod<String>('getLocalTimezone');
      if (timezoneName != null && timezoneName.isNotEmpty) {
        tz.setLocalLocation(tz.getLocation(timezoneName));
        return;
      }
    } catch (_) {
      // Fall back to UTC if the platform channel is unavailable.
    }

    tz.setLocalLocation(tz.UTC);
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _highPriorityChannelId,
        'High Priority Reminders',
        description: 'Urgent task reminders with alarm sound',
        importance: Importance.max,
        sound: _highAlarmSound,
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _mediumPriorityChannelId,
        'Medium Priority Reminders',
        description: 'Standard task reminders',
        importance: Importance.high,
        sound: _normalAlarmSound,
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _lowPriorityChannelId,
        'Low Priority Reminders',
        description: 'Low priority task reminders',
        importance: Importance.defaultImportance,
        sound: _normalAlarmSound,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  Future<void> _requestPermissions() async {
    final dynamic androidPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    try {
      await androidPlugin.requestNotificationsPermission();
    } catch (_) {}
  }

  Future<bool> areNotificationsEnabled() async {
    await init();

    final dynamic androidPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return true;

    try {
      final enabled = await androidPlugin.areNotificationsEnabled();
      return enabled == true;
    } catch (_) {
      return true;
    }
  }

  Future<void> openNotificationSettings() async {
    try {
      await _platformChannel.invokeMethod<bool>('openNotificationSettings');
    } catch (_) {}
  }

  Future<void> openExactAlarmSettings() async {
    try {
      await _platformChannel.invokeMethod<bool>('openExactAlarmSettings');
    } catch (_) {}
  }

  Future<void> openBatteryOptimizationSettings() async {
    try {
      await _platformChannel.invokeMethod<bool>('openBatteryOptimizationSettings');
    } catch (_) {}
  }

  Future<void> openMiuiAutostartSettings() async {
    try {
      await _platformChannel.invokeMethod<bool>('openMiuiAutostartSettings');
    } catch (_) {}
  }

  Future<bool> canScheduleExactAlarmsNative() async {
    try {
      final allowed =
          await _platformChannel.invokeMethod<bool>('canScheduleExactAlarmsNative');
      return allowed == true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final ignored =
          await _platformChannel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return ignored == true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> _scheduleNativeAndroidReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required TaskPriority priority,
  }) async {
    try {
      final scheduled = await _platformChannel.invokeMethod<bool>(
        'scheduleTaskReminder',
        {
          'id': id,
          'title': title,
          'body': body,
          'triggerAtMillis': scheduledDate.millisecondsSinceEpoch,
          'priority': priority.name,
        },
      );
      return scheduled == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _cancelNativeAndroidReminder(int id) async {
    try {
      await _platformChannel.invokeMethod<bool>(
        'cancelTaskReminder',
        {'id': id},
      );
    } catch (_) {}
  }

  void _onNotificationTap(NotificationResponse response) {
    // Placeholder for deep-linking into a task in the future.
  }

  NotificationDetails _getNotificationDetails(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            _highPriorityChannelId,
            'High Priority Reminders',
            channelDescription: 'Urgent task reminders with alarm sound',
            importance: Importance.max,
            priority: Priority.max,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            sound: _highAlarmSound,
            playSound: true,
            enableVibration: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          ),
        );
      case TaskPriority.medium:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            _mediumPriorityChannelId,
            'Medium Priority Reminders',
            channelDescription: 'Standard task reminders',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.alarm,
            sound: _normalAlarmSound,
            playSound: true,
            enableVibration: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          ),
        );
      case TaskPriority.low:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            _lowPriorityChannelId,
            'Low Priority Reminders',
            channelDescription: 'Low priority task reminders',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            sound: _normalAlarmSound,
            playSound: true,
            enableVibration: true,
          ),
        );
    }
  }

  Future<void> scheduleTaskReminder(TaskEntity task) async {
    await init();

    if (!task.hasReminder) return;

    if (task.status != TaskStatus.pending) {
      await cancelTaskReminder(task);
      return;
    }

    final requestedReminderTime = task.reminderTime ??
        task.dateTime.subtract(const Duration(minutes: 15));

    if (task.dateTime.isBefore(DateTime.now())) return;

    final now = DateTime.now();
    final reminderTime = requestedReminderTime.isBefore(now)
        ? now.add(const Duration(seconds: 5))
        : requestedReminderTime;

    final priorityLabel = task.priority == TaskPriority.high
        ? 'URGENT'
        : task.priority == TaskPriority.medium
            ? 'Reminder'
            : 'Upcoming';

    final body = task.description?.isNotEmpty == true
        ? '$priorityLabel ${task.description}'
        : '$priorityLabel Starting soon!';

    final scheduled = await _scheduleNativeAndroidReminder(
      id: task.id.hashCode.toSigned(31),
      title: 'Task Reminder: ${task.title}',
      body: body,
      scheduledDate: reminderTime,
      priority: task.priority,
    );

    if (scheduled && task.priority == TaskPriority.high && task.dateTime.isAfter(DateTime.now())) {
      await _scheduleNativeAndroidReminder(
        id: (task.id.hashCode.toSigned(31) + 1000000).toSigned(31),
        title: '${task.title} is starting now',
        body: 'This high-priority task is starting right now!',
        scheduledDate: task.dateTime,
        priority: TaskPriority.high,
      );
    }
  }

  Future<void> syncTaskReminders(List<TaskEntity> tasks) async {
    await init();

    for (final task in tasks) {
      final shouldSchedule =
          task.hasReminder &&
          task.status == TaskStatus.pending &&
          task.dateTime.isAfter(DateTime.now());

      if (shouldSchedule) {
        await scheduleTaskReminder(task);
      } else {
        await cancelTaskReminder(task);
      }
    }
  }

  Future<void> cancelTaskReminder(TaskEntity task) async {
    await _cancelNativeAndroidReminder(task.id.hashCode);
    await _cancelNativeAndroidReminder(task.id.hashCode + 1000000);
    await _flutterLocalNotificationsPlugin.cancel(id: task.id.hashCode);
    await _flutterLocalNotificationsPlugin.cancel(id: task.id.hashCode + 1000000);
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    TaskPriority priority = TaskPriority.medium,
  }) async {
    await init();

    await _flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: _getNotificationDetails(priority),
    );
  }

  Future<void> cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
