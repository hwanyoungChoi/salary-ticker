# ADR-001 계산 로직 위치: 같은 target 안의 순수 타입
- 상태: 채택
- 맥락: 초당 금액·오늘 번 돈 계산을 UI와 분리해 시각 고정 테스트를 해야 한다.
- 선택지: A. 같은 executable target 안에 View와 다른 파일의 순수 타입 / B. 별도 library target
- 의견: pm(A 추천, 가장 단순) / fe(찬성, @testable import로 이미 테스트 가능하고 나중에 B로 옮기기 쉬움) / qa(찬성, Calendar·UserDefaults 주입만 되면 충분)
- 검토 원문: [fe](../reviews/20261110-1121-fe-spec-salary-counter.md) · [qa](../reviews/20261110-1121-qa-spec-salary-counter.md)
- 결정: A
- 이유: 지금 요구를 충족하는 가장 단순한 구조이고 테스트 가능성도 같다.
- 뒤집을 조건: 계산 로직을 위젯·다른 앱 등 두 번째 target에서 써야 할 때.
