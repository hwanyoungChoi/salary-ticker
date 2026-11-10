import SwiftUI

@main
struct SalaryTickerApp: App {
  @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

  var body: some Scene {
    MenuBarExtra("0원") {
      Button("종료") { NSApplication.shared.terminate(nil) }
        .keyboardShortcut("q")
    }
  }
}

// 메뉴바 전용 앱이라 Dock 아이콘과 앱 전환기에서 숨긴다.
final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
  }
}
