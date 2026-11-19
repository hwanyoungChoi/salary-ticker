import AppKit
import SwiftUI

/// 메뉴바 숫자를 누르면 열리는 패널(P7). 옆 사람에게 연봉이 보이지 않도록 연봉·비과세 입력,
/// 세후 금액, 근무 시간표는 "설정" 아래에 접어 두고, 접힌 상태에서는 금액 없는 안내 문구와 종료만 보인다.
struct PanelView: View {
  let model: TickerModel

  /// 펼침은 저장하지 않는다. 패널을 닫으면 다시 접혀, 열 때마다 접힌 상태로 시작한다.
  @State private var isSettingsExpanded: Bool

  /// `isSettingsExpanded`는 펼친 패널을 그려 보는 테스트(스크린샷 포함)만 넘긴다. 앱은 접힌 채 시작한다.
  init(model: TickerModel, isSettingsExpanded: Bool = false) {
    self.model = model
    _isSettingsExpanded = State(initialValue: isSettingsExpanded)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      DisclosureGroup("설정", isExpanded: $isSettingsExpanded) {
        settings
      }
      if !isSettingsExpanded, let setupNotice = model.setupNotice {
        Text(setupNotice)
      }
      Divider()
      Button("종료") { NSApplication.shared.terminate(nil) }
        .keyboardShortcut("q")
    }
    .padding()
    .frame(width: 260)
    // 번들 없는 `swift run` 실행에서도 펼친 입력칸이 키보드 포커스를 받도록 앱을 앞으로 올린다.
    // 열 때는 설정이 접혀 있어 입력칸이 없으므로, 키 입력이 연봉 칸으로 들어가지 않는다.
    .onAppear { NSApp.activate() }
    .onDisappear { isSettingsExpanded = false }
  }

  private var settings: some View {
    VStack(alignment: .leading, spacing: 10) {
      AmountField(
        title: "연봉 (원)", placeholder: "예: 52,000,000",
        errorMessage: "숫자와 쉼표만, 1조(1,000,000,000,000) 이하로 입력하세요",
        storedValue: model.annualSalary, submit: model.submitAnnualSalary)
      AmountField(
        title: "연간 비과세 (원)", placeholder: "예: 2,400,000",
        errorMessage: "숫자와 쉼표만, 1조 이하로 입력하세요",
        storedValue: model.annualTaxFree, submit: model.submitAnnualTaxFree)
      VStack(alignment: .leading, spacing: 2) {
        if let monthlyTakeHomeText = model.monthlyTakeHomeText {
          Text(monthlyTakeHomeText)
            .monospacedDigit()
        }
        Text(model.perSecondText)
          .monospacedDigit()
        Text(TakeHomePay.basisText)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Divider()
      ScheduleSection(model: model)
    }
    .padding(.top, 6)
  }
}
