import Flutter
import UIKit
import UserNotifications

// ⚠️ iOS版本不使用友盟统计（符合App Store审核要求）
// Android版本保留友盟统计功能

@main
@objc class AppDelegate: FlutterAppDelegate {
  // 🔥 模仿Android的pendingNoteId机制
  private var pendingPayload: String?
  private var methodChannel: FlutterMethodChannel?
  
  // 🎨 启动页视图（用于淡出动画）
  private var launchScreenView: UIView?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // 🔔 设置通知中心委托
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    
    // 🔥 关键：设置MethodChannel（和Android MainActivity一样）
    let controller = window?.rootViewController as! FlutterViewController
    methodChannel = FlutterMethodChannel(
      name: "com.didichou.inkroot/native_alarm",
      binaryMessenger: controller.binaryMessenger
    )
    
    // 🔥 监听Flutter的查询请求（和Android getInitialNoteId一样）
    methodChannel?.setMethodCallHandler { [weak self] (call, result) in
      if call.method == "getInitialPayload" {
        print("📱 [AppDelegate] Flutter查询初始payload: \(self?.pendingPayload ?? "nil")")
        result(self?.pendingPayload)
        self?.pendingPayload = nil // 清空避免重复
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    print("✅ [AppDelegate] MethodChannel已设置")
    
    // 🎨 启动页动画 MethodChannel
    let launchScreenChannel = FlutterMethodChannel(
      name: "com.didichou.inkroot/launch_screen",
      binaryMessenger: controller.binaryMessenger
    )
    
    launchScreenChannel.setMethodCallHandler { [weak self] (call, result) in
      if call.method == "removeLaunchScreen" {
        print("🎨 [AppDelegate] Flutter请求移除启动页（带动画）")
        self?.removeLaunchScreenWithAnimation()
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    // ⚠️ iOS版本不使用友盟统计 - 为了通过App Store审核
    // 友盟Method Channel已禁用，所有调用将返回false
    let umengChannel = FlutterMethodChannel(
      name: "com.didichou.inkroot/umeng",
      binaryMessenger: controller.binaryMessenger
    )
    
    umengChannel.setMethodCallHandler { (call, result) in
      // iOS平台所有友盟调用返回false（未启用）
      print("⚠️ [UmengAnalytics iOS] iOS平台已禁用友盟统计")
      result(false)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // 🎨 创建启动页覆盖层（大厂标准方案）
  private func setupLaunchScreenOverlay() {
    guard let window = self.window,
          let rootViewController = window.rootViewController else {
      return
    }
    
    // 从 Storyboard 加载启动页
    let storyboard = UIStoryboard(name: "LaunchScreen", bundle: nil)
    if let launchVC = storyboard.instantiateInitialViewController() {
      launchScreenView = launchVC.view
      launchScreenView?.frame = window.bounds
      
      // 添加到最顶层
      rootViewController.view.addSubview(launchScreenView!)
      rootViewController.view.bringSubviewToFront(launchScreenView!)
      
      print("✅ [LaunchScreen] 启动页覆盖层已创建")
    }
  }
  
  // 🎨 移除启动页（带淡出动画，模仿支付宝/小红书）
  func removeLaunchScreenWithAnimation() {
    guard let launchView = launchScreenView else {
      print("⚠️ [LaunchScreen] 启动页视图不存在")
      return
    }
    
    print("🎨 [LaunchScreen] 开始淡出动画...")
    
    // 支付宝/小红书的做法：400ms 淡出动画
    UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
      launchView.alpha = 0
    }) { _ in
      launchView.removeFromSuperview()
      self.launchScreenView = nil
      print("✅ [LaunchScreen] 启动页已移除（带动画）")
    }
  }
  
  // 🔔 处理前台通知
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }
  
  // 🔔 处理通知点击 - 关键！完全模仿Android的handleIntent
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    print("════════════════════════════════")
    print("🔥 [AppDelegate] 用户点击了通知！")
    
    // 🔥 从notification的userInfo中获取payload
    let userInfo = response.notification.request.content.userInfo
    let payload = userInfo["payload"] as? String ?? userInfo["noteIdString"] as? String
    
    print("📱 [AppDelegate] payload: \(payload ?? "nil")")
    print("📱 [AppDelegate] userInfo: \(userInfo)")
    
    if let payload = payload {
      // 🔥 方式1：立即通过MethodChannel发送（和Android一样）
      if let channel = methodChannel {
        print("📱 [AppDelegate] 尝试通过MethodChannel发送openNote...")
        channel.invokeMethod("openNote", arguments: payload)
        print("✅ [AppDelegate] MethodChannel已调用")
      } else {
        print("⚠️ [AppDelegate] MethodChannel未初始化")
      }
      
      // 🔥 方式2：保存payload等待Flutter查询（和Android的pendingNoteId一样）
      pendingPayload = payload
      print("📱 [AppDelegate] pendingPayload已设置: \(payload)")
    } else {
      print("❌ [AppDelegate] payload为空！")
    }
    
    print("════════════════════════════════")
    
    // 🔥 仍然调用父类方法，让flutter_local_notifications也处理
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }
}
