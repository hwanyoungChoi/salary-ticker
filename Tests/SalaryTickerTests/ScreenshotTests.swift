import AppKit
import Foundation
import SwiftUI
import Testing

@testable import SalaryTicker

/// README용 앱 화면 PNG를 docs/에 렌더링한다. 평소 `swift test`에서는 건너뛴다.
/// 다시 만들기: `RENDER_SCREENSHOTS=1 swift test --filter ScreenshotTests`
@Suite(
  "README 스크린샷",
  .enabled(if: ProcessInfo.processInfo.environment["RENDER_SCREENSHOTS"] != nil))
@MainActor
struct ScreenshotTests {
  private static let docs = URL(filePath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    .appending(path: "docs")

  /// 예시 연봉 2천만 원, 기본 시간표, 2026-11-09(월) 14:00 Asia/Seoul.
  /// 기대값: 20,000,000 × 16,200초 ÷ (52 × 5 × 32,400초) = 38,461.5… → 38,461, 초당 2.37… → 2.4원.
  @Test func renderPanelAndMenuBarLabel() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
    let now = calendar.date(
      from: DateComponents(year: 2026, month: 11, day: 9, hour: 14, minute: 0, second: 0))!

    let suiteName = "SalaryTickerScreenshotTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let model = TickerModel(store: SalaryStore(defaults: defaults), calendar: calendar, now: now)
    #expect(model.submitAnnualSalary("20000000"))
    #expect(model.earnedToday == 38_461)
    #expect(model.perSecondText == "초당 2.4원")

    try FileManager.default.createDirectory(at: Self.docs, withIntermediateDirectories: true)
    try render(PanelView(model: model), calendar: calendar, to: "panel.png")
    try render(
      PanelView(model: model, isSettingsExpanded: true), calendar: calendar,
      to: "panel-expanded.png")
    try render(MenuBarLabel(model: model).padding(6), calendar: calendar, to: "menubar.png")
  }

  /// `ImageRenderer`는 입력칸·시각 피커 같은 AppKit 컨트롤을 그리지 못해, 화면에 띄우지 않은
  /// 창의 `NSHostingView`를 비트맵으로 그린다(화면 기록 권한 불필요).
  private func render(_ view: some View, calendar: Calendar, to fileName: String) throws {
    _ = NSApplication.shared
    let content =
      view
      .environment(\.calendar, calendar)
      .environment(\.timeZone, calendar.timeZone)
      .environment(\.locale, Locale(identifier: "ko_KR"))
      // 창을 화면에 띄우지 않아 비활성 색으로 그려지는 것을, 패널이 열린 상태(활성)로 맞춘다.
      .environment(\.controlActiveState, .key)
    let hostingView = NSHostingView(rootView: content)
    let window = NSWindow(
      contentRect: NSRect(origin: .zero, size: hostingView.fittingSize), styleMask: .borderless,
      backing: .buffered, defer: false)
    window.appearance = NSAppearance(named: .aqua)
    window.backgroundColor = .windowBackgroundColor
    window.contentView = hostingView
    // onAppear(저장된 연봉을 입력칸에 채움)와 다시 그리기가 끝나도록 런루프를 잠깐 돌린다.
    RunLoop.main.run(until: Date().addingTimeInterval(0.5))
    hostingView.frame.size = hostingView.fittingSize
    hostingView.layoutSubtreeIfNeeded()

    let size = hostingView.bounds.size
    let scale = 2
    let bitmap = try #require(
      NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(size.width) * scale,
        pixelsHigh: Int(size.height) * scale, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0,
        bitsPerPixel: 0))
    bitmap.size = size
    hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)
    let data = try #require(bitmap.representation(using: .png, properties: [:]))
    try data.write(to: Self.docs.appending(path: fileName))
  }
}
