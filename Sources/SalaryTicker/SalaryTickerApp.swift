import SwiftUI

@main
struct SalaryTickerApp: App {
  @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
  @State private var model: TickerModel

  init() {
    let model = TickerModel(
      store: SalaryStore(defaults: .standard), calendar: .autoupdatingCurrent)
    model.startTicking()
    _model = State(initialValue: model)
  }

  var body: some Scene {
    MenuBarExtra {
      PanelView(model: model)
        .fitsWindowHeight()
    } label: {
      MenuBarLabel(model: model)
    }
    .menuBarExtraStyle(.window)
  }
}

// 메뉴바 전용 앱이라 Dock 아이콘과 앱 전환기에서 숨긴다.
final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
  }
}
