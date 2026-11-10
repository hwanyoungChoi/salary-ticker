import AppKit
import SwiftUI

extension View {
  /// MenuBarExtra(.window) 창은 처음 열린 높이에 머물러, 설정을 펼쳐 내용이 길어지면 위아래가 잘린다.
  /// 내용의 원래 높이를 재서 창 위 끝(메뉴바 쪽)은 그대로 두고 창 높이를 맞춘다.
  func fitsWindowHeight() -> some View {
    modifier(FitsWindowHeight())
  }
}

private struct FitsWindowHeight: ViewModifier {
  @State private var window: NSWindow?
  @State private var contentHeight: CGFloat = 0

  func body(content: Content) -> some View {
    content
      .fixedSize(horizontal: false, vertical: true)
      .onGeometryChange(for: CGFloat.self) {
        $0.size.height
      } action: {
        contentHeight = $0
      }
      .background(WindowReader { window = $0 })
      .onChange(of: contentHeight) { fit() }
      .onChange(of: window) { fit() }
  }

  private func fit() {
    guard let window, contentHeight > 0 else { return }
    let current = window.contentRect(forFrameRect: window.frame)
    guard abs(current.height - contentHeight) > 0.5 else { return }
    let fitted = NSRect(
      x: current.minX, y: current.maxY - contentHeight,
      width: current.width, height: contentHeight)
    window.setFrame(window.frameRect(forContentRect: fitted), display: true)
  }
}

/// SwiftUI 뷰가 올라간 NSWindow를 알려 준다.
private struct WindowReader: NSViewRepresentable {
  let onWindow: @MainActor (NSWindow?) -> Void

  func makeNSView(context: Context) -> NSView {
    WindowReportingView(onWindow: onWindow)
  }

  func updateNSView(_ nsView: NSView, context: Context) {}
}

private final class WindowReportingView: NSView {
  private let onWindow: @MainActor (NSWindow?) -> Void

  init(onWindow: @escaping @MainActor (NSWindow?) -> Void) {
    self.onWindow = onWindow
    super.init(frame: .zero)
  }

  required init?(coder: NSCoder) { nil }

  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    let window = window
    // 뷰 갱신 도중 상태를 바꾸지 않도록 다음 차례로 미룬다.
    Task { @MainActor in onWindow(window) }
  }
}
