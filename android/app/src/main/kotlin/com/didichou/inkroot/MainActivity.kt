package com.didichou.inkroot

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.BroadcastReceiver
import android.content.IntentFilter
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.umeng.analytics.MobclickAgent
import com.umeng.commonsdk.UMConfigure

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.didichou.inkroot/native_alarm"
    private val UMENG_CHANNEL = "com.didichou.inkroot/umeng"
    private var methodChannel: MethodChannel? = null
    private var umengChannel: MethodChannel? = null
    private var pendingNoteId: Int? = null
    private var isUmengInitialized = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 友盟统计 Method Channel
        umengChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UMENG_CHANNEL)
        umengChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "init" -> {
                    if (!isUmengInitialized) {
                        try {
                            // 初始化友盟SDK
                            UMConfigure.init(this, "68f40dfe644c9e2c20597ea5", "default", UMConfigure.DEVICE_TYPE_PHONE, null)
                            // 🔥 开启日志用于调试（Release 时可以关闭）
                            UMConfigure.setLogEnabled(true)
                            // 设置场景类型
                            MobclickAgent.setPageCollectionMode(MobclickAgent.PageMode.AUTO)
                            isUmengInitialized = true
                            android.util.Log.d("UmengAnalytics", "友盟统计初始化成功")
                            android.util.Log.d("UmengAnalytics", "AppKey: 68f40dfe644c9e2c20597ea5")
                            android.util.Log.d("UmengAnalytics", "Channel: default")
                            result.success(true)
                        } catch (e: Exception) {
                            android.util.Log.e("UmengAnalytics", "友盟统计初始化失败: ${e.message}")
                            result.error("INIT_FAILED", e.message, null)
                        }
                    } else {
                        result.success(true)
                    }
                }
                "onEvent" -> {
                    // 直接获取参数（Flutter传递的是String，不是Map）
                    val eventId = call.arguments as? String
                    if (eventId != null) {
                        MobclickAgent.onEvent(this, eventId)
                        android.util.Log.d("UmengAnalytics", "事件已记录: $eventId")
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "eventId is required", null)
                    }
                }
                "onEventWithMap" -> {
                    val eventId = call.argument<String>("eventId")
                    val params = call.argument<Map<String, String>>("params")
                    if (eventId != null && params != null) {
                        MobclickAgent.onEvent(this, eventId, params)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "eventId and params are required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val noteId = call.argument<Int>("noteId") ?: 0
                    val title = call.argument<String>("title") ?: ""
                    val body = call.argument<String>("body") ?: ""
                    val triggerTime = call.argument<Long>("triggerTime") ?: 0L
                    
                    val success = scheduleAlarm(noteId, title, body, triggerTime)
                    result.success(success)
                }
                "cancelAlarm" -> {
                    val noteId = call.argument<Int>("noteId") ?: 0
                    cancelAlarm(noteId)
                    result.success(true)
                }
                "openAppSettings" -> {
                    openAppSettings()
                    result.success(true)
                }
                "requestBatteryOptimization" -> {
                    requestIgnoreBatteryOptimizations()
                    result.success(true)
                }
                "requestNotificationPermission" -> {
                    requestNotificationPermission()
                    result.success(true)
                }
                "getInitialNoteId" -> {
                    // 获取初始的noteId（从通知点击进入）
                    result.success(pendingNoteId)
                    pendingNoteId = null // 清空以避免重复处理
                }
                "checkPermissions" -> {
                    // 检查所有权限状态
                    val permissions = checkAllPermissions()
                    result.success(permissions)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // 🔥 处理从通知点击进入的情况
        handleIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // 🔥 关键：更新intent（如果应用在后台，这样才能拿到新的noteId）
        setIntent(intent)
        // 🔥 处理应用在后台时点击通知
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent?) {
        intent?.let {
            // 🔥 处理保存提醒通知（优先处理，避免被openNote覆盖）
            val isSaveNotification = it.getBooleanExtra("isSaveNotification", false)
            if (isSaveNotification) {
                val noteId = it.getIntExtra("noteId", 0)
                val title = it.getStringExtra("title") ?: ""
                val body = it.getStringExtra("body") ?: ""
                val triggerTime = it.getLongExtra("triggerTime", 0L)
                
                android.util.Log.e("MainActivity", "════════════════════════════════")
                android.util.Log.e("MainActivity", "🔥 收到保存提醒通知请求！")
                android.util.Log.e("MainActivity", "noteId=$noteId")
                android.util.Log.e("MainActivity", "════════════════════════════════")
                
                // 通过MethodChannel通知Flutter保存到数据库
                try {
                    val data = mapOf(
                        "noteId" to noteId,
                        "title" to title,
                        "body" to body,
                        "triggerTime" to triggerTime
                    )
                    methodChannel?.invokeMethod("saveReminderNotification", data)
                    android.util.Log.e("MainActivity", "✅ 已通知Flutter保存提醒记录")
                } catch (e: Exception) {
                    android.util.Log.e("MainActivity", "❌ 通知Flutter失败: ${e.message}")
                }
                
                return // 处理完就返回，不继续处理openNote
            }
            
            // 🔥 处理通知点击
            val noteId = it.getIntExtra("noteId", -1)
            if (noteId != -1) {
                android.util.Log.e("MainActivity", "════════════════════════════════")
                android.util.Log.e("MainActivity", "🔥 收到通知点击！")
                android.util.Log.e("MainActivity", "noteId=$noteId")
                android.util.Log.e("MainActivity", "methodChannel is null: ${methodChannel == null}")
                android.util.Log.e("MainActivity", "════════════════════════════════")
                
                // 如果Flutter已经准备好，直接通知
                try {
                    methodChannel?.invokeMethod("openNote", noteId)
                    android.util.Log.e("MainActivity", "✅ 已通过MethodChannel发送openNote消息")
                } catch (e: Exception) {
                    android.util.Log.e("MainActivity", "❌ MethodChannel调用失败: ${e.message}")
                }
                
                // 同时保存noteId等待Flutter查询（备用）
                pendingNoteId = noteId
                android.util.Log.e("MainActivity", "pendingNoteId已设置为: $pendingNoteId")
            } 
            // 🔥 处理分享内容
            else if (it.action == Intent.ACTION_SEND || it.action == Intent.ACTION_SEND_MULTIPLE) {
                handleSharedContent(it)
            } 
            else {
                android.util.Log.e("MainActivity", "⚠️ 未从Intent中获取到noteId或分享内容")
            }
        }
    }
    
    // 🔥 处理分享的内容
    private fun handleSharedContent(intent: Intent) {
        android.util.Log.e("MainActivity", "════════════════════════════════")
        android.util.Log.e("MainActivity", "🔥 收到分享内容！")
        android.util.Log.e("MainActivity", "Action: ${intent.action}")
        android.util.Log.e("MainActivity", "Type: ${intent.type}")
        android.util.Log.e("MainActivity", "════════════════════════════════")
        
        try {
            when {
                // 处理文本分享
                intent.type?.startsWith("text/") == true -> {
                    val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
                    if (!sharedText.isNullOrEmpty()) {
                        android.util.Log.e("MainActivity", "📝 收到分享的文本: ${sharedText.take(50)}...")
                        methodChannel?.invokeMethod("onSharedText", sharedText)
                    }
                }
                // 处理图片分享
                intent.type?.startsWith("image/") == true -> {
                    if (intent.action == Intent.ACTION_SEND) {
                        // 单张图片
                        val imageUri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            intent.getParcelableExtra(Intent.EXTRA_STREAM, android.net.Uri::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            intent.getParcelableExtra(Intent.EXTRA_STREAM)
                        }
                        imageUri?.let { uri ->
                            val path = getRealPathFromURI(uri)
                            if (path != null) {
                                android.util.Log.e("MainActivity", "📷 收到分享的图片: $path")
                                methodChannel?.invokeMethod("onSharedImage", path)
                            } else {
                                android.util.Log.e("MainActivity", "❌ 无法获取图片路径")
                            }
                        }
                    } else if (intent.action == Intent.ACTION_SEND_MULTIPLE) {
                        // 多张图片
                        val imageUris = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, android.net.Uri::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)
                        }
                        val paths = imageUris?.mapNotNull { uri ->
                            getRealPathFromURI(uri)
                        } ?: emptyList()
                        if (paths.isNotEmpty()) {
                            android.util.Log.e("MainActivity", "📷 收到分享的图片: ${paths.size}张")
                            methodChannel?.invokeMethod("onSharedImages", paths)
                        }
                    }
                }
                // 处理其他文件
                else -> {
                    val fileUri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        intent.getParcelableExtra(Intent.EXTRA_STREAM, android.net.Uri::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        intent.getParcelableExtra(Intent.EXTRA_STREAM)
                    }
                    fileUri?.let { uri ->
                        val path = getRealPathFromURI(uri)
                        if (path != null) {
                            android.util.Log.e("MainActivity", "📎 收到分享的文件: $path")
                            methodChannel?.invokeMethod("onSharedFile", path)
                        } else {
                            android.util.Log.e("MainActivity", "❌ 无法获取文件路径")
                        }
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "❌ 处理分享内容失败: ${e.message}")
            e.printStackTrace()
        }
    }
    
    // 🔥 获取文件真实路径（将 content URI 的文件复制到应用目录）
    private fun getRealPathFromURI(uri: android.net.Uri): String? {
        return try {
            // 尝试从 MediaStore 获取真实路径
            val cursor = contentResolver.query(uri, null, null, null, null)
            cursor?.use {
                if (it.moveToFirst()) {
                    val index = it.getColumnIndex(android.provider.MediaStore.Images.ImageColumns.DATA)
                    if (index != -1) {
                        val path = it.getString(index)
                        if (path != null && java.io.File(path).exists()) {
                            return path
                        }
                    }
                }
            }
            
            // 如果无法获取路径，将文件复制到应用缓存目录
            android.util.Log.e("MainActivity", "⚠️ 无法获取真实路径，将文件复制到缓存目录")
            copyUriToCache(uri)
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "❌ 获取文件路径失败: ${e.message}")
            e.printStackTrace()
            null
        }
    }
    
    // 🔥 将 URI 的文件复制到缓存目录
    private fun copyUriToCache(uri: android.net.Uri): String? {
        return try {
            // 获取文件扩展名
            val mimeType = contentResolver.getType(uri)
            val extension = when {
                mimeType?.startsWith("image/") == true -> {
                    when {
                        mimeType.contains("jpeg") || mimeType.contains("jpg") -> "jpg"
                        mimeType.contains("png") -> "png"
                        mimeType.contains("gif") -> "gif"
                        mimeType.contains("webp") -> "webp"
                        else -> "jpg"
                    }
                }
                else -> "dat"
            }
            
            // 创建缓存文件
            val timestamp = System.currentTimeMillis()
            val cacheDir = cacheDir
            val destFile = java.io.File(cacheDir, "shared_$timestamp.$extension")
            
            // 复制文件
            contentResolver.openInputStream(uri)?.use { input ->
                destFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            
            android.util.Log.e("MainActivity", "✅ 文件已复制到: ${destFile.absolutePath}")
            destFile.absolutePath
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "❌ 复制文件失败: ${e.message}")
            e.printStackTrace()
            null
        }
    }
    
    // 🔥 检查所有权限状态
    private fun checkAllPermissions(): Map<String, Boolean> {
        val permissions = mutableMapOf<String, Boolean>()
        
        // 1. 检查通知权限
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
        permissions["notification"] = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            notificationManager.areNotificationsEnabled()
        } else {
            true
        }
        
        // 2. 检查通知渠道设置（横幅、锁屏等）
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = notificationManager.getNotificationChannel("note_reminders_v2")
            if (channel != null) {
                android.util.Log.e("MainActivity", "通知渠道importance: ${channel.importance}")
                android.util.Log.e("MainActivity", "通知渠道lockscreenVisibility: ${channel.lockscreenVisibility}")
                
                // 横幅通知：检查重要性级别（如果通知权限开了，就认为横幅也开了）
                permissions["banner"] = channel.importance >= android.app.NotificationManager.IMPORTANCE_DEFAULT && permissions["notification"] == true
                
                // 锁屏通知：检查可见性（如果通知权限开了，就认为锁屏也开了）
                permissions["lockscreen"] = permissions["notification"] == true
            } else {
                // 如果渠道不存在，但通知权限开了，说明还没创建渠道，先认为开启
                permissions["banner"] = permissions["notification"] == true
                permissions["lockscreen"] = permissions["notification"] == true
            }
        } else {
            permissions["banner"] = true
            permissions["lockscreen"] = true
        }
        
        // 3. 检查精确闹钟权限
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
            permissions["alarm"] = alarmManager.canScheduleExactAlarms()
        } else {
            permissions["alarm"] = true
        }
        
        // 4. 检查电池优化（MIUI关键）
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
            permissions["battery"] = powerManager.isIgnoringBatteryOptimizations(packageName)
            permissions["batteryOptimization"] = powerManager.isIgnoringBatteryOptimizations(packageName)
        } else {
            permissions["battery"] = true
            permissions["batteryOptimization"] = true
        }
        
        // 5. 自启动权限（小米特有，无法直接检查，假定为false）
        // 注意：Android标准API无法检查自启动权限，需要用户手动确认
        permissions["autostart"] = false
        
        return permissions
    }
    
    private fun openAppSettings() {
        try {
            val intent = Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = android.net.Uri.fromParts("package", packageName, null)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    // 🔥 请求忽略电池优化（小米手机关键）
    private fun requestIgnoreBatteryOptimizations() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val intent = Intent(android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = android.net.Uri.parse("package:$packageName")
                }
                startActivity(intent)
            }
        } catch (e: Exception) {
            e.printStackTrace()
            // 如果直接请求失败，跳转到电池优化设置页
            try {
                val intent = Intent(android.provider.Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                startActivity(intent)
            } catch (e2: Exception) {
                e2.printStackTrace()
            }
        }
    }
    
    // 🔥🔥🔥 请求通知权限（Android 13+）
    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 1001)
        }
    }

    private fun scheduleAlarm(noteId: Int, title: String, body: String, triggerTime: Long): Boolean {
        return try {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            val intent = Intent(this, AlarmReceiver::class.java).apply {
                putExtra("noteId", noteId)
                putExtra("title", title)
                putExtra("body", body)
            }
            
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                noteId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // 使用精确闹钟（Android 12+需要权限）
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerTime,
                        pendingIntent
                    )
                } else {
                    // 如果没有精确闹钟权限，使用普通闹钟
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerTime,
                        pendingIntent
                    )
                }
            } else {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
            }
            
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun cancelAlarm(noteId: Int) {
        try {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(this, AlarmReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                noteId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}