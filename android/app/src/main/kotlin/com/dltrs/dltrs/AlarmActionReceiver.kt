package com.dltrs.dltrs

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_STOP_ALARM) {
            val id = intent.getIntExtra(AlarmExtras.ID, 0)
            if (id != 0) {
                AlarmForegroundService.stopAlarm(context, id)
            }
        }
    }

    companion object {
        const val ACTION_STOP_ALARM = "com.dltrs.dltrs.ACTION_STOP_ALARM"
    }
}
