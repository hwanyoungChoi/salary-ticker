import AppKit
import SwiftUI

/// 메뉴바 숫자를 누르면 열리는 패널(P7): 연봉 입력, 초당 금액, 근무 시간표, 종료.
struct PanelView: View {
  let model: TickerModel

  @State private var salaryText = ""
  @State private var hasInputError = false
  @FocusState private var isSalaryFocused: Bool

  var body: some View {
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
  }

  /// 번들 없는 `swift run` 실행에서도 입력칸이 키보드 포커스를 받도록 앱을 앞으로 올린다.
  private func handleAppear() {
    NSApp.activate()
    showStoredSalary()
  }

  /// 패널을 닫으면 입력 중인 값을 한 번 반영해 보고, 무효면 다음에 열 때 저장값을 다시 보여준다.
  private func handleDisappear() {
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
