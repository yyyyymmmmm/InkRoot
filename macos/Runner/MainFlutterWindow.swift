import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
    
    // 配置Mac风格的窗口
    configureWindow()
  }
  
  private func configureWindow() {
    // 设置窗口初始大小（适合笔记应用的黄金比例）
    let screenSize = NSScreen.main?.visibleFrame.size ?? NSSize(width: 1280, height: 800)
    let windowWidth: CGFloat = min(1200, screenSize.width * 0.7)
    let windowHeight: CGFloat = min(800, screenSize.height * 0.8)
    
    // 居中显示
    let windowX = (screenSize.width - windowWidth) / 2
    let windowY = (screenSize.height - windowHeight) / 2
    
    self.setFrame(NSRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight), display: true)
    
    // 设置最小窗口大小
    self.minSize = NSSize(width: 800, height: 600)
    
    // 设置窗口标题
    self.title = "墨鸣笔记"
    
    // 启用全屏按钮
    self.collectionBehavior = [.fullScreenPrimary]
    
    // 设置标题栏样式 - 使用标准样式，不透明
    self.titlebarAppearsTransparent = false
    self.titleVisibility = .visible
    
    // 设置窗口样式 - 标准窗口，不使用fullSizeContentView
    self.styleMask = [.titled, .closable, .miniaturizable, .resizable]
  }
}
