package com.didichou.inkroot

import android.app.PendingIntent
import android.app.AlarmManager
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject

abstract class BaseInkRootWidgetProvider : AppWidgetProvider() {
    final override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    protected abstract fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    )

    protected fun snapshot(context: Context): JSONObject? {
        val raw = context
            .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(SNAPSHOT_KEY, null)
        return try {
            if (raw.isNullOrBlank()) null else JSONObject(raw)
        } catch (e: Exception) {
            null
        }
    }

    protected fun deepLinkPendingIntent(
        context: Context,
        url: String,
        requestCode: Int
    ): PendingIntent {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
            setPackage(context.packageName)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val immutableFlag =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_IMMUTABLE
            } else {
                0
            }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag
        return PendingIntent.getActivity(context, requestCode, intent, flags)
    }

    companion object {
        const val PREFS_NAME = "inkroot_widget"
        const val SNAPSHOT_KEY = "inkroot_widget_snapshot"
    }
}

class InkRootQuickNoteWidgetProvider : BaseInkRootWidgetProvider() {
    override fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val snapshot = snapshot(context)
        val views = RemoteViews(context.packageName, R.layout.inkroot_quick_note_widget)
        val noteCount = snapshot?.optJSONObject("today")?.optInt("notes", 0) ?: 0
        val pendingTodos = snapshot?.optJSONObject("today")?.optInt("pendingTodos", 0) ?: 0
        val unsynced = snapshot?.optJSONObject("sync")?.optInt("unsyncedCount", 0) ?: 0
        val quickTags = snapshot?.optJSONArray("quickTags")

        views.setTextViewText(R.id.inkroot_widget_subtitle, "今日 $noteCount 条")
        views.setTextViewText(
            R.id.inkroot_widget_status,
            when {
                unsynced > 0 -> "$unsynced 条待同步"
                pendingTodos > 0 -> "$pendingTodos 个待办"
                else -> "静待沉淀，蓄势而鸣"
            }
        )
        views.setOnClickPendingIntent(
            R.id.inkroot_widget_quick_note,
            deepLinkPendingIntent(context, "inkroot://quick-note", 10)
        )

        val tagIds = intArrayOf(
            R.id.inkroot_widget_tag_1,
            R.id.inkroot_widget_tag_2,
            R.id.inkroot_widget_tag_3
        )
        for (index in tagIds.indices) {
            val tag = quickTags?.optString(index).orEmpty()
            if (tag.isBlank()) {
                views.setViewVisibility(tagIds[index], View.GONE)
            } else {
                views.setViewVisibility(tagIds[index], View.VISIBLE)
                views.setTextViewText(tagIds[index], "#$tag")
                views.setOnClickPendingIntent(
                    tagIds[index],
                    deepLinkPendingIntent(
                        context,
                        "inkroot://quick-note?tag=${Uri.encode(tag)}",
                        30 + index
                    )
                )
            }
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}

class InkRootRandomReviewWidgetProvider : BaseInkRootWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == ACTION_RANDOM_REVIEW_TICK) {
            updateAllReviewWidgets(context)
            scheduleReviewUpdate(context)
            return
        }
        super.onReceive(context, intent)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        scheduleReviewUpdate(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        cancelReviewUpdate(context)
    }

    override fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val snapshot = snapshot(context)
        val views = RemoteViews(context.packageName, R.layout.inkroot_random_review_widget)
        val reviewNotes = snapshot?.optJSONArray("reviewNotes")
        val reviewConfig = snapshot?.optJSONObject("reviewConfig")
        val refreshMinutes = reviewConfig?.optInt("refreshIntervalMinutes", 60) ?: 60
        val rangeDays = reviewConfig?.optInt("rangeDays", 0) ?: 0
        val reviewCount = reviewNotes?.length() ?: 0
        val review = if (reviewCount > 0) {
            val intervalMillis = refreshMinutes.coerceIn(15, 1440) * 60_000L
            val bucket = System.currentTimeMillis() / intervalMillis
            reviewNotes?.optJSONObject((bucket % reviewCount.toLong()).toInt())
        } else {
            null
        }
        val reviewText = review?.optString("preview")?.takeIf { it.isNotBlank() }
            ?: "打开 InkRoot 后显示随机回顾"
        val reviewId = review?.optString("id").orEmpty()

        views.setTextViewText(R.id.inkroot_widget_review, reviewText)
        views.setTextViewText(
            R.id.inkroot_widget_status,
            "${formatRefresh(refreshMinutes)} · ${formatRange(rangeDays)}"
        )
        views.setOnClickPendingIntent(
            R.id.inkroot_widget_review_container,
            deepLinkPendingIntent(
                context,
                if (reviewId.isNotBlank()) "inkroot://note/$reviewId" else "inkroot://random-review",
                50
            )
        )
        views.setOnClickPendingIntent(
            R.id.inkroot_widget_random,
            deepLinkPendingIntent(context, "inkroot://random-review", 51)
        )

        appWidgetManager.updateAppWidget(appWidgetId, views)
        scheduleReviewUpdate(context, refreshMinutes)
    }

    private fun formatRefresh(minutes: Int): String =
        if (minutes < 60) "${minutes}分钟刷新" else "${minutes / 60}小时刷新"

    private fun formatRange(days: Int): String =
        when (days) {
            0 -> "全部"
            30 -> "近30天"
            90 -> "近90天"
            180 -> "近半年"
            365 -> "近一年"
            else -> "${days}天"
        }

    private fun updateAllReviewWidgets(context: Context) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val widgetIds = appWidgetManager.getAppWidgetIds(
            ComponentName(context, InkRootRandomReviewWidgetProvider::class.java)
        )
        for (appWidgetId in widgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun scheduleReviewUpdate(context: Context, refreshMinutes: Int = currentRefreshMinutes(context)) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val widgetIds = appWidgetManager.getAppWidgetIds(
            ComponentName(context, InkRootRandomReviewWidgetProvider::class.java)
        )
        if (widgetIds.isEmpty()) {
            cancelReviewUpdate(context)
            return
        }

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val intervalMillis = refreshMinutes.coerceIn(15, 1440) * 60_000L
        val pendingIntent = reviewUpdatePendingIntent(context)
        alarmManager.cancel(pendingIntent)
        alarmManager.setInexactRepeating(
            AlarmManager.RTC,
            System.currentTimeMillis() + intervalMillis,
            intervalMillis,
            pendingIntent
        )
    }

    private fun cancelReviewUpdate(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        alarmManager.cancel(reviewUpdatePendingIntent(context))
    }

    private fun currentRefreshMinutes(context: Context): Int {
        val snapshot = snapshot(context)
        return snapshot
            ?.optJSONObject("reviewConfig")
            ?.optInt("refreshIntervalMinutes", 60)
            ?: 60
    }

    private fun reviewUpdatePendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, InkRootRandomReviewWidgetProvider::class.java).apply {
            action = ACTION_RANDOM_REVIEW_TICK
        }
        val immutableFlag =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_IMMUTABLE
            } else {
                0
            }
        return PendingIntent.getBroadcast(
            context,
            92,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag
        )
    }

    companion object {
        private const val ACTION_RANDOM_REVIEW_TICK =
            "com.didichou.inkroot.action.RANDOM_REVIEW_WIDGET_TICK"
    }
}
