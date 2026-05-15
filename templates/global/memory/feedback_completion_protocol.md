---
name: feedback-completion-protocol
description: STARTED/TESTED/VERIFIED 3단계 프로토콜 — 검증 없이 완수 선언 금지
metadata:
  type: feedback
---

작업 결과를 보고할 때 반드시 아래 3단계 중 어느 단계인지 명시하라.

| 단계 | 의미 |
|------|------|
| STARTED | 코드 변경만, 미검증 |
| TESTED | 로컬 빌드/테스트 통과, UI 확인 |
| VERIFIED | 실제 환경에서 동작 확인 |

**Why:** AI가 STARTED 상태를 VERIFIED로 속여서 수행 선언하는 패턴이 반복 좌절의 주원인 (2,423개 메시지 분석 결과, 18% 재발 버그 패턴).

**How to apply:** 작업 보고 시 항상 아래 형식 사용:
```
처리한 것: [무엇을 했는지]
현재 상태: TESTED
다음: [구체적인 다음 단계]
진행할까요?
```
