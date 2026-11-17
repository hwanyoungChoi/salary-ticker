import Foundation

/// 근무 시간표. 요일은 `Calendar` weekday(1=일 … 7=토), 시각은 자정부터의 분.
/// 점심시간에는 돈이 쌓이지 않는다. 점심 시작과 끝이 같으면 점심시간이 없다.
struct WorkSchedule: Equatable {
  var weekdays: Set<Int>
  var startMinutes: Int
  var endMinutes: Int
  var lunchStartMinutes: Int
  var lunchEndMinutes: Int

  /// 기본값: 월~금 09:30~18:30, 점심 12:00~13:00.
  static let standard = WorkSchedule(
    weekdays: [2, 3, 4, 5, 6], startMinutes: 570, endMinutes: 1110,
    lunchStartMinutes: 720, lunchEndMinutes: 780)

  /// 하루 안의 시각(00:00~23:59). 야간 근무(퇴근이 다음 날)는 범위 밖이다.
  static let minutesOfDay = 0...1439

  /// 저장·계산에 쓸 수 있는 시간표인가. 요일이 비어 있는 것은 허용한다(P11).
  var isValid: Bool {
    weekdays.allSatisfy((1...7).contains) && Self.minutesOfDay.contains(startMinutes)
      && Self.minutesOfDay.contains(endMinutes) && startMinutes < endMinutes && isLunchValid
  }

  /// 점심시간은 출근과 퇴근 사이에 있고, 근무 시간 전체를 덮지 않는다.
  var isLunchValid: Bool {
    startMinutes <= lunchStartMinutes && lunchStartMinutes <= lunchEndMinutes
      && lunchEndMinutes <= endMinutes && dailySeconds > 0
  }

  /// 하루 근무 초(점심 제외).
  var dailySeconds: Int {
    ((endMinutes - startMinutes) - (lunchEndMinutes - lunchStartMinutes)) * 60
  }

  /// 자정부터 `secondOfDay`초까지 일한 초(점심 제외). 출근 전 0, 퇴근 뒤 하루 근무 초.
  func workedSeconds(untilSecondOfDay secondOfDay: Int) -> Int {
    func elapsed(from start: Int, to end: Int) -> Int {
      min(max(secondOfDay, start * 60), end * 60) - start * 60
    }
    return elapsed(from: startMinutes, to: endMinutes)
      - elapsed(from: lunchStartMinutes, to: lunchEndMinutes)
  }

  /// `date`가 속한 달(1일~말일)의 근무 요일 수.
  func workdays(inMonthOf date: Date, calendar: Calendar) -> Int {
    guard let month = calendar.dateInterval(of: .month, for: date),
      let days = calendar.range(of: .day, in: .month, for: date)
    else { return 0 }
    return days.count(where: { day in
      guard let date = calendar.date(byAdding: .day, value: day - 1, to: month.start) else {
        return false
      }
      return weekdays.contains(calendar.component(.weekday, from: date))
    })
  }
}
