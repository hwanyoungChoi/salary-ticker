import SwiftUI

/// 패널의 금액 입력칸. Enter를 누르거나 포커스가 빠지면 저장하고, 무효면 오류 문구를 보인다.
/// 사라질 때(설정 접기·패널 닫기) 입력 중인 값을 한 번 반영해 보고, 무효면 저장값으로 되돌린다.
/// 저장값과 같은 글자는 다시 저장하지 않는다.
struct AmountField: View {
  let title: String
  let placeholder: String
  let errorMessage: String
  let storedValue: Int?
  let submit: (String) -> Bool

  @State private var text = ""
  @State private var hasError = false
  @FocusState private var isFocused: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.headline)
      TextField(placeholder, text: $text)
        .textFieldStyle(.roundedBorder)
        .focused($isFocused)
        .onSubmit(commit)
      if hasError {
        Text(errorMessage)
          .font(.caption)
          .foregroundStyle(.red)
      }
    }
    .onAppear(perform: showStored)
    .onDisappear {
      commit()
      showStored()
    }
    .onChange(of: isFocused) { _, isFocused in
      if !isFocused { commit() }
    }
  }

  private func commit() {
    let trimmed = text.trimmingCharacters(in: .whitespaces)
    if trimmed == storedText {
      hasError = false
    } else if submit(trimmed) {
      showStored()
    } else {
      hasError = true
    }
  }

  private func showStored() {
    text = storedText
    hasError = false
  }

  private var storedText: String {
    storedValue.map(MoneyFormat.amount) ?? ""
  }
}
