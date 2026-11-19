import AppKit
import Foundation
import SwiftUI
import Testing

@testable import SalaryTicker

/// README용 패널 PNG를 docs/에 렌더링한다. 평소 `swift test`에서는 건너뛴다.
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
  /// 세후 1년 17,895,920원(비과세 0). 기대값: × 12,600초(점심 뺀 09:30~14:00) ÷ (12 × 21일 × 28,800초)
  /// = 31,069.3… → 31,069, 초당 2.46… → 2.5원.
  @Test func renderPanel() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
    let now = calendar.date(
      from: DateComponents(year: 2026, month: 11, day: 9, hour: 14, minute: 0, second: 0))!

    let suiteName = "SalaryTickerScreenshotTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let model = TickerModel(store: SalaryStore(defaults: defaults), calendar: calendar, now: now)
    #expect(model.submitAnnualSalary("20000000"))
    #expect(model.earnedToday == 31_069)
    #expect(model.perSecondText == "세후 초당 2.5원")

    try FileManager.default.createDirectory(at: Self.docs, withIntermediateDirectories: true)
    try render(PanelView(model: model), calendar: calendar, to: "panel.png")
    try render(
      PanelView(model: model, isSettingsExpanded: true), calendar: calendar,
      to: "panel-expanded.png")
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
