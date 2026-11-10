/// 연봉 입력 규칙(P8). 원 단위 정수, 1 이상 1조 이하만 유효하다.
enum AnnualSalary {
  static let maximum = 1_000_000_000_000

  static func isValid(_ value: Int) -> Bool {
    (1...maximum).contains(value)
  }

  /// 앞뒤 공백과 쉼표를 허용한다. 소수점·지수·전각 숫자·부호·문자, 0, 상한 초과는 nil.
  static func parse(_ text: String) -> Int? {
    let digits = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "")
    guard !digits.isEmpty, digits.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
    guard let value = Int(digits), isValid(value) else { return nil }
    return value
  }
}
