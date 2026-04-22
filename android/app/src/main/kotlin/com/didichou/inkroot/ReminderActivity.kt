package com.didichou.inkroot

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView

/**
 * 🔥 提醒Activity（对标微信、滴答清单的全屏提醒）
 * 在锁屏时也能弹出，有声音、振动
 */
class ReminderActivity : Activity() {
    
    private var vibrator: Vibrator? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super<Activity>.onCreate(savedInstanceState)
        
        android.util.Log.e("ReminderActivity", "════════════════════════════════")
        android.util.Log.e("ReminderActivity", "🔥🔥🔥 提醒Activity启动！")
        
        // 🔥🔥🔥 关键：锁屏显示配置
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                    or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                    or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }
        
        // 解锁屏幕
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguardManager.requestDismissKeyguard(this, null)
        }
        
        // 获取数据
        val title = intent.getStringExtra("title") ?: "笔记提醒"
        val body = intent.getStringExtra("body") ?: ""
        
        android.util.Log.e("ReminderActivity", "标题: $title")
        android.util.Log.e("ReminderActivity", "内容: $body")
        
        // 🔥 播放声音
        playSound()
        
        // 🔥 振动
        startVibration()
        
        // 设置布局（简单的全屏提醒界面）
        setContentView(createSimpleLayout(title, body))
        
        android.util.Log.e("ReminderActivity", "✅ Activity显示完成")
        android.util.Log.e("ReminderActivity", "════════════════════════════════")
    }
    
    private fun createSimpleLayout(title: String, body: String): android.view.View {
        val layout = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            setPadding(60, 120, 60, 120)
            setBackgroundColor(0xFFFFFFFF.toInt())
            gravity = android.view.Gravity.CENTER
        }
        
        // 标题
        val titleView = TextView(this).apply {
            text = title
            textSize = 24f
            setTextColor(0xFF000000.toInt())
            gravity = android.view.Gravity.CENTER
            setPadding(0, 0, 0, 40)
        }
        layout.addView(titleView)
        
        // 内容
        val bodyView = TextView(this).apply {
            text = body
            textSize = 18f
            setTextColor(0xFF333333.toInt())
            gravity = android.view.Gravity.CENTER
            setPadding(0, 0, 0, 80)
        }
        layout.addView(bodyView)
        
        // 关闭按钮
        val closeButton = Button(this).apply {
            text = "知道了"
            textSize = 18f
            setPadding(80, 40, 80, 40)
            setBackgroundColor(0xFFFF5722.toInt())
            setTextColor(0xFFFFFFFF.toInt())
            setOnClickListener {
                stopVibration()
                finish()
            }
        }
        layout.addView(closeButton)
        
        return layout
    }
    
    private fun playSound() {
        try {
            val notification = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            val ringtone = RingtoneManager.getRingtone(applicationContext, notification)
            ringtone.play()
            android.util.Log.e("ReminderActivity", "🔊 声音播放成功")
        } catch (e: Exception) {
            android.util.Log.e("ReminderActivity", "声音播放失败: ${e.message}")
        }
    }
    
    private fun startVibration() {
        try {
            vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 1000, 500, 1000), -1))
            } else {
                vibrator?.vibrate(longArrayOf(0, 1000, 500, 1000), -1)
            }
            android.util.Log.e("ReminderActivity", "📳 振动开始")
        } catch (e: Exception) {
            android.util.Log.e("ReminderActivity", "振动失败: ${e.message}")
        }
    }
    
    private fun stopVibration() {
        vibrator?.cancel()
        android.util.Log.e("ReminderActivity", "📳 振动停止")
    }
    
    override fun onDestroy() {
        super<Activity>.onDestroy()
        stopVibration()
        android.util.Log.e("ReminderActivity", "Activity销毁")
    }
}

