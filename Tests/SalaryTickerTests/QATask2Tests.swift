import Foundation
import Testing

@testable import SalaryTicker

private let seoul: Calendar = {
  var calendar = Calendar(identifier: .gregorian)
  calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
  return calendar
}()

@Suite("AC-7 저장 형식 경계 (qa)")
struct ScheduleStorageQATests {
  /// 키 중 어느 하나가 빠져도 시간표 전체를 기본값으로 읽는다(키마다 기본값을 섞지 않음).
  /// 나머지 키는 기본값과 다른 유효 값이라, 키별 기본값을 섞으면 `.standard`와 달라진다.
  @Test(
    "키 하나가 빠지면 기본 시간표",
    arguments: [
      "workWeekdays", "workStartMinutes", "workEndMinutes", "lunchStartMinutes",
      "lunchEndMinutes",
    ])
  func missingKeyReadsAsStandard(missingKey: String) {
    let suiteName = "SalaryTickerQATask2Tests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let stored: [String: Any] = [
      "workWeekdays": [1, 7], "workStartMinutes": 600, "workEndMinutes": 1200,
      "lunchStartMinutes": 690, "lunchEndMinutes": 750,
    ]
    for (key, value) in stored where key != missingKey {
      defaults.set(value, forKey: key)
    }
    #expect(SalaryStore(defaults: defaults).schedule == .standard)
  }
}

@Suite("AC-7 바뀐 시간표의 정수 연산 (qa)")
struct ScheduleMoneyQATests {
  /// 하루 근무 초의 최댓값은 86,340초(00:00~23:59, 점심 없음)다. 연봉 상한 1조 × 86,340초도
  /// Int64 안이다. 매일 근무면 11월은 30일이라 퇴근 시각에 일급(1조 ÷ 12 ÷ 30, 버림)이 나온다.
  @Test func widestScheduleAtMaximumSalaryDoesNotOverflow() {
    let schedule = WorkSchedule(
      weekdays: Set(1...7), startMinutes: 0, endMinutes: 1439, lunchStartMinutes: 0,
      lunchEndMinutes: 0)
    let endOfDay = seoul.date(
      from: DateComponents(year: 2026, month: 11, day: 14, hour: 23, minute: 59, second: 59))!
    #expect(
      SalaryCalculator.earnedToday(
        annualSalary: AnnualSalary.maximum, schedule: schedule, at: endOfDay, calendar: seoul)
        == 2_777_777_777)
  }
}
