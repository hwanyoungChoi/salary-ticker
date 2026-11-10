import AppKit
import Foundation
import SwiftUI
import Testing

@testable import SalaryTicker

/// 패널의 설정 접기. 화면에 띄우지 않은 창에 패널을 붙여, 입력칸·시각 피커가 그려졌는지 본다.
/// 테스트 프로세스는 활성화가 막혀 있어(`.prohibited`) 패널의 `NSApp.activate()`가 포커스를 뺏지 않는다.
@Suite("설정 접기")
@MainActor
struct PanelViewTests {
  @Test func settingsAreCollapsedWhenOpened() {
    withPanel(isSettingsExpanded: false) { panel in
      #expect(!panel.showsSettings)
    }
  }

  /// 펼친 채 닫았다가(창에서 떼기 = onDisappear) 다시 열면(붙이기 = onAppear) 접혀 있다.
  @Test func reopenedPanelIsCollapsedAgain() {
    withPanel(isSettingsExpanded: true) { panel in
      #expect(panel.showsSettings)
      panel.close()
      panel.open()
      #expect(!panel.showsSettings)
    }
  }

  private func withPanel(isSettingsExpanded: Bool, _ body: (HostedPanel) -> Void) {
    let suiteName = "SalaryTickerPanelViewTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let model = TickerModel(store: SalaryStore(defaults: defaults), calendar: .current)
    #expect(model.submitAnnualSalary("20000000"))
    let panel = HostedPanel(PanelView(model: model, isSettingsExpanded: isSettingsExpanded))
    panel.open()
    body(panel)
    panel.close()
  }
}

@MainActor
private struct HostedPanel {
  let hostingView: NSHostingView<PanelView>
  let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 260, height: 400), styleMask: .borderless,
    backing: .buffered, defer: false)

  init(_ view: PanelView) {
    _ = NSApplication.shared
    hostingView = NSHostingView(rootView: view)
  }

  func open() {
    window.contentView = hostingView
    settle()
  }

  func close() {
    window.contentView = nil
    settle()
  }

  /// 연봉 입력칸이나 근무 시각 피커가 하나라도 그려져 있는지.
  var showsSettings: Bool { containsControl(in: hostingView) }

  private func containsControl(in view: NSView) -> Bool {
    view is NSTextField || view is NSDatePicker || view.subviews.contains(where: containsControl)
  }

  private func settle() {
    RunLoop.main.run(until: Date().addingTimeInterval(0.2))
  }
}
