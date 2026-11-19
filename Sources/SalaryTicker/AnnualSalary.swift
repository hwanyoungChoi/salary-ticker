/// 금액 입력 규칙(P8). 원 단위 정수, 1조 이하만 유효하다. 연봉은 1 이상, 비과세는 0도 된다.
enum AnnualSalary {
  static let maximum = 1_000_000_000_000

  static func isValid(_ value: Int) -> Bool {
    (1...maximum).contains(value)
  }

  /// 연봉. 0이나 빈 값은 nil.
  static func parse(_ text: String) -> Int? {
    parseAmount(text).flatMap { $0 > 0 ? $0 : nil }
  }

  /// 0 이상 1조 이하 금액. 앞뒤 공백과 쉼표를 허용한다.
  /// 소수점·지수·전각 숫자·부호·문자, 상한 초과는 nil.
  static func parseAmount(_ text: String) -> Int? {
    let digits = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "")
    guard !digits.isEmpty, digits.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
    guard let value = Int(digits), (0...maximum).contains(value) else { return nil }
    return value
  }
}
