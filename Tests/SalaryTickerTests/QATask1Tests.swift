import Foundation
import Testing

@testable import SalaryTicker

private let seoul: Calendar = {
  var calendar = Calendar(identifier: .gregorian)
  calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
  return calendar
}()

/// 2026-11-09(월) hh:mm:ss (Asia/Seoul).
private func monday(_ hour: Int, _ minute: Int, _ second: Int) -> Date {
  seoul.date(
    from: DateComponents(year: 2026, month: 11, day: 9, hour: hour, minute: minute, second: second)
  )!
}

@Suite("AC-3 정수 연산 (qa)")
struct IntegerMoneyTests {
  /// 45,000,000 × 351 / 8,424,000 = 정확히 1,875.
  /// 초당 금액을 Double로 먼저 구해 곱하면 1,874.999…로 1원 모자란다(ADR-003).
  @Test func exactBoundaryIsNotOneWonShort() {
    #expect(
      SalaryCalculator.earnedToday(
        annualSalary: 45_000_000, schedule: .standard, at: monday(9, 35, 51), calendar: seoul)
        == 1_875)
  }
}

@Suite("AC-1 메뉴바 라벨 (qa)")
@MainActor
struct MenuBarLabelTests {
  @Test func labelIsDigitsAndCommasOnly() {
    let suiteName = "SalaryTickerQATests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    // P9: 미입력이면 근무시간 중에도 "0".
    let model = TickerModel(
      store: SalaryStore(defaults: defaults), calendar: seoul, now: monday(12, 30, 0))
    #expect(MoneyFormat.amount(model.earnedToday) == "0")

    // 저장된 연봉으로 같은 시각을 다시 열면 숫자와 쉼표만 나온다.
    #expect(model.submitAnnualSalary("52,000,000"))
    let reopened = TickerModel(
      store: SalaryStore(defaults: defaults), calendar: seoul, now: monday(12, 30, 0))
    let label = MoneyFormat.amount(reopened.earnedToday)
    #expect(label == "66,666")
    #expect(label.allSatisfy { $0.isASCII && ($0.isNumber || $0 == ",") })
  }
}
