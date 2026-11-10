import Foundation

/// 기기 내 저장(ADR 002). 테스트는 `UserDefaults(suiteName:)`를 주입한다.
struct SalaryStore {
  static let annualSalaryKey = "annualSalary"
  static let workWeekdaysKey = "workWeekdays"
  static let workStartMinutesKey = "workStartMinutes"
  static let workEndMinutesKey = "workEndMinutes"

  let defaults: UserDefaults

  /// 저장된 연봉. 없거나 규칙(P8) 밖의 값이면 nil(미입력).
  var annualSalary: Int? {
    let value = defaults.integer(forKey: Self.annualSalaryKey)
    return AnnualSalary.isValid(value) ? value : nil
  }

  func saveAnnualSalary(_ value: Int) {
    defaults.set(value, forKey: Self.annualSalaryKey)
  }

  /// 저장된 시간표. 세 키 중 하나라도 없거나, 타입이 다르거나, 규칙(AC-8) 밖이면 기본값(P2).
  /// 키마다 따로 기본값을 섞지 않는다(저장은 항상 세 키를 함께 한다).
  var schedule: WorkSchedule {
    guard let weekdays = defaults.array(forKey: Self.workWeekdaysKey) as? [Int],
      let start = defaults.object(forKey: Self.workStartMinutesKey) as? Int,
      let end = defaults.object(forKey: Self.workEndMinutesKey) as? Int
    else { return .standard }
    let stored = WorkSchedule(weekdays: Set(weekdays), startMinutes: start, endMinutes: end)
    return stored.isValid ? stored : .standard
  }

  /// 요일은 정렬한 정수 배열(property list 배열)로 저장한다. 빈 배열도 그대로 저장한다(P11).
  func saveSchedule(_ schedule: WorkSchedule) {
    defaults.set(schedule.weekdays.sorted(), forKey: Self.workWeekdaysKey)
    defaults.set(schedule.startMinutes, forKey: Self.workStartMinutesKey)
    defaults.set(schedule.endMinutes, forKey: Self.workEndMinutesKey)
  }
}
