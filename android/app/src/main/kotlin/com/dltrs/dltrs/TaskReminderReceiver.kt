package com.dltrs.dltrs

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class TaskReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(AlarmExtras.ID, 0)
        if (id == 0) return

        TaskAlarmStore.remove(context, id)

        val serviceIntent = Intent(context, AlarmForegroundService::class.java).apply {
            putExtras(intent)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }
}
