package com.dltrs.dltrs

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    private val platformChannel = "dltrs/platform"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            platformChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getLocalTimezone" -> result.success(TimeZone.getDefault().id)
                "openNotificationSettings" -> {
                    openNotificationSettings()
                    result.success(true)
                }
                "openExactAlarmSettings" -> {
                    openExactAlarmSettings()
                    result.success(true)
                }
                "openBatteryOptimizationSettings" -> {
                    openBatteryOptimizationSettings()
                    result.success(true)
                }
                "openMiuiAutostartSettings" -> {
                    openMiuiAutostartSettings()
                    result.success(true)
                }
                "scheduleTaskReminder" -> {
                    val id = call.argument<Int>("id")
                    val title = call.argument<String>("title")
                    val body = call.argument<String>("body")
                    val triggerAtMillis = call.argument<Long>("triggerAtMillis")
                    val priority = call.argument<String>("priority")

                    if (id == null || title == null || body == null || triggerAtMillis == null || priority == null) {
                        result.success(false)
                    } else {
                        val scheduled = TaskAlarmScheduler.schedule(
                            context = applicationContext,
                            alarm = TaskAlarm(
                                id = id,
                                title = title,
                                body = body,
                                triggerAtMillis = triggerAtMillis,
                                priority = priority,
                            ),
                        )
                        result.success(scheduled)
                    }
                }
                "scheduleInstantTaskAlarm" -> {
                    val id = call.argument<Int>("id")
                    val title = call.argument<String>("title")
                    val body = call.argument<String>("body")
                    val priority = call.argument<String>("priority")

                    if (id == null || title == null || body == null || priority == null) {
                        result.success(false)
                    } else {
                        val intent = Intent(this, AlarmForegroundService::class.java).apply {
                            putExtra(AlarmExtras.ID, id)
                            putExtra(AlarmExtras.TITLE, title)
                            putExtra(AlarmExtras.BODY, body)
                            putExtra(AlarmExtras.PRIORITY, priority)
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    }
                }
                "canScheduleExactAlarmsNative" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val alarmManager = getSystemService(ALARM_SERVICE) as android.app.AlarmManager
                        result.success(alarmManager.canScheduleExactAlarms())
                    } else {
                        result.success(true)
                    }
                }
                "isIgnoringBatteryOptimizations" -> {
                    val powerManager = getSystemService(POWER_SERVICE) as PowerManager
                    result.success(powerManager.isIgnoringBatteryOptimizations(packageName))
                }
                "cancelTaskReminder" -> {
                    val id = call.argument<Int>("id")
                    if (id == null) {
                        result.success(false)
                    } else {
                        TaskAlarmScheduler.cancel(applicationContext, id)
                        result.success(true)
                    }
                }
                "debugAlarmNow" -> {
                    val id = System.currentTimeMillis().toInt()
                    val scheduled = TaskAlarmScheduler.schedule(
                        context = applicationContext,
                        alarm = TaskAlarm(
                            id = id,
                            title = "DLTRS Test Alarm",
                            body = "If you see and hear this, native alarms are working.",
                            triggerAtMillis = System.currentTimeMillis() + 5000,
                            priority = "high",
                        ),
                        persist = false,
                    )
                    result.success(scheduled)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openNotificationSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            }
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
            }
        }

        startActivity(intent)
    }

    private fun openExactAlarmSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                data = Uri.parse("package:$packageName")
            })
        }
    }

    private fun openBatteryOptimizationSettings() {
        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        if (!powerManager.isIgnoringBatteryOptimizations(packageName)) {
            startActivity(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:$packageName")
            })
        } else {
            startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
        }
    }

    private fun openMiuiAutostartSettings() {
        val intents = listOf(
            Intent().setClassName(
                "com.miui.securitycenter",
                "com.miui.permcenter.autostart.AutoStartManagementActivity",
            ),
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
            },
        )

        for (intent in intents) {
            try {
                startActivity(intent)
                return
            } catch (_: Exception) {
            }
        }
    }
}
