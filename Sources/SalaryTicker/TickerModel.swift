import Foundation
import Observation

/// 메뉴바와 패널이 함께 보는 상태. 값은 매초 현재 시각으로 다시 계산한다(누적하지 않음).
@MainActor
@Observable
final class TickerModel {
  private(set) var annualSalary: Int?
  private(set) var now: Date

  @ObservationIgnored private let store: SalaryStore
  @ObservationIgnored private let calendar: Calendar
  @ObservationIgnored private let schedule = WorkSchedule.standard
  @ObservationIgnored private var tickTask: Task<Void, Never>?

  init(store: SalaryStore, calendar: Calendar, now: Date = Date()) {
    self.store = store
    self.calendar = calendar
    self.now = now
    annualSalary = store.annualSalary
  }

  var earnedToday: Int {
    SalaryCalculator.earnedToday(
      annualSalary: annualSalary ?? 0, schedule: schedule, at: now, calendar: calendar)
  }

  var perSecond: Double {
    SalaryCalculator.perSecond(annualSalary: annualSalary ?? 0, schedule: schedule)
  }

  /// 1초마다 `now`를 갱신한다. `Task.sleep`은 연속 시계라 잠자기에서 깨면 바로 다시 계산된다.
  func startTicking() {
    guard tickTask == nil else { return }
    tickTask = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1))
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
    now = Date()
    return true
  }
}
