/// 근무 시간표. 요일은 `Calendar` weekday(1=일 … 7=토), 시각은 자정부터의 분.
struct WorkSchedule: Equatable {
  var weekdays: Set<Int>
  var startMinutes: Int
  var endMinutes: Int

  /// P2 기본값: 월~금 09:30~18:30.
  static let standard = WorkSchedule(
    weekdays: [2, 3, 4, 5, 6], startMinutes: 570, endMinutes: 1110)

  /// 하루 안의 시각(00:00~23:59). 야간 근무(퇴근이 다음 날)는 범위 밖이다.
  static let minutesOfDay = 0...1439

  /// 저장·계산에 쓸 수 있는 시간표인가(AC-8). 요일이 비어 있는 것은 허용한다(P11).
  var isValid: Bool {
    weekdays.allSatisfy((1...7).contains) && Self.minutesOfDay.contains(startMinutes)
      && Self.minutesOfDay.contains(endMinutes) && startMinutes < endMinutes
  }

  /// 하루 근무 초. 퇴근이 출근보다 이르면 0.
  var dailySeconds: Int { max(0, endMinutes - startMinutes) * 60 }

  /// P3 분모: 52주 × 주 근무일수 × 하루 근무 초.
  var annualSeconds: Int { 52 * weekdays.count * dailySeconds }
}
