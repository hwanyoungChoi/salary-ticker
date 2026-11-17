import Foundation

/// 연봉 + 시간표 + 현재 시각 → 오늘 번 돈, 초당 금액.
/// 그 달 월급(연봉 ÷ 12)을 그 달 근무 초(근무일 수 × 점심 뺀 하루 근무 초)에 고르게 나눈다.
enum SalaryCalculator {
  /// 오늘 출근 시각부터 `now`까지 번 돈(원, 버림). 근무 요일이 아니거나 연봉이 무효면 0.
  /// 점심시간에는 멈추고, 퇴근 뒤 자정까지는 일급에서 멈춘다.
  static func earnedToday(
    annualSalary: Int, schedule: WorkSchedule, at now: Date, calendar: Calendar
  ) -> Int {
    let monthlySeconds = monthlySeconds(schedule: schedule, at: now, calendar: calendar)
    guard AnnualSalary.isValid(annualSalary), monthlySeconds > 0,
      schedule.weekdays.contains(calendar.component(.weekday, from: now))
    else { return 0 }

    let secondOfDay = Int(now.timeIntervalSince(calendar.startOfDay(for: now)).rounded(.down))
    let workedSeconds = schedule.workedSeconds(untilSecondOfDay: secondOfDay)
    // 곱셈 먼저, 나눗셈 나중. 연봉 상한(1조) × 하루 최대 86,340초는 Int64 안이다.
    return annualSalary * workedSeconds / (12 * monthlySeconds)
  }

  /// 초당 금액(원). 연봉이 무효이거나 그 달 근무 초가 0이면 0.
  static func perSecond(
    annualSalary: Int, schedule: WorkSchedule, at now: Date, calendar: Calendar
  ) -> Double {
    let monthlySeconds = monthlySeconds(schedule: schedule, at: now, calendar: calendar)
    guard AnnualSalary.isValid(annualSalary), monthlySeconds > 0 else { return 0 }
    return Double(annualSalary) / Double(12 * monthlySeconds)
  }

  /// `now`가 속한 달의 근무 초. 무효한 시간표면 0.
  private static func monthlySeconds(
    schedule: WorkSchedule, at now: Date, calendar: Calendar
  ) -> Int {
    guard schedule.isValid else { return 0 }
    return schedule.workdays(inMonthOf: now, calendar: calendar) * schedule.dailySeconds
  }
}
