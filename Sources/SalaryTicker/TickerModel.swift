import Foundation
import Observation

/// 메뉴바와 패널이 함께 보는 상태. 값은 매초 현재 시각으로 다시 계산한다(누적하지 않음).
/// 연봉·시간표가 바뀌면 이를 읽는 화면이 바로 다시 그린다.
@MainActor
@Observable
final class TickerModel {
  private(set) var annualSalary: Int?
  private(set) var schedule: WorkSchedule
  private(set) var now: Date

  @ObservationIgnored private let store: SalaryStore
  @ObservationIgnored private let calendar: Calendar
  @ObservationIgnored private var tickTask: Task<Void, Never>?

  init(store: SalaryStore, calendar: Calendar, now: Date = Date()) {
    self.store = store
    self.calendar = calendar
    self.now = now
    annualSalary = store.annualSalary
    schedule = store.schedule
  }

  var earnedToday: Int {
    SalaryCalculator.earnedToday(
      annualSalary: annualSalary ?? 0, schedule: schedule, at: now, calendar: calendar)
  }

  /// 패널의 초당 금액 자리(P10, P11). 둘 다 비어 있으면 연봉 미입력을 먼저 알린다.
  var perSecondText: String {
    guard let annualSalary else { return "연봉을 입력하세요" }
    guard !schedule.weekdays.isEmpty else { return "근무 요일을 선택하세요" }
    return MoneyFormat.perSecond(
      SalaryCalculator.perSecond(annualSalary: annualSalary, schedule: schedule))
  }

  /// 시계의 다음 정각 초마다 `now`를 갱신한다. 1초 고정 간격은 조금씩 밀려 가끔 표시 초를
  /// 건너뛰므로 매번 남은 소수 초만큼만 잔다. `Task.sleep`은 연속 시계라 잠자기에서 깨면 바로 다시 계산된다.
  func startTicking() {
    guard tickTask == nil else { return }
    tickTask = Task { [weak self] in
      while !Task.isCancelled {
        let fraction = Date().timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1)
        try? await Task.sleep(for: .seconds(1 - fraction))
        guard let self else { return }
        self.now = Date()
      }
    }
  }

  /// 유효한 입력만 저장하고 true를 돌려준다. 무효면 저장된 이전 연봉을 그대로 둔다.
  func submitAnnualSalary(_ text: String) -> Bool {
    guard let value = AnnualSalary.parse(text) else { return false }
    store.saveAnnualSalary(value)
    annualSalary = value
    return true
  }

  /// 유효한 시간표(AC-8)만 저장하고 true를 돌려준다. 무효면 저장된 이전 시간표를 그대로 둔다.
  func submitSchedule(_ next: WorkSchedule) -> Bool {
    guard next.isValid else { return false }
    store.saveSchedule(next)
    schedule = next
    return true
  }
}
