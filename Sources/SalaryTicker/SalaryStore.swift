import Foundation

/// 기기 내 저장(ADR 002). 테스트는 `UserDefaults(suiteName:)`를 주입한다.
struct SalaryStore {
  static let annualSalaryKey = "annualSalary"

  let defaults: UserDefaults

  /// 저장된 연봉. 없거나 규칙(P8) 밖의 값이면 nil(미입력).
  var annualSalary: Int? {
    let value = defaults.integer(forKey: Self.annualSalaryKey)
    return AnnualSalary.isValid(value) ? value : nil
  }

  func saveAnnualSalary(_ value: Int) {
    defaults.set(value, forKey: Self.annualSalaryKey)
  }
}
