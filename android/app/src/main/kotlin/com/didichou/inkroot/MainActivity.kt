package com.didichou.inkroot

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.umeng.analytics.MobclickAgent
import com.umeng.commonsdk.UMConfigure
import java.io.File
import java.util.UUID
import java.util.concurrent.Executors

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.didichou.inkroot/native_alarm"
    private val UMENG_CHANNEL = "com.didichou.inkroot/umeng"
    private var methodChannel: MethodChannel? = null
    private var umengChannel: MethodChannel? = null
    private var pendingNoteId: Int? = null
    private var pendingSharedPayload: Map<String, Any>? = null
    private var pendingDeepLink: String? = null
    private var isUmengInitialized = false
    private val shareExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    private data class SharedUriItem(
        val uri: Uri,
        val isImage: Boolean
    )

    private data class CopiedSharedFile(
        val path: String,
        val isImage: Boolean
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 友盟统计 Method Channel
        umengChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UMENG_CHANNEL)
        umengChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "init" -> {
                    if (!isUmengInitialized) {
                        try {
                            val appInfo = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
                            val appKey = appInfo.metaData?.getString("UMENG_APPKEY")?.trim().orEmpty()
                            val channel = appInfo.metaData?.getString("UMENG_CHANNEL")?.trim().orEmpty().ifEmpty { "default" }

                            if (appKey.isEmpty()) {
                                ReleaseLog.d("UmengAnalytics", "友盟统计未配置，跳过初始化")
                                result.success(false)
                                return@setMethodCallHandler
                            }

                            UMConfigure.init(this, appKey, channel, UMConfigure.DEVICE_TYPE_PHONE, null)
                            UMConfigure.setLogEnabled(BuildConfig.DEBUG)
                            // 设置场景类型
                            MobclickAgent.setPageCollectionMode(MobclickAgent.PageMode.AUTO)
                            isUmengInitialized = true
                            ReleaseLog.d("UmengAnalytics", "友盟统计初始化成功")
                            ReleaseLog.d("UmengAnalytics", "Channel: $channel")
                            result.success(true)
                        } catch (e: Exception) {
                            ReleaseLog.e("UmengAnalytics", "友盟统计初始化失败: ${e.message}")
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
                        ReleaseLog.d("UmengAnalytics", "事件已记录: $eventId")
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
                "requestNotificationPermission" -> {
                    requestNotificationPermission()
                    result.success(true)
                }
                "getInitialNoteId" -> {
                    // 获取初始的noteId（从通知点击进入）
                    result.success(pendingNoteId)
                    pendingNoteId = null // 清空以避免重复处理
                }
                "getInitialPayload" -> {
                    result.success(pendingNoteId)
                    pendingNoteId = null
                }
                "getInitialSharedPayload" -> {
                    result.success(pendingSharedPayload)
                    pendingSharedPayload = null
                }
                "getInitialDeepLink" -> {
                    result.success(pendingDeepLink)
                    pendingDeepLink = null
                }
                "saveWidgetSnapshot" -> {
                    val key = call.argument<String>("key") ?: "inkroot_widget_snapshot"
                    val snapshot = call.argument<String>("snapshot") ?: ""
                    saveWidgetSnapshot(key, snapshot)
                    result.success(true)
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
                
                ReleaseLog.e("MainActivity", "════════════════════════════════")
                ReleaseLog.e("MainActivity", "🔥 收到保存提醒通知请求！")
                ReleaseLog.e("MainActivity", "noteId=$noteId")
                ReleaseLog.e("MainActivity", "════════════════════════════════")
                
                // 通过MethodChannel通知Flutter保存到数据库
                try {
                    val data = mapOf(
                        "noteId" to noteId,
                        "title" to title,
                        "body" to body,
                        "triggerTime" to triggerTime
                    )
                    methodChannel?.invokeMethod("saveReminderNotification", data)
                    ReleaseLog.e("MainActivity", "✅ 已通知Flutter保存提醒记录")
                } catch (e: Exception) {
                    ReleaseLog.e("MainActivity", "❌ 通知Flutter失败: ${e.message}")
                }
                
                return // 处理完就返回，不继续处理openNote
            }
            
            // 🔥 处理通知点击
            val noteId = it.getIntExtra("noteId", -1)
            if (noteId != -1) {
                ReleaseLog.e("MainActivity", "════════════════════════════════")
                ReleaseLog.e("MainActivity", "🔥 收到通知点击！")
                ReleaseLog.e("MainActivity", "noteId=$noteId")
                ReleaseLog.e("MainActivity", "methodChannel is null: ${methodChannel == null}")
                ReleaseLog.e("MainActivity", "════════════════════════════════")
                
                // 如果Flutter已经准备好，直接通知
                try {
                    methodChannel?.invokeMethod("openNote", noteId)
                    ReleaseLog.e("MainActivity", "✅ 已通过MethodChannel发送openNote消息")
                } catch (e: Exception) {
                    ReleaseLog.e("MainActivity", "❌ MethodChannel调用失败: ${e.message}")
                }
                
                // 同时保存noteId等待Flutter查询（备用）
                pendingNoteId = noteId
                ReleaseLog.e("MainActivity", "pendingNoteId已设置为: $pendingNoteId")
            } 
            // 🔥 处理分享内容
            else if (
                it.action == Intent.ACTION_SEND ||
                it.action == Intent.ACTION_SEND_MULTIPLE ||
                it.action == Intent.ACTION_PROCESS_TEXT
            ) {
                handleSharedContent(it)
            } 
            else if (it.data?.scheme == "inkroot") {
                handleDeepLink(it.data.toString())
            }
            else {
                ReleaseLog.e("MainActivity", "⚠️ 未从Intent中获取到noteId或分享内容")
            }
        }
    }

    private fun handleDeepLink(url: String) {
        pendingDeepLink = url
        try {
            methodChannel?.invokeMethod("openDeepLink", url)
        } catch (e: Exception) {
            ReleaseLog.e("MainActivity", "❌ 处理深链失败: ${e.message}")
        }
    }

    private fun saveWidgetSnapshot(key: String, snapshot: String) {
        try {
            getSharedPreferences("inkroot_widget", Context.MODE_PRIVATE)
                .edit()
                .putString(key, snapshot)
                .apply()

            notifyWidgetProvider(InkRootQuickNoteWidgetProvider::class.java)
            notifyWidgetProvider(InkRootRandomReviewWidgetProvider::class.java)
        } catch (e: Exception) {
            ReleaseLog.e("MainActivity", "❌ 保存小组件快照失败: ${e.message}")
        }
    }

    private fun notifyWidgetProvider(providerClass: Class<*>) {
        val appWidgetManager = AppWidgetManager.getInstance(this)
        val componentName = ComponentName(this, providerClass)
        val widgetIds = appWidgetManager.getAppWidgetIds(componentName)
        if (widgetIds.isNotEmpty()) {
            val updateIntent = Intent(this, providerClass).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
            }
            sendBroadcast(updateIntent)
        }
    }
    
    // 🔥 处理分享的内容
    private fun handleSharedContent(intent: Intent) {
        ReleaseLog.e("MainActivity", "════════════════════════════════")
        ReleaseLog.e("MainActivity", "🔥 收到分享内容！")
        ReleaseLog.e("MainActivity", "Action: ${intent.action}")
        ReleaseLog.e("MainActivity", "Type: ${intent.type}")
        ReleaseLog.e("MainActivity", "════════════════════════════════")
        
        try {
            val sharedText = extractSharedText(intent)
            val sharedUris = extractSharedUris(intent)

            if (sharedUris.isEmpty()) {
                if (sharedText.isNotBlank()) {
                    ReleaseLog.e("MainActivity", "📝 收到分享的文本: ${sharedText.take(50)}...")
                    deliverSharedPayload(mapOf("type" to "text", "content" to sharedText))
                } else {
                    ReleaseLog.e("MainActivity", "⚠️ 分享内容为空")
                }
                return
            }

            copySharedUrisAsync(sharedUris) { copiedFiles ->
                if (copiedFiles.isEmpty()) {
                    if (sharedText.isNotBlank()) {
                        deliverSharedPayload(mapOf("type" to "text", "content" to sharedText))
                    } else {
                        ReleaseLog.e("MainActivity", "❌ 无法读取分享附件")
                    }
                    return@copySharedUrisAsync
                }

                val imagePaths = copiedFiles
                    .filter { it.isImage }
                    .map { it.path }
                val filePaths = copiedFiles
                    .filterNot { it.isImage }
                    .map { it.path }

                ReleaseLog.e(
                    "MainActivity",
                    "✅ 分享附件已读取: 图片 ${imagePaths.size}，文件 ${filePaths.size}"
                )
                deliverCombinedSharedPayload(sharedText, imagePaths, filePaths)
            }
        } catch (e: Exception) {
            ReleaseLog.e("MainActivity", "❌ 处理分享内容失败: ${e.message}")
            ReleaseLog.printStackTrace(e)
        }
    }

    private fun copySharedUrisAsync(
        items: List<SharedUriItem>,
        callback: (List<CopiedSharedFile>) -> Unit
    ) {
        shareExecutor.execute {
            val files = items.mapNotNull { item ->
                getRealPathFromURI(item.uri)?.let { path ->
                    CopiedSharedFile(path, item.isImage)
                }
            }
            mainHandler.post { callback(files) }
        }
    }

    private fun extractSharedUris(intent: Intent): List<SharedUriItem> {
        val uris = mutableListOf<Uri>()

        if (intent.action == Intent.ACTION_SEND_MULTIPLE) {
            val streamUris = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)
            }
            if (!streamUris.isNullOrEmpty()) {
                uris.addAll(streamUris)
            }
        } else {
            val streamUri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(Intent.EXTRA_STREAM)
            }
            if (streamUri != null) {
                uris.add(streamUri)
            }
        }

        intent.clipData?.let { clipData ->
            for (index in 0 until clipData.itemCount) {
                clipData.getItemAt(index).uri?.let { uris.add(it) }
            }
        }

        return uris
            .distinctBy { it.toString() }
            .map { uri -> SharedUriItem(uri, isImageShare(intent, uri)) }
    }

    private fun extractSharedText(intent: Intent): String {
        val processText = intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
        val extraText = intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()
        val subject = intent.getStringExtra(Intent.EXTRA_SUBJECT)
        val title = intent.getStringExtra(Intent.EXTRA_TITLE)
        val candidates = listOf(processText, extraText, subject, title)
            .mapNotNull { it?.trim() }
            .filter { it.isNotEmpty() }
            .distinct()

        if (candidates.isEmpty()) {
            return ""
        }

        return if (candidates.size == 1) {
            candidates.first()
        } else {
            candidates.joinToString("\n")
        }
    }

    private fun isImageShare(intent: Intent, uri: Uri): Boolean {
        val intentType = intent.type
        if (intentType?.startsWith("image/") == true) {
            return true
        }

        val contentType = runCatching { contentResolver.getType(uri) }.getOrNull()
        if (contentType?.startsWith("image/") == true) {
            return true
        }

        val path = uri.path?.lowercase().orEmpty()
        return path.endsWith(".jpg") ||
            path.endsWith(".jpeg") ||
            path.endsWith(".png") ||
            path.endsWith(".gif") ||
            path.endsWith(".webp") ||
            path.endsWith(".heic") ||
            path.endsWith(".heif")
    }

    private fun deliverCombinedSharedPayload(
        sharedText: String,
        imagePaths: List<String>,
        filePaths: List<String>
    ) {
        val cleanText = sharedText.trim()
        val hasText = cleanText.isNotEmpty()
        val hasImages = imagePaths.isNotEmpty()
        val hasFiles = filePaths.isNotEmpty()

        when {
            hasText || (hasImages && hasFiles) || filePaths.size > 1 -> {
                deliverSharedPayload(
                    mapOf(
                        "type" to "text",
                        "content" to buildContentWithAttachments(
                            cleanText,
                            imagePaths,
                            filePaths
                        )
                    )
                )
            }
            imagePaths.size == 1 -> {
                deliverSharedPayload(mapOf("type" to "image", "path" to imagePaths.first()))
            }
            imagePaths.size > 1 -> {
                deliverSharedPayload(mapOf("type" to "images", "paths" to imagePaths))
            }
            filePaths.size == 1 -> {
                deliverSharedPayload(mapOf("type" to "file", "path" to filePaths.first()))
            }
        }
    }

    private fun buildContentWithAttachments(
        text: String,
        imagePaths: List<String>,
        filePaths: List<String>
    ): String {
        val lines = mutableListOf<String>()
        if (text.isNotBlank()) {
            lines.add(text)
        }
        imagePaths.forEach { path ->
            lines.add("![图片](file://$path)")
        }
        filePaths.forEach { path ->
            lines.add("📎 ${File(path).name}\n路径: $path")
        }
        return lines.joinToString("\n")
    }

    private fun deliverSharedPayload(payload: Map<String, Any>) {
        pendingSharedPayload = payload
        try {
            methodChannel?.invokeMethod("onSharedPayload", payload)
            ReleaseLog.e("MainActivity", "✅ 已通知Flutter处理分享内容")
        } catch (e: Exception) {
            ReleaseLog.e("MainActivity", "❌ 分享内容通知Flutter失败: ${e.message}")
        }
    }
    
    // 🔥 获取文件真实路径（将 content URI 的文件复制到应用目录）
    private fun getRealPathFromURI(uri: Uri): String? {
        return try {
            // 尝试从 MediaStore 获取真实路径
            val cursor = contentResolver.query(uri, null, null, null, null)
            cursor?.use {
                if (it.moveToFirst()) {
                    val index = it.getColumnIndex(android.provider.MediaStore.Images.ImageColumns.DATA)
                    if (index != -1) {
                        val path = it.getString(index)
                        if (path != null && File(path).exists()) {
                            return path
                        }
                    }
                }
            }
            
            // 如果无法获取路径，将文件复制到应用缓存目录
            ReleaseLog.e("MainActivity", "⚠️ 无法获取真实路径，将文件复制到缓存目录")
            copyUriToCache(uri)
        } catch (e: Exception) {
            ReleaseLog.e("MainActivity", "❌ 获取文件路径失败: ${e.message}")
            ReleaseLog.printStackTrace(e)
            null
        }
    }
    
    // 🔥 将 URI 的文件复制到缓存目录
    private fun copyUriToCache(uri: Uri): String? {
        return try {
            val displayName = queryDisplayName(uri)
            val mimeType = contentResolver.getType(uri)
            val extension = extensionFrom(displayName, mimeType)
            
            // 创建缓存文件
            val safeName = displayName
                ?.substringBeforeLast('.', displayName)
                ?.replace(Regex("[^A-Za-z0-9._-]"), "_")
                ?.take(32)
                ?.ifBlank { null }
                ?: "shared"
            val destFile = File(cacheDir, "${safeName}_${UUID.randomUUID()}.$extension")
            
            // 复制文件
            contentResolver.openInputStream(uri)?.use { input ->
                destFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            
            ReleaseLog.e("MainActivity", "✅ 文件已复制到: ${destFile.absolutePath}")
            destFile.absolutePath
        } catch (e: Exception) {
            ReleaseLog.e("MainActivity", "❌ 复制文件失败: ${e.message}")
            ReleaseLog.printStackTrace(e)
            null
        }
    }

    private fun queryDisplayName(uri: Uri): String? {
        return try {
            contentResolver.query(
                uri,
                arrayOf(OpenableColumns.DISPLAY_NAME),
                null,
                null,
                null
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (index >= 0) cursor.getString(index) else null
                } else {
                    null
                }
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun extensionFrom(displayName: String?, mimeType: String?): String {
        val nameExtension = displayName
            ?.substringAfterLast('.', missingDelimiterValue = "")
            ?.lowercase()
            ?.takeIf { it.isNotBlank() && it.length <= 8 }
        if (nameExtension != null) {
            return nameExtension
        }

        return when {
            mimeType?.contains("jpeg") == true || mimeType?.contains("jpg") == true -> "jpg"
            mimeType?.contains("png") == true -> "png"
            mimeType?.contains("gif") == true -> "gif"
            mimeType?.contains("webp") == true -> "webp"
            mimeType?.contains("heic") == true -> "heic"
            mimeType?.contains("pdf") == true -> "pdf"
            mimeType?.contains("text") == true -> "txt"
            else -> "dat"
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
                ReleaseLog.e("MainActivity", "通知渠道importance: ${channel.importance}")
                ReleaseLog.e("MainActivity", "通知渠道lockscreenVisibility: ${channel.lockscreenVisibility}")
                
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
        
        // 3. 精确闹钟权限不作为必需项。未授权时使用普通系统闹钟兜底。
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
            ReleaseLog.printStackTrace(e)
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

            // Android 12+ 若用户未授予精确闹钟权限，使用普通系统闹钟兜底。
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
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
            }
            
            true
        } catch (e: Exception) {
            ReleaseLog.printStackTrace(e)
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
            ReleaseLog.printStackTrace(e)
        }
    }
}
