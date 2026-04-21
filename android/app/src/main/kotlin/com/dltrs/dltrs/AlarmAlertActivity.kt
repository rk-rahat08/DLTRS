package com.dltrs.dltrs

import android.app.Activity
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class AlarmAlertActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        val id = intent.getIntExtra(AlarmExtras.ID, 0)
        val title = intent.getStringExtra(AlarmExtras.TITLE) ?: "Task Alarm"
        val body = intent.getStringExtra(AlarmExtras.BODY) ?: "Your task is starting now."

        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(48, 48, 48, 48)
        }

        val titleView = TextView(this).apply {
            text = title
            textSize = 28f
            gravity = Gravity.CENTER
        }

        val bodyView = TextView(this).apply {
            text = body
            textSize = 18f
            gravity = Gravity.CENTER
            setPadding(0, 24, 0, 40)
        }

        val stopButton = Button(this).apply {
            text = "Stop Alarm"
            setOnClickListener {
                AlarmForegroundService.stopAlarm(this@AlarmAlertActivity, id)
                finish()
            }
        }

        layout.addView(titleView)
        layout.addView(bodyView)
        layout.addView(stopButton)
        setContentView(layout)
    }
}
