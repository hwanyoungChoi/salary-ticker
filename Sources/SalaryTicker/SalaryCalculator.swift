import Foundation

/// 연봉 + 시간표 + 현재 시각 → 오늘 번 돈, 초당 금액(P3, P4, P5).
enum SalaryCalculator {
  /// 오늘 출근 시각부터 `now`까지 번 돈(원, 버림). 근무 요일이 아니거나 연봉이 무효면 0.
  /// 퇴근 뒤 자정까지는 일급에서 멈춘다.
  static func earnedToday(
    annualSalary: Int, schedule: WorkSchedule, at now: Date, calendar: Calendar
  ) -> Int {
    let annualSeconds = schedule.annualSeconds
    guard AnnualSalary.isValid(annualSalary), annualSeconds > 0,
      schedule.weekdays.contains(calendar.component(.weekday, from: now)),
      let start = calendar.date(
        bySettingHour: schedule.startMinutes / 60, minute: schedule.startMinutes % 60, second: 0,
        of: now)
    else { return 0 }

    let elapsed = Int(now.timeIntervalSince(start).rounded(.down))
    let workedSeconds = min(max(elapsed, 0), schedule.dailySeconds)
    // 곱셈 먼저, 나눗셈 나중. 연봉 상한(1조) × 하루 최대 86,400초는 Int64 안이다.
    return annualSalary * workedSeconds / annualSeconds
  }

  /// 초당 금액(원). 연봉이 무효이거나 근무 초가 0이면 0.
  static func perSecond(annualSalary: Int, schedule: WorkSchedule) -> Double {
    let annualSeconds = schedule.annualSeconds
    guard AnnualSalary.isValid(annualSalary), annualSeconds > 0 else { return 0 }
    return Double(annualSalary) / Double(annualSeconds)
  }
}
