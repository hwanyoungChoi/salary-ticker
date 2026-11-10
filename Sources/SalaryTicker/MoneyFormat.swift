import Foundation

/// 표시 형식(P6, P10). 기기 언어와 무관하게 쉼표 구분을 쓰도록 로캘을 고정한다.
enum MoneyFormat {
  private static let locale = Locale(identifier: "ko_KR")

  /// 메뉴바 숫자. 천 단위 쉼표, 단위 없음. 입력은 이미 버림한 정수다.
  static func amount(_ value: Int) -> String {
    value.formatted(.number.locale(locale))
  }

  /// 패널의 초당 금액. 예: "초당 6.2원".
  static func perSecond(_ value: Double) -> String {
    "초당 \(value.formatted(.number.precision(.fractionLength(1)).locale(locale)))원"
  }
}
