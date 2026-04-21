package com.dltrs.dltrs

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

data class TaskAlarm(
    val id: Int,
    val title: String,
    val body: String,
    val triggerAtMillis: Long,
    val priority: String,
)

object TaskAlarmStore {
    private const val PREFS = "dltrs_task_alarms"
    private const val KEY_ALARMS = "alarms"

    fun save(context: Context, alarm: TaskAlarm) {
        val alarms = getAll(context).filterNot { it.id == alarm.id }.toMutableList()
        alarms.add(alarm)
        persist(context, alarms)
    }

    fun remove(context: Context, id: Int) {
        persist(context, getAll(context).filterNot { it.id == id })
    }

    fun getAll(context: Context): List<TaskAlarm> {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_ALARMS, "[]")

        val result = mutableListOf<TaskAlarm>()
        val array = JSONArray(raw)
        for (index in 0 until array.length()) {
            val item = array.getJSONObject(index)
            result.add(
                TaskAlarm(
                    id = item.getInt("id"),
                    title = item.getString("title"),
                    body = item.getString("body"),
                    triggerAtMillis = item.getLong("triggerAtMillis"),
                    priority = item.getString("priority"),
                ),
            )
        }
        return result
    }

    private fun persist(context: Context, alarms: List<TaskAlarm>) {
        val array = JSONArray()
        alarms.forEach { alarm ->
            array.put(
                JSONObject()
                    .put("id", alarm.id)
                    .put("title", alarm.title)
                    .put("body", alarm.body)
                    .put("triggerAtMillis", alarm.triggerAtMillis)
                    .put("priority", alarm.priority),
            )
        }

        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_ALARMS, array.toString())
            .apply()
    }
}
