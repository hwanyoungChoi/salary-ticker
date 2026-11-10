/// 근무 시간표. 요일은 `Calendar` weekday(1=일 … 7=토), 시각은 자정부터의 분.
struct WorkSchedule {
  let weekdays: Set<Int>
  let startMinutes: Int
  let endMinutes: Int

  /// P2: 월~금 09:30~18:30. 태스크 1은 이 상수만 쓴다.
  static let standard = WorkSchedule(
    weekdays: [2, 3, 4, 5, 6], startMinutes: 570, endMinutes: 1110)

  /// 하루 근무 초. 퇴근이 출근보다 이르면 0.
  var dailySeconds: Int { max(0, endMinutes - startMinutes) * 60 }

  /// P3 분모: 52주 × 주 근무일수 × 하루 근무 초.
  var annualSeconds: Int { 52 * weekdays.count * dailySeconds }
}
