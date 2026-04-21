package com.dltrs.dltrs

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

class AlarmForegroundService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopAlarm(intent.getIntExtra(AlarmExtras.ID, 0))
            return START_NOT_STICKY
        }

        val id = intent?.getIntExtra(AlarmExtras.ID, 0) ?: 0
        val title = intent?.getStringExtra(AlarmExtras.TITLE) ?: "Task Reminder"
        val body = intent?.getStringExtra(AlarmExtras.BODY) ?: "Your task is starting now."
        val priority = intent?.getStringExtra(AlarmExtras.PRIORITY) ?: PRIORITY_MEDIUM

        createChannels(this)
        acquireWakeLock()
        val notification = buildNotification(id, title, body, priority)
        startForeground(id, notification)
        try {
            ring(priority)
        } catch (_: Exception) {
            // Keep the foreground service alive even if media playback fails.
        }

        if (priority == PRIORITY_HIGH) {
            startActivity(
                Intent(this, AlarmAlertActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    putExtra(AlarmExtras.ID, id)
                    putExtra(AlarmExtras.TITLE, title)
                    putExtra(AlarmExtras.BODY, body)
                    putExtra(AlarmExtras.PRIORITY, priority)
                },
            )
        }

        return START_STICKY
    }

    override fun onDestroy() {
        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
        if (wakeLock?.isHeld == true) wakeLock?.release()
        wakeLock = null
        super.onDestroy()
    }

    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) return
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "DLTRS:TaskAlarmWakeLock",
        ).apply {
            acquire(10 * 60 * 1000L)
        }
    }

    private fun buildNotification(
        id: Int,
        title: String,
        body: String,
        priority: String,
    ): android.app.Notification {
        val fullScreenIntent = PendingIntent.getActivity(
            this,
            id + 3000000,
            Intent(this, AlarmAlertActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra(AlarmExtras.ID, id)
                putExtra(AlarmExtras.TITLE, title)
                putExtra(AlarmExtras.BODY, body)
                putExtra(AlarmExtras.PRIORITY, priority)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val stopIntent = PendingIntent.getBroadcast(
            this,
            id + 4000000,
            Intent(this, AlarmActionReceiver::class.java).apply {
                action = AlarmActionReceiver.ACTION_STOP_ALARM
                putExtra(AlarmExtras.ID, id)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        return NotificationCompat.Builder(this, channelIdFor(priority))
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setOngoing(priority == PRIORITY_HIGH)
            .setAutoCancel(priority != PRIORITY_HIGH)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setFullScreenIntent(fullScreenIntent, priority == PRIORITY_HIGH)
            .addAction(0, "Stop", stopIntent)
            .build()
    }

    private fun ring(priority: String) {
        val soundName = if (priority == PRIORITY_HIGH) "alarm_sound_high" else "alarm_sound_normal"
        val soundUri = rawSoundUri(this, soundName)
        mediaPlayer?.release()
        mediaPlayer = MediaPlayer().apply {
            setDataSource(this@AlarmForegroundService, soundUri)
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build(),
            )
            isLooping = priority == PRIORITY_HIGH
            prepare()
            start()
        }
        vibrate()
    }

    private fun vibrate() {
        val pattern = longArrayOf(0, 800, 400, 800)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            manager.defaultVibrator.vibrate(VibrationEffect.createWaveform(pattern, 0))
        } else {
            @Suppress("DEPRECATION")
            val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(VibrationEffect.createWaveform(pattern, 0))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(pattern, 0)
            }
        }
    }

    private fun stopAlarm(id: Int) {
        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
        if (wakeLock?.isHeld == true) wakeLock?.release()
        wakeLock = null
        NotificationManagerCompat.from(this).cancel(id)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    companion object {
        const val PRIORITY_HIGH = "high"
        const val PRIORITY_MEDIUM = "medium"
        private const val ACTION_STOP = "com.dltrs.dltrs.ACTION_STOP_ALARM"
        private const val CHANNEL_HIGH = "native_alarm_high_v2"
        private const val CHANNEL_NORMAL = "native_alarm_normal_v2"

        fun stopAlarm(context: Context, id: Int) {
            context.stopService(Intent(context, AlarmForegroundService::class.java))
            NotificationManagerCompat.from(context).cancel(id)
        }

        fun createChannels(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

            val alarmAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()

            val highChannel = NotificationChannel(
                CHANNEL_HIGH,
                "High Priority Alarms",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Full-screen high-priority task alarms"
                enableVibration(true)
                setSound(rawSoundUri(context, "alarm_sound_high"), alarmAttributes)
            }

            val normalChannel = NotificationChannel(
                CHANNEL_NORMAL,
                "Task Reminder Alarms",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Task reminder alarms"
                enableVibration(true)
                setSound(rawSoundUri(context, "alarm_sound_normal"), alarmAttributes)
            }

            val manager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(highChannel)
            manager.createNotificationChannel(normalChannel)
        }

        fun channelIdFor(priority: String): String {
            return if (priority == PRIORITY_HIGH) CHANNEL_HIGH else CHANNEL_NORMAL
        }

        fun rawSoundUri(context: Context, resourceName: String): Uri {
            return Uri.parse("android.resource://${context.packageName}/raw/$resourceName")
        }
    }
}
