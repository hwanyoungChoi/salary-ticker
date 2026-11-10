import SwiftUI

/// 메뉴바에 보이는 오늘 번 돈. 숫자만 표시한다(단위 없음). 폭 흔들림을 줄이려 고정폭 숫자를 요청한다.
struct MenuBarLabel: View {
  let model: TickerModel

  var body: some View {
    Text(MoneyFormat.amount(model.earnedToday))
      .monospacedDigit()
  }
}
