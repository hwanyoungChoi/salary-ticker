import SwiftUI

/// 패널에 그리는 요일 순서(월~일)와 이름. 값은 `Calendar` weekday(1=일 … 7=토).
private let weekdayItems: [(weekday: Int, label: String)] = [
  (2, "월"), (3, "화"), (4, "수"), (5, "목"), (6, "금"), (7, "토"), (1, "일"),
]

/// 패널의 근무 시간표 설정: 요일 토글 7개, 출근·퇴근 시각, 점심 시작·끝 시각.
/// 요일은 누르는 즉시 저장한다(모두 꺼도 저장, P11). 시각은 고르는 동안 로컬 값으로 두고
/// 유효할 때만 저장한다. 무효면 이유를 보이고 저장된 이전 시간표로 계속 센다(AC-8).
struct ScheduleSection: View {
  let model: TickerModel

  @Environment(\.calendar) private var calendar
  @State private var startMinutes: Int
  @State private var endMinutes: Int
  @State private var lunchStartMinutes: Int
  @State private var lunchEndMinutes: Int
  @State private var hoursError: String?

  init(model: TickerModel) {
    self.model = model
    _startMinutes = State(initialValue: model.schedule.startMinutes)
    _endMinutes = State(initialValue: model.schedule.endMinutes)
    _lunchStartMinutes = State(initialValue: model.schedule.lunchStartMinutes)
    _lunchEndMinutes = State(initialValue: model.schedule.lunchEndMinutes)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("근무 요일")
        .font(.headline)
      HStack(spacing: 4) {
        ForEach(weekdayItems, id: \.weekday) { item in
          Toggle(item.label, isOn: workdayBinding(item.weekday))
            .toggleStyle(.button)
        }
      }
      DatePicker(
        "출근", selection: clockBinding($startMinutes), displayedComponents: .hourAndMinute)
      DatePicker(
        "퇴근", selection: clockBinding($endMinutes), displayedComponents: .hourAndMinute)
      DatePicker(
        "점심 시작", selection: clockBinding($lunchStartMinutes),
        displayedComponents: .hourAndMinute)
      DatePicker(
        "점심 끝", selection: clockBinding($lunchEndMinutes), displayedComponents: .hourAndMinute)
      if let hoursError {
        Text(hoursError)
          .font(.caption)
          .foregroundStyle(.red)
      }
    }
    .onChange(of: startMinutes, commitHours)
    .onChange(of: endMinutes, commitHours)
    .onChange(of: lunchStartMinutes, commitHours)
    .onChange(of: lunchEndMinutes, commitHours)
    .onDisappear(perform: showStoredHours)
  }

  private func workdayBinding(_ weekday: Int) -> Binding<Bool> {
    Binding(
      get: { model.schedule.weekdays.contains(weekday) },
      set: { isOn in
        var next = model.schedule
        if isOn {
          next.weekdays.insert(weekday)
        } else {
          next.weekdays.remove(weekday)
        }
        _ = model.submitSchedule(next)
      })
  }

  /// 자정부터의 분 ↔ `DatePicker`가 다루는 오늘 날짜의 시각. 피커와 같은 환경 `Calendar`를 쓴다.
  private func clockBinding(_ minutes: Binding<Int>) -> Binding<Date> {
    Binding(
      get: {
        calendar.date(
          bySettingHour: minutes.wrappedValue / 60, minute: minutes.wrappedValue % 60, second: 0,
          of: Date()) ?? Date()
      },
      set: { date in
        let time = calendar.dateComponents([.hour, .minute], from: date)
        minutes.wrappedValue = (time.hour ?? 0) * 60 + (time.minute ?? 0)
      })
  }

  private func commitHours() {
    var next = model.schedule
    next.startMinutes = startMinutes
    next.endMinutes = endMinutes
    next.lunchStartMinutes = lunchStartMinutes
    next.lunchEndMinutes = lunchEndMinutes
    if model.submitSchedule(next) {
      hoursError = nil
    } else if next.startMinutes >= next.endMinutes {
      hoursError = "퇴근 시각은 출근 시각보다 늦어야 합니다"
    } else {
      hoursError = "점심시간은 출근과 퇴근 사이, 근무 시간보다 짧게 정하세요"
    }
  }

  /// 패널을 닫으면 무효로 남은 시각을 버리고 다음에 열 때 저장값을 보여준다.
  private func showStoredHours() {
    startMinutes = model.schedule.startMinutes
    endMinutes = model.schedule.endMinutes
    lunchStartMinutes = model.schedule.lunchStartMinutes
    lunchEndMinutes = model.schedule.lunchEndMinutes
    hoursError = nil
  }
}
