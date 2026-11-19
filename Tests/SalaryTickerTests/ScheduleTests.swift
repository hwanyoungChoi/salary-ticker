import Foundation
import Testing

@testable import SalaryTicker

private let seoul: Calendar = {
  var calendar = Calendar(identifier: .gregorian)
  calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
  return calendar
}()

/// 2026-11-09(월) hh:mm (Asia/Seoul).
private func monday(_ hour: Int, _ minute: Int) -> Date {
  seoul.date(from: DateComponents(year: 2026, month: 11, day: 9, hour: hour, minute: minute))!
}

/// 테스트마다 비어 있는 저장소를 쓰고 끝나면 지운다.
@MainActor
private func withDefaults(_ body: (UserDefaults) -> Void) {
  let suiteName = "SalaryTickerScheduleTests.\(UUID().uuidString)"
  let defaults = UserDefaults(suiteName: suiteName)!
  defer { defaults.removePersistentDomain(forName: suiteName) }
  body(defaults)
}

@MainActor
private func makeModel(_ defaults: UserDefaults, now: Date = monday(10, 0)) -> TickerModel {
  TickerModel(store: SalaryStore(defaults: defaults), calendar: seoul, now: now)
}

@Suite("AC-7 시간표 저장과 반영")
@MainActor
struct ScheduleStoreTests {
  @Test func unsetScheduleIsStandard() {
    withDefaults { defaults in
      #expect(makeModel(defaults).schedule == .standard)
    }
  }

  /// 출근을 10:30으로 바꾸면 월요일 10:00에 0. 바꾼 즉시 같은 모델에 반영되고, 다시 열어도 유지된다.
  @Test func laterStartAppliesNowAndAfterRelaunch() {
    withDefaults { defaults in
      let model = makeModel(defaults)
      #expect(model.submitAnnualSalary("52,000,000"))
      #expect(model.earnedToday == 10_862)  // 세후 43,796,920원, 09:30 출근, 1,800초

      var next = model.schedule
      next.startMinutes = 630
      #expect(model.submitSchedule(next))
      #expect(model.earnedToday == 0)

      let reopened = makeModel(defaults)
      #expect(reopened.schedule == next)
      #expect(reopened.earnedToday == 0)
      #expect(defaults.array(forKey: "workWeekdays") as? [Int] == [2, 3, 4, 5, 6])
      #expect(defaults.integer(forKey: "workStartMinutes") == 630)
      #expect(defaults.integer(forKey: "workEndMinutes") == 1110)
      #expect(defaults.integer(forKey: "lunchStartMinutes") == 720)
      #expect(defaults.integer(forKey: "lunchEndMinutes") == 780)
    }
  }

  @Test func weekdaysSurviveRelaunch() {
    withDefaults { defaults in
      let schedule = WorkSchedule(
        weekdays: [1, 7], startMinutes: 0, endMinutes: 1439, lunchStartMinutes: 690,
        lunchEndMinutes: 750)
      #expect(makeModel(defaults).submitSchedule(schedule))
      #expect(makeModel(defaults).schedule == schedule)
    }
  }

  /// 손으로 고친 값 등 규칙 밖 저장값은 기본 시간표로 읽는다(키마다 기본값을 섞지 않음).
  @Test func invalidStoredValueReadsAsStandard() {
    let cases: [(weekdays: Any?, start: Any?, end: Any?, lunchStart: Any?, lunchEnd: Any?)] = [
      ([2, 3], 600, nil, 720, 780),  // 키 하나 없음
      ("2,3,4", 570, 1110, 720, 780),  // 요일이 배열이 아님
      (["월"], 570, 1110, 720, 780),  // 요일이 정수가 아님
      ([0, 2], 570, 1110, 720, 780),  // 요일 범위 밖
      ([2, 8], 570, 1110, 720, 780),
      ([2], "570", 1110, 720, 780),  // 시각이 문자열
      ([2], 570.5, 1110, 720, 780),  // 시각이 소수
      ([2], -1, 1110, 720, 780),  // 시각 범위 밖
      ([2], 570, 1440, 720, 780),
      ([2], 1110, 1110, 720, 780),  // 퇴근 = 출근
      ([2], 1110, 570, 720, 780),  // 퇴근 < 출근
      ([2], 570, 1110, 540, 600),  // 점심이 출근 전에 시작
      ([2], 570, 1110, 1080, 1140),  // 점심이 퇴근 뒤에 끝남
      ([2], 570, 1110, 780, 720),  // 점심 끝 < 점심 시작
      ([2], 570, 1110, 570, 1110),  // 점심이 근무 시간 전체
    ]
    for (index, stored) in cases.enumerated() {
      withDefaults { defaults in
        defaults.set(stored.weekdays, forKey: "workWeekdays")
        defaults.set(stored.start, forKey: "workStartMinutes")
        defaults.set(stored.end, forKey: "workEndMinutes")
        defaults.set(stored.lunchStart, forKey: "lunchStartMinutes")
        defaults.set(stored.lunchEnd, forKey: "lunchEndMinutes")
        #expect(SalaryStore(defaults: defaults).schedule == .standard, "\(index)번 경우")
      }
    }
  }
}

@Suite("AC-8 시간표 검증과 요일 0개")
@MainActor
struct ScheduleValidationTests {
  @Test(
    "무효한 시각은 저장하지 않는다",
    arguments: [(570, 570), (600, 570), (-1, 1110), (570, 1440), (1439, 1439)])
  func invalidHoursKeepPreviousSchedule(start: Int, end: Int) {
    withDefaults { defaults in
      let model = makeModel(defaults)
      var next = model.schedule
      next.startMinutes = start
      next.endMinutes = end
      #expect(!model.submitSchedule(next))
      #expect(model.schedule == .standard)
      #expect(defaults.object(forKey: "workStartMinutes") == nil)
    }
  }

  @Test("1분 차이와 하루 끝값은 허용", arguments: [(570, 571), (0, 1), (1438, 1439), (0, 1439)])
  func boundaryHoursAreSaved(start: Int, end: Int) {
    withDefaults { defaults in
      let model = makeModel(defaults)
      var next = model.schedule
      next.startMinutes = start
      next.endMinutes = end
      next.lunchStartMinutes = start
      next.lunchEndMinutes = start
      #expect(model.submitSchedule(next))
      #expect(SalaryStore(defaults: defaults).schedule == next)
    }
  }

  /// 점심시간은 출근~퇴근 안에서만, 근무 시간 전체를 덮지 않게. 무효면 저장하지 않는다.
  @Test(
    "무효한 점심시간은 저장하지 않는다",
    arguments: [(540, 600), (1080, 1140), (780, 720), (570, 1110)])
  func invalidLunchKeepsPreviousSchedule(lunchStart: Int, lunchEnd: Int) {
    withDefaults { defaults in
      let model = makeModel(defaults)
      var next = model.schedule
      next.lunchStartMinutes = lunchStart
      next.lunchEndMinutes = lunchEnd
      #expect(!model.submitSchedule(next))
      #expect(model.schedule == .standard)
    }
  }

  /// 점심 시작과 끝을 같게 하면 점심 없이 9시간을 센다. 12:30에도 멈추지 않는다.
  @Test func equalLunchTimesMeanNoLunch() {
    withDefaults { defaults in
      let model = makeModel(defaults, now: monday(12, 30))
      #expect(model.submitAnnualSalary("52,000,000"))
      #expect(model.earnedToday == 54_311)  // 점심 12:00부터 멈춤

      var next = model.schedule
      next.lunchStartMinutes = 720
      next.lunchEndMinutes = 720
      #expect(model.submitSchedule(next))
      // 10,800초 × 세후 43,796,920 ÷ (12 × 21일 × 32,400초)
      #expect(model.earnedToday == 57_932)
    }
  }

  /// P11: 요일을 모두 꺼도 저장되고(기본값으로 돌아가지 않음), 메뉴바 0, 패널 안내 문구.
  @Test func noWorkdaysIsSavedAndEarnsZero() {
    withDefaults { defaults in
      let model = makeModel(defaults, now: monday(12, 30))
      #expect(model.submitAnnualSalary("52,000,000"))
      #expect(model.perSecondText == "세후 초당 6.0원")
      #expect(model.setupNotice == nil)

      var next = model.schedule
      next.weekdays = []
      #expect(model.submitSchedule(next))
      #expect(model.earnedToday == 0)
      #expect(model.perSecondText == "근무 요일을 선택하세요")
      #expect(model.setupNotice == "근무 요일을 선택하세요")

      let reopened = makeModel(defaults, now: monday(12, 30))
      #expect(reopened.schedule.weekdays.isEmpty)
      #expect(reopened.earnedToday == 0)
      #expect(defaults.array(forKey: "workWeekdays") as? [Int] == [])
    }
  }

  @Test func missingSalaryIsAskedFirst() {
    withDefaults { defaults in
      let model = makeModel(defaults)
      #expect(model.perSecondText == "연봉을 입력하세요")
      var noWorkdays = WorkSchedule.standard
      noWorkdays.weekdays = []
      #expect(model.submitSchedule(noWorkdays))
      #expect(model.perSecondText == "연봉을 입력하세요")
      #expect(model.setupNotice == "연봉을 입력하세요")
    }
  }
}
