# 설정 접어 두기 — fe 구현 기록
날짜: 2026-11-10 · 브랜치 `cony/hide-settings` · 커밋 안 함(리드가 함)

## 변경 파일
- `Sources/SalaryTicker/PanelView.swift`: 연봉 입력·오류 문구·초당 금액·근무 시간표를 `DisclosureGroup("설정", isExpanded:)` 안으로 옮겼다. 접힌 상태에서 보이는 것은 "설정" 펼치기, 안내 문구(있을 때만), 구분선, 종료뿐이다. `isSettingsExpanded`는 `@State`(저장 안 함, 기본 false)이고 `onDisappear`(패널 닫힘)에서 false로 되돌린다. 테스트가 펼친 패널을 그릴 수 있게 `init(model:isSettingsExpanded: = false)`를 뒀다(앱은 기본값만 씀).
- `Sources/SalaryTicker/TickerModel.swift`: `setupNotice: String?` 추가("연봉을 입력하세요" / "근무 요일을 선택하세요" / nil). `perSecondText`는 `setupNotice ?? 초당 금액`으로 바꿔 판단을 한 곳에만 둔다. 문구와 우선순위는 그대로.
- `Tests/SalaryTickerTests/PanelViewTests.swift` (새 파일): 핵심 AC 2개.
- `Tests/SalaryTickerTests/ScheduleTests.swift`: 기존 P10/P11 테스트에 `setupNotice` 기대값 3줄 추가.
- `Tests/SalaryTickerTests/ScreenshotTests.swift`: 펼친 패널도 그려 `docs/panel-expanded.png`로 저장.
- `docs/panel.png`(접힌 패널, 520×202), `docs/panel-expanded.png`(새 파일, 520×624). `docs/menubar.png`는 다시 만들었고 md5가 같다(변화 없음).
- `README.md`: 스크린샷에 펼친 패널 추가와 캡션, 사용법 1번(설정 펼치기, 닫으면 다시 접힘), 사용법 4번(펼치면 초당 금액, 접혀도 "연봉을 입력하세요"는 보임).

## 동작 (리드가 정한 항목별)
- 열면 접힘: 접힌 상태에서는 입력칸·시각 피커가 뷰 계층에 아예 없다(테스트로 확인). 연봉 숫자·"초당 N원"은 접힌 화면에 그리지 않는다. 접힌 상태의 안내 문구는 `setupNotice`만 쓰는데, 이 값은 고정 문구 두 개 또는 nil이라 금액이 들어갈 수 없다.
- 다시 열면 접힘: `handleDisappear`에서 `isSettingsExpanded = false`. 펼침은 어디에도 저장하지 않는다.
- 안내 문구: 접혀 있고 `setupNotice`가 있을 때만 "설정" 아래에 보인다. 펼치면 지금처럼 초당 금액 자리에 같은 문구가 나오므로 바깥 줄은 숨긴다(중복 방지, 펼친 화면은 기존과 같다).
- 저장 시점·검증: Enter(`onSubmit`), 포커스 잃음(`onChange(isSalaryFocused)`), 패널 닫힘(`onDisappear`)은 그대로다. 접을 때(`onChange(isSettingsExpanded)`가 false로 바뀜)는 패널 닫힘과 같은 `finishSalaryEditing()`(유효하면 저장, 무효면 저장값으로 되돌림)을 부른다. 기존 `handleDisappear`의 두 줄을 이 함수로 뺐다. 접으면 입력칸이 사라져 포커스 잃음 `commitSalary`도 한 번 더 불릴 수 있는데, 그때 입력칸은 이미 저장값이라 같은 값을 다시 저장하거나(연봉 있음) 오류 없이 끝난다(연봉 없음, 빈 문자열 = 저장값 ""). 무효 입력이 남은 채 접으면 그 입력은 버려지고 펼치면 저장값이 보인다(패널을 닫을 때와 같은 동작).
- 근무 시각: `ScheduleSection`은 접으면 사라지므로 기존 `onDisappear`(무효 시각 버리고 저장값 표시)가 그대로 돈다. 펼치면 새로 만들어져 저장값으로 시작한다. 코드 변경 없음.
- 자동 포커스: 열 때 입력칸이 계층에 없으므로 포커스를 받을 텍스트 칸이 없다(확인한 사실: 접힌 계층에 `NSTextField` 없음). `NSApp.activate()`는 펼친 뒤 타이핑을 위해 그대로 둔다.

## 테스트
- `PanelViewTests`(평소 `swift test`에서 돈다): 화면에 띄우지 않은 borderless `NSWindow`에 `NSHostingView<PanelView>`를 붙이고 `NSTextField`/`NSDatePicker`가 계층에 있는지 본다.
  - `settingsAreCollapsedWhenOpened`: 기본 생성 → 설정 컨트롤 없음.
  - `reopenedPanelIsCollapsedAgain`: 펼친 상태로 생성 → 컨트롤 있음 확인 → 창에서 떼고(onDisappear) 다시 붙이면(onAppear) 컨트롤 없음.
  - 패널 닫기·열기를 "창에서 떼기·붙이기"로 대신했다. 실제 `MenuBarExtra` 창이 닫힐 때 `onDisappear`가 불리는 것은 기존 코드(연봉 저장)가 이미 기대는 동작이고 이번에 새로 확인하지는 못했다(추론).
  - 테스트 프로세스의 activation policy가 `.prohibited`(rawValue 2), `NSApp.isActive == false`임을 확인했다. 그래서 테스트 중 패널의 `NSApp.activate()`는 사용자 앞 화면의 포커스를 뺏지 않는다(확인한 사실). 이전 README 기록의 "재생성 때 포커스가 갈 수 있다(추론)"도 같은 이유로 일어나지 않는 것으로 보인다.
  - 화면 위 클릭으로 펼치기는 오프스크린 창에서 `sendEvent`가 먹지 않아 테스트하지 못했다. 펼친 상태는 init 인자로 만든다.
- `setupNotice`: 연봉 없음 → "연봉을 입력하세요"(요일 0개여도 이것 먼저), 요일 0개 → "근무 요일을 선택하세요", 정상 → nil.
- 이미지 확인(Read로 직접 열어 봄):
  - `docs/panel.png`: "> 설정", 구분선, 종료만. 금액·연봉 없음.
  - `docs/panel-expanded.png`: "v 설정" 아래 연봉 (원) 20,000,000, 초당 2.4원, 근무 요일 월~금 켜짐, 출근 오전 9:30, 퇴근 오후 6:30, 종료. 펼친 내용은 기존 panel.png와 같고 들여쓰기 없음. 입력칸 오른쪽 끝을 확대해 테두리가 잘리지 않은 것을 확인.
  - 연봉 미입력 패널을 임시로 scratchpad에 그려 확인(저장소에 남기지 않음): 접힌 상태에 "연봉을 입력하세요"가 "설정"과 구분선 사이에 보이고, 펼치면 입력칸 placeholder와 같은 문구가 기존 자리에 보인다.

## 화면에서 확인할 항목 (사람 확인, `swift run`)
1. 메뉴바 숫자를 누름 → 패널에 "설정"과 "종료"만 보인다(연봉 저장된 상태). 바로 숫자 키를 눌러도 아무 데도 입력되지 않는다.
2. "설정"을 누름 → 연봉 입력칸, 초당 금액, 근무 요일, 출퇴근 시각이 지금처럼 보인다. 입력칸을 눌러 타이핑할 수 있다.
3. 펼친 채 패널 바깥을 눌러 닫음 → 다시 열면 접혀 있다.
4. 연봉칸에 다른 유효한 값을 타이핑하고 Enter 없이 "설정"을 눌러 접음 → 메뉴바 숫자가 새 연봉 기준으로 바뀐다. 무효한 값(예: `abc`)으로 접으면 다시 펼쳤을 때 이전 연봉이 보인다.
5. 연봉이 없는 상태(사람이 판단해 별도 도메인에서)에서 열면 접힌 채 "연봉을 입력하세요"가 보인다.
6. 펼칠 때 포커스가 연봉 칸으로 바로 가는지, 포커스 링이 잘리지 않는지(오프스크린 렌더로는 확인 못 함).

## 계약 밖 API·결정 필요
- 없음. (서버 없음)
- 참고: `PanelView`의 `isSettingsExpanded` init 인자는 테스트 전용이다. 앱 동작에는 영향이 없지만 리드가 범위에 맞는지 볼 것.

## 검증
- `swift format lint --strict --recursive Package.swift Sources Tests` → 통과(exit 0)
- `swift test` → 통과, 30 tests in 13 suites(스크린샷 스위트 skipped)
- `swift build` → 통과(exit 0)
- `RENDER_SCREENSHOTS=1 swift test --filter ScreenshotTests` → 통과, PNG 3개 다시 씀

## 안전 수칙
- 앱 실행, 프로세스 조회·종료, 표준 UserDefaults 읽기·쓰기, `defaults` 명령은 하지 않았다. 모든 테스트는 `UserDefaults(suiteName:)` 임시 도메인을 쓴다.
- 조사용 임시 테스트 파일 2개는 지웠다. 내가 만든 `~/Library/Preferences/SalaryTicker{ProbeTmp,PanelViewTests}.*.plist`와 이번 스크린샷 실행분 1개는 지웠다. 기존 테스트 스위트가 매 실행마다 남기는 다른 `SalaryTicker*Tests.*.plist`는 이전부터 있던 문제라 손대지 않았다(범위 밖).

컨벤션 점검: 고친 것 1개(테스트 전용 init 주석이 스크린샷만 언급하던 것) / 남긴 것 0개. CONVENTIONS.md 없음, `.swift-format` lint 기준. 판단은 `setupNotice` 한 곳, View 의존 없는 문구 판단은 모델에 둠.
