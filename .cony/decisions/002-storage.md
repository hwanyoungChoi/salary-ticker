# ADR-002 입력값 저장: UserDefaults
- 상태: 채택
- 맥락: 연봉과 근무 시간표를 이 기기에만 저장해야 한다(CLAUDE.md 제약).
- 선택지: A. UserDefaults / B. JSON 파일
- 의견: pm(A 추천) / fe(조건부 찬성, @AppStorage가 [Int]를 지원하지 않으니 키 이름만 고정하고 배열 저장 방식은 fe 재량) / qa(조건부 찬성, TextField를 저장소에 바로 묶으면 잘못된 입력이 그대로 저장되므로 검증을 거쳐 저장)
- 검토 원문: [fe](../reviews/20261110-1121-fe-spec-salary-counter.md) · [qa](../reviews/20261110-1121-qa-spec-salary-counter.md)
- 결정: A. 키 이름만 스펙에 고정하고, 저장은 검증을 통과한 값만 한다.
- 이유: Apple 기본 관례이고 값이 몇 개뿐이다. 두 조건은 모두 스펙에 반영했다.
- 뒤집을 조건: 저장할 값이 기록(이력)처럼 커지거나 내보내기가 필요할 때.
