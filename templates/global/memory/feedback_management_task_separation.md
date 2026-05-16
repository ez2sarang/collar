---
name: feedback-management-task-separation
description: 단일 에이전트 작업 집중 시 절차 규칙 망각 → 관리/작업 에이전트 역할 분리 필요 (허예찬 아키텍처)
metadata:
  type: feedback
---

작업 에이전트 역할로 집중할 때는 절차 규칙(커밋, 검증)을 잊는 경향이 있다.

**Why:** 규칙이 CLAUDE.md에 존재해도 작업 압박 시 절차를 잊는다.
허예찬 지적: "관리 agent, 작업 agent를 분리해서 역할을 나눠라"
단일 에이전트가 코드를 짜고 자기 결과를 승인하면 절차가 누락된다.

**How to apply:**
"완료" 선언 전 의무 자기감사 — 전부 YES여야 선언 가능:
  ☐ 검증 명령을 실제 실행했는가? (출력 결과 존재하는가?)
  ☐ git commit를 실행했는가? (git status 클린한가?)
  ☐ 현재 상태 TESTED 이상인가? (STARTED면 선언 금지)
  ☐ 요청 사항 전부 이행했는가?
  ☐ 보고 형식을 지켰는가?

명시적 체크리스트 없이는 절차 준수 보장 불가.
복잡한 작업 → verifier 에이전트를 별도로 호출해 독립 검증.
참고 메모리: [[feedback-auto-commit]] [[feedback-completion-protocol]]
