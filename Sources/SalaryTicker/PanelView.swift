import AppKit
import SwiftUI

/// 메뉴바 숫자를 누르면 열리는 패널(P7). 옆 사람에게 연봉이 보이지 않도록 연봉 입력, 초당 금액,
/// 근무 시간표는 "설정" 아래에 접어 두고, 접힌 상태에서는 금액 없는 안내 문구와 종료만 보인다.
struct PanelView: View {
  let model: TickerModel

  /// 펼침은 저장하지 않는다. 패널을 닫으면 다시 접혀, 열 때마다 접힌 상태로 시작한다.
  @State private var isSettingsExpanded: Bool
  @State private var salaryText = ""
  @State private var hasInputError = false
  @FocusState private var isSalaryFocused: Bool

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
    .onAppear(perform: handleAppear)
    .onDisappear(perform: handleDisappear)
    .onChange(of: isSalaryFocused) { _, isFocused in
      if !isFocused { commitSalary() }
    }
    .onChange(of: isSettingsExpanded) { _, isExpanded in
      if !isExpanded { finishSalaryEditing() }
    }
  }

  private var settings: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("연봉 (원)")
        .font(.headline)
      TextField("예: 52,000,000", text: $salaryText)
        .textFieldStyle(.roundedBorder)
        .focused($isSalaryFocused)
        .onSubmit(commitSalary)
      if hasInputError {
        Text("숫자와 쉼표만, 1조(1,000,000,000,000) 이하로 입력하세요")
          .font(.caption)
          .foregroundStyle(.red)
      }
      Text(model.perSecondText)
        .monospacedDigit()
      Divider()
      ScheduleSection(model: model)
    }
    .padding(.top, 6)
  }

  /// 번들 없는 `swift run` 실행에서도 펼친 입력칸이 키보드 포커스를 받도록 앱을 앞으로 올린다.
  /// 열 때는 설정이 접혀 있어 입력칸이 없으므로, 키 입력이 연봉 칸으로 들어가지 않는다.
  private func handleAppear() {
    NSApp.activate()
    showStoredSalary()
  }

  private func handleDisappear() {
    finishSalaryEditing()
    isSettingsExpanded = false
  }

  /// 패널을 닫거나 설정을 접으면 입력 중인 값을 한 번 반영해 보고, 무효면 저장값으로 되돌린다.
  private func finishSalaryEditing() {
    commitSalary()
    showStoredSalary()
  }

  private func commitSalary() {
    if model.submitAnnualSalary(salaryText) {
      showStoredSalary()
    } else {
      hasInputError = salaryText.trimmingCharacters(in: .whitespaces) != storedSalaryText
    }
  }

  private func showStoredSalary() {
    salaryText = storedSalaryText
    hasInputError = false
  }

  private var storedSalaryText: String {
    model.annualSalary.map(MoneyFormat.amount) ?? ""
  }
}
