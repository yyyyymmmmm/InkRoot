package com.didichou.inkroot

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val noteId = intent.getIntExtra("noteId", 0)
        val noteContent = intent.getStringExtra("body") ?: ""
        
        // 🎯 优化通知标题和内容显示
        val title = "📝 笔记提醒"
        val body = if (noteContent.isNotEmpty()) {
            noteContent
        } else {
            "您有一条笔记提醒"
        }
        
        // 🔥 过滤无效的测试提醒（noteId=0）
        if (noteId == 0) {
            android.util.Log.e("AlarmReceiver", "🚫 忽略测试提醒 noteId=0")
            return
        }
        
        // 🔥 关键日志：确认AlarmReceiver被触发
        android.util.Log.e("AlarmReceiver", "════════════════════════════════")
        android.util.Log.e("AlarmReceiver", "⏰⏰⏰ 闹钟触发！！！")
        android.util.Log.e("AlarmReceiver", "noteId=$noteId, title=$title, body=$body")
        android.util.Log.e("AlarmReceiver", "当前时间: ${System.currentTimeMillis()}")

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // 🔥 定义channel ID（使用新ID确保设置生效）
        val CHANNEL_ID = "note_reminders_v2"
        
        // 🔥 创建通知渠道（Android 8.0+）
        if (Build.VERSION.SDK_INT >= 26) {
            // 🔥 删除旧channel（如果存在）
            try {
                notificationManager.deleteNotificationChannel("note_reminders")
                android.util.Log.e("AlarmReceiver", "✅ 已删除旧通知渠道")
            } catch (e: Exception) {
                android.util.Log.e("AlarmReceiver", "删除旧渠道失败（可能不存在）: ${e.message}")
            }
            
            // 🎯 创建通知渠道（参考大厂：微信、钉钉风格）
            val channel = NotificationChannel(
                CHANNEL_ID,
                "笔记提醒",
                NotificationManager.IMPORTANCE_HIGH  // 高优先级：横幅 + 锁屏 + 声音
            ).apply {
                description = "重要笔记提醒通知"
                
                // 🔔 声音设置（通知类型）
                setSound(
                    android.provider.Settings.System.DEFAULT_NOTIFICATION_URI,
                    android.media.AudioAttributes.Builder()
                        .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setUsage(android.media.AudioAttributes.USAGE_NOTIFICATION)
                        .build()
                )
                
                // 📳 振动设置（简洁模式）
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 300, 200, 300)
                
                // 💡 LED灯（主题色）
                enableLights(true)
                lightColor = 0xFF2C9678.toInt() // 应用主题色
                
                // 🔓 锁屏显示
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
                
                // 📱 其他设置
                setShowBadge(true) // 显示角标
                setBypassDnd(false) // 尊重勿扰模式
            }
            notificationManager.createNotificationChannel(channel)
            android.util.Log.e("AlarmReceiver", "✅ 通知渠道已创建：横幅 + 锁屏 + 声音 + 振动")
        }
        
        // 检查通知权限
        if (Build.VERSION.SDK_INT >= 24) {
            val enabled = notificationManager.areNotificationsEnabled()
            android.util.Log.e("AlarmReceiver", "通知权限状态: ${if (enabled) "✅ 已开启" else "❌ 未开启"}")
            if (!enabled) {
                android.util.Log.e("AlarmReceiver", "❌❌❌ 通知权限未开启，无法显示通知！")
                return
            }
        }

        // 🔥🔥🔥 创建提醒Activity的Intent（用于FullScreenIntent）
        val activityIntent = Intent(context, ReminderActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS
            putExtra("noteId", noteId)
            putExtra("title", title)
            putExtra("body", body)
        }
        
        // 创建PendingIntent用于全屏弹出
        val fullScreenPendingIntent = PendingIntent.getActivity(
            context,
            noteId,
            activityIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        android.util.Log.e("AlarmReceiver", "✅ 已创建FullScreenIntent PendingIntent")
        
        // 🔥🔥🔥 直接播放系统通知声音和强力振动
        try {
            // 播放系统通知声音（不是闹钟声音）
            val ringtoneUri = android.provider.Settings.System.DEFAULT_NOTIFICATION_URI
            val ringtone = android.media.RingtoneManager.getRingtone(context, ringtoneUri)
            if (ringtone != null) {
                ringtone.play()
                android.util.Log.e("AlarmReceiver", "🔊 系统通知声音播放成功")
                
                // 延迟5秒后停止
                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                    try {
                        if (ringtone.isPlaying) {
                            ringtone.stop()
                            android.util.Log.e("AlarmReceiver", "🔊 声音已停止")
                        }
                    } catch (e: Exception) {
                        android.util.Log.e("AlarmReceiver", "停止声音失败: ${e.message}")
                    }
                }, 5000)
            }
        } catch (e: Exception) {
            android.util.Log.e("AlarmReceiver", "播放声音失败: ${e.message}")
            e.printStackTrace()
        }
        
        // 🔥🔥🔥 强力振动（加大振动强度）
        try {
            val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as android.os.Vibrator
            if (vibrator.hasVibrator()) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    // 使用更强的振动效果
                    val vibrationEffect = android.os.VibrationEffect.createWaveform(
                        longArrayOf(0, 500, 200, 500, 200, 500), // 振动-停-振动-停-振动
                        -1 // 不重复
                    )
                    vibrator.vibrate(vibrationEffect)
                    android.util.Log.e("AlarmReceiver", "📳 强力振动已触发（Android 8.0+）")
                } else {
                    vibrator.vibrate(longArrayOf(0, 500, 200, 500, 200, 500), -1)
                    android.util.Log.e("AlarmReceiver", "📳 振动已触发（传统模式）")
                }
            } else {
                android.util.Log.e("AlarmReceiver", "⚠️ 设备不支持振动")
            }
        } catch (e: Exception) {
            android.util.Log.e("AlarmReceiver", "振动失败: ${e.message}")
            e.printStackTrace()
        }
        
            // 🔥🔥🔥 关键：点击通知打开应用（不重启，复用现有Activity）
            val notificationIntent = Intent(context, MainActivity::class.java).apply {
                // 使用SINGLE_TOP避免重启应用，如果应用在后台就直接唤起
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                // 添加action确保onNewIntent能收到
                action = "com.didichou.inkroot.OPEN_NOTE"
                putExtra("noteId", noteId)
            }
            
            val pendingIntent = PendingIntent.getActivity(
                context,
                noteId + 10000,
                notificationIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

        // 🔥🔥🔥 构建通知（对标微信/滴答清单/系统闹钟）
        val iconResId = context.resources.getIdentifier("ic_launcher", "mipmap", context.packageName)
        android.util.Log.e("AlarmReceiver", "图标资源ID: $iconResId")
        
        // 🔥🔥🔥 关键：获取系统默认声音URI
        val defaultSoundUri = android.provider.Settings.System.DEFAULT_NOTIFICATION_URI
        android.util.Log.e("AlarmReceiver", "声音URI: $defaultSoundUri")
        
        // 🎯 大厂风格通知（参考：微信、钉钉、飞书）
        
        // 📝 智能标题：笔记内容前20字 或 "笔记提醒"
        val notificationTitle = if (body.isNotEmpty()) {
            if (body.length > 20) {
                body.substring(0, 20) + "..."
            } else {
                body
            }
        } else {
            "笔记提醒"
        }
        
        // 📝 通知内容：完整笔记内容
        val notificationContent = if (body.isNotEmpty()) {
            body
        } else {
            "您有一条新的笔记提醒，点击查看详情"
        }
        
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            // 📱 图标（大厂风格：应用图标）
            .setSmallIcon(R.mipmap.ic_launcher) // 状态栏小图标
            .setLargeIcon(
                android.graphics.BitmapFactory.decodeResource(
                    context.resources,
                    R.mipmap.ic_launcher
                )
            ) // 通知栏大图标
            
            // 📝 内容（大厂风格：标题=内容摘要，正文=完整内容）
            .setContentTitle(notificationTitle) // 标题：笔记内容摘要
            .setContentText(notificationContent) // 内容：完整笔记内容
            
            // 📄 展开样式（大文本显示）
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText(notificationContent) // 展开后显示完整内容
                    .setBigContentTitle(notificationTitle)
            )
            
            // 🎨 样式设置
            .setColor(0xFF2C9678.toInt()) // 应用主题色
            .setColorized(false) // 不对整个通知着色
            
            // ⚡ 优先级（高优先级 = 横幅通知）
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            
            // 🔔 声音和振动
            .setSound(defaultSoundUri, android.media.AudioManager.STREAM_NOTIFICATION)
            .setVibrate(longArrayOf(0, 300, 200, 300))
            
            // 💡 LED灯
            .setLights(0xFF2C9678.toInt(), 1000, 1000)
            
            // 🔓 锁屏显示
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            
            // ⏰ 时间显示
            .setShowWhen(true)
            .setWhen(System.currentTimeMillis())
            .setOnlyAlertOnce(false)
            
            // 👆 交互设置
            .setAutoCancel(true) // 点击后自动取消
            .setContentIntent(pendingIntent)
            
            // 📱 横幅通知（Heads-up Notification）
            .setFullScreenIntent(fullScreenPendingIntent, false)
            
            .build()

        // 🔥 显示通知（会自动触发FullScreenIntent）
        try {
            android.util.Log.e("AlarmReceiver", "开始发送通知...")
            android.util.Log.e("AlarmReceiver", "通知ID: $noteId")
            notificationManager.notify(noteId, notification)
            android.util.Log.e("AlarmReceiver", "✅✅✅ 通知已成功发送！")
            
            // 🔥🔥🔥 关键：通知触发时立即保存到数据库（市场主流做法）
            // 使用显式Intent发送广播（Android 8.0+必须）
            try {
                val saveIntent = Intent(context, MainActivity::class.java)
                saveIntent.action = "com.didichou.inkroot.SAVE_REMINDER_NOTIFICATION"
                saveIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                saveIntent.putExtra("noteId", noteId)
                saveIntent.putExtra("title", title)
                saveIntent.putExtra("body", body)
                saveIntent.putExtra("triggerTime", System.currentTimeMillis())
                saveIntent.putExtra("isSaveNotification", true) // 标记这是保存通知的请求
                
                // 使用PendingIntent发送
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    noteId + 20000, // 使用不同的requestCode避免冲突
                    saveIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                
                try {
                    pendingIntent.send()
                    android.util.Log.e("AlarmReceiver", "✅ 已发送保存提醒记录的Intent")
                } catch (e: Exception) {
                    android.util.Log.e("AlarmReceiver", "⚠️ 发送Intent失败，尝试直接启动: ${e.message}")
                    // 备用方案：直接启动MainActivity
                    context.startActivity(saveIntent)
                }
            } catch (saveError: Exception) {
                android.util.Log.e("AlarmReceiver", "⚠️ 保存通知失败: ${saveError.message}")
            }
            
            android.util.Log.e("AlarmReceiver", "════════════════════════════════")
        } catch (e: Exception) {
            android.util.Log.e("AlarmReceiver", "❌❌❌ 通知发送失败: ${e.message}")
            e.printStackTrace()
            android.util.Log.e("AlarmReceiver", "════════════════════════════════")
        }
    }
}

