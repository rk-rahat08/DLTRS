package com.dltrs.dltrs

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

object TaskAlarmScheduler {
    private const val ACTION_ALARM = "com.dltrs.dltrs.ACTION_TASK_ALARM"

    fun schedule(context: Context, alarm: TaskAlarm, persist: Boolean = true): Boolean {
        if (alarm.triggerAtMillis <= System.currentTimeMillis()) return false
        if (persist) TaskAlarmStore.save(context, alarm)

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val operation = alarmIntent(context, alarm)

        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (!alarmManager.canScheduleExactAlarms()) {
                    // Fallback to inexact alarm if permission is missing
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        alarm.triggerAtMillis,
                        operation,
                    )
                    return true
                }
            }

            // If we have permission or are on older Android versions, we can use exact alarms
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    alarm.triggerAtMillis,
                    operation,
                )
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, alarm.triggerAtMillis, operation)
            }
            true
        } catch (e: SecurityException) {
            // Ultimate fallback if even the check fails or another security restriction happens
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        alarm.triggerAtMillis,
                        operation,
                    )
                } else {
                    alarmManager.set(AlarmManager.RTC_WAKEUP, alarm.triggerAtMillis, operation)
                }
            } catch (_: Exception) {
                // Return gracefully instead of crashing
            }
            false
        }
    }

    fun cancel(context: Context, id: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(emptyAlarmIntent(context, id))
        TaskAlarmStore.remove(context, id)
        AlarmForegroundService.stopAlarm(context, id)
    }

    fun restoreFutureAlarms(context: Context) {
        val now = System.currentTimeMillis()
        TaskAlarmStore.getAll(context)
            .filter { it.triggerAtMillis > now }
            .forEach { schedule(context, it, persist = false) }
    }

    private fun alarmIntent(context: Context, alarm: TaskAlarm): PendingIntent {
        return PendingIntent.getBroadcast(
            context,
            alarm.id,
            Intent(context, TaskReminderReceiver::class.java).apply {
                action = ACTION_ALARM
                putAlarmExtras(alarm)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun emptyAlarmIntent(context: Context, id: Int): PendingIntent {
        return PendingIntent.getBroadcast(
            context,
            id,
            Intent(context, TaskReminderReceiver::class.java).apply {
                action = ACTION_ALARM
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}

fun Intent.putAlarmExtras(alarm: TaskAlarm) {
    putExtra(AlarmExtras.ID, alarm.id)
    putExtra(AlarmExtras.TITLE, alarm.title)
    putExtra(AlarmExtras.BODY, alarm.body)
    putExtra(AlarmExtras.TRIGGER_AT, alarm.triggerAtMillis)
    putExtra(AlarmExtras.PRIORITY, alarm.priority)
}

object AlarmExtras {
    const val ID = "id"
    const val TITLE = "title"
    const val BODY = "body"
    const val TRIGGER_AT = "triggerAtMillis"
    const val PRIORITY = "priority"
}
