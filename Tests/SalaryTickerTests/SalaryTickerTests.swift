import Foundation
import Testing

@testable import SalaryTicker

private let seoul: Calendar = {
  var calendar = Calendar(identifier: .gregorian)
  calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
  return calendar
}()

private let salary = 52_000_000

/// 2026-11-{day} hh:mm:ss (Asia/Seoul). 9일은 월요일, 14일은 토요일.
private func date(day: Int, _ hour: Int, _ minute: Int, _ second: Int) -> Date {
  seoul.date(
    from: DateComponents(
      year: 2026, month: 11, day: day, hour: hour, minute: minute, second: second)
  )!
}

private func earned(at date: Date, annualSalary: Int = salary) -> Int {
  SalaryCalculator.earnedToday(
    annualSalary: annualSalary, schedule: .standard, at: date, calendar: seoul)
}

@Suite("AC-2 오늘 번 돈")
struct EarnedTodayTests {
  @Test(
    "월요일 시각별 기대값",
    arguments: [
      (9, 29, 59, 0), (9, 30, 0, 0), (9, 30, 1, 6), (9, 30, 3, 18), (9, 30, 4, 24),
      (12, 30, 0, 66_666), (14, 0, 0, 100_000), (18, 29, 59, 199_993), (18, 30, 0, 200_000),
      (23, 59, 59, 200_000),
    ])
  func monday(hour: Int, minute: Int, second: Int, expected: Int) {
    #expect(earned(at: date(day: 9, hour, minute, second)) == expected)
  }

  @Test func saturdayIsZero() {
    #expect(earned(at: date(day: 14, 12, 0, 0)) == 0)
  }

  @Test func nextDayResetsAtMidnight() {
    #expect(earned(at: date(day: 10, 0, 0, 0)) == 0)
  }

  @Test func perSecondIsAbout6Point17() {
    let perSecond = SalaryCalculator.perSecond(annualSalary: salary, schedule: .standard)
    #expect(abs(perSecond - 6.1728) < 0.0001)
    #expect(MoneyFormat.perSecond(perSecond) == "초당 6.2원")
  }
}

@Suite("AC-3 버림과 단조 증가")
struct MonotonicTests {
  @Test func neverDecreasesDuringWorkHours() {
    let start = date(day: 9, 9, 30, 0)
    var previous = 0
    for second in 0...32_400 {
      let value = earned(at: start.addingTimeInterval(TimeInterval(second)))
      #expect(value >= previous, "\(second)초에서 감소")
      previous = value
    }
    #expect(previous == 200_000)
  }

  @Test func fractionalSecondsRoundDown() {
    #expect(earned(at: date(day: 9, 9, 30, 0).addingTimeInterval(0.9)) == 0)
    #expect(earned(at: date(day: 9, 9, 30, 3).addingTimeInterval(0.9)) == 18)
  }
}

@Suite("AC-5 연봉 파싱과 오버플로")
struct AnnualSalaryTests {
  @Test(
    "유효한 입력",
    arguments: [
      ("52,000,000", 52_000_000), (" 52000000 ", 52_000_000), ("0052", 52),
      ("1,000,000,000,000", 1_000_000_000_000),
    ])
  func valid(text: String, expected: Int) {
    #expect(AnnualSalary.parse(text) == expected)
  }

  @Test(
    "무효한 입력",
    arguments: [
      "", "   ", ",", "0", "abc", "-1", "+52", "52.5", "1e7", "５２", "52만",
      "1,000,000,000,001", "9223372036854775807", "99999999999999999999",
    ])
  func invalid(text: String) {
    #expect(AnnualSalary.parse(text) == nil)
  }

  @Test func outOfRangeSalaryEarnsZeroWithoutTrap() {
    #expect(earned(at: date(day: 9, 18, 30, 0), annualSalary: Int.max) == 0)
    #expect(earned(at: date(day: 9, 18, 30, 0), annualSalary: -1) == 0)
  }

  @Test func maximumSalaryDoesNotOverflow() {
    #expect(
      earned(at: date(day: 9, 18, 30, 0), annualSalary: AnnualSalary.maximum) == 3_846_153_846)
  }

  @Test func noWorkdaysEarnsZero() {
    let schedule = WorkSchedule(weekdays: [], startMinutes: 570, endMinutes: 1110)
    #expect(
      SalaryCalculator.earnedToday(
        annualSalary: salary, schedule: schedule, at: date(day: 9, 12, 0, 0), calendar: seoul) == 0)
    #expect(SalaryCalculator.perSecond(annualSalary: salary, schedule: schedule) == 0)
  }
}

@Suite("AC-4 저장")
@MainActor
struct StoreTests {
  @Test func savedSalarySurvivesNewInstance() {
    let (defaults, suiteName) = makeDefaults()
    defer { defaults.removePersistentDomain(forName: suiteName) }

    #expect(
      TickerModel(store: SalaryStore(defaults: defaults), calendar: seoul).annualSalary == nil)
    #expect(
      TickerModel(store: SalaryStore(defaults: defaults), calendar: seoul).submitAnnualSalary(
        "52,000,000"))

    let reopened = TickerModel(
      store: SalaryStore(defaults: defaults), calendar: seoul, now: date(day: 9, 14, 0, 0))
    #expect(defaults.integer(forKey: "annualSalary") == 52_000_000)
    #expect(reopened.annualSalary == 52_000_000)
    #expect(reopened.earnedToday == 100_000)
  }

  @Test func invalidInputKeepsPreviousSalary() {
    let (defaults, suiteName) = makeDefaults()
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let model = TickerModel(store: SalaryStore(defaults: defaults), calendar: seoul)
    _ = model.submitAnnualSalary("52000000")

    for text in ["abc", "0", "-1", "9223372036854775807"] {
      #expect(!model.submitAnnualSalary(text))
    }
    #expect(model.annualSalary == 52_000_000)
    #expect(SalaryStore(defaults: defaults).annualSalary == 52_000_000)
  }

  @Test func outOfRangeStoredValueReadsAsUnset() {
    let (defaults, suiteName) = makeDefaults()
    defer { defaults.removePersistentDomain(forName: suiteName) }
    defaults.set(Int.max, forKey: "annualSalary")
    #expect(SalaryStore(defaults: defaults).annualSalary == nil)
  }

  private func makeDefaults() -> (UserDefaults, String) {
    let suiteName = "SalaryTickerTests.\(UUID().uuidString)"
    return (UserDefaults(suiteName: suiteName)!, suiteName)
  }
}

@Suite("P6 표시 형식")
struct MoneyFormatTests {
  @Test(
    arguments: [
      (0, "0"), (999, "999"), (1_000, "1,000"), (200_000, "200,000"), (1_234_567, "1,234,567"),
    ])
  func amount(value: Int, expected: String) {
    #expect(MoneyFormat.amount(value) == expected)
  }
}
