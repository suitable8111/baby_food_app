package com.babyfood.baby_food_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews

class BabyTrackerWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    companion object {
        private const val PREFS_NAME = "HomeWidgetPreferences"

        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int) {
            val prefs: SharedPreferences =
                context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            val feedingCount = prefs.getInt("feedingCount", 0)
            val feedingMl    = prefs.getInt("feedingMl", 0)
            val diaperCount  = prefs.getInt("diaperCount", 0)
            val playMinutes  = prefs.getInt("playMinutes", 0)
            val babyName     = prefs.getString("babyName", "우리아이") ?: "우리아이"
            val lastUpdate   = prefs.getString("lastUpdate", "--:--") ?: "--:--"

            val views = RemoteViews(context.packageName, R.layout.baby_tracker_widget)

            views.setTextViewText(R.id.tv_baby_name, "♥ $babyName 오늘의 기록")
            views.setTextViewText(R.id.tv_last_update, "⏱ $lastUpdate")
            views.setTextViewText(R.id.tv_feeding_count, "${feedingCount}회")
            views.setTextViewText(
                R.id.tv_feeding_ml,
                if (feedingMl > 0) "${feedingMl}ml" else ""
            )
            views.setTextViewText(R.id.tv_diaper_count, "${diaperCount}회")
            views.setTextViewText(R.id.tv_play_minutes, "${playMinutes}분")

            // 위젯 탭 → 이유식 기록 화면으로 이동
            val intent = Intent(context, MainActivity::class.java).apply {
                data = Uri.parse("babyfood://diary")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
