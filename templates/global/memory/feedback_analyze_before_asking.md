---
name: feedback-analyze-before-asking
description: 질문하기 전 히스토리 먼저 분석하라 — 맥락 파악 없이 사용자에게 묻는 것 금지
metadata:
  type: feedback
---

맥락을 충분히 이해하지 못한 상태에서 사용자에게 질문하지 마라. 대신 다음 순서로 판단하라:

1. `session-compact.md` 읽기
2. `memory.md` 또는 프로젝트 메모리 확인
3. 관련 `doc/` 문서 탐색
4. git log / 파일 상태로 현재 상태 추론

위 과정으로 충분히 판단 가능한 경우, 사용자에게 묻지 말고 바로 실행하라.

**Why:** 맥락 없이 질문하면 사용자가 이미 히스토리에 있는 내용을 반복 설명해야 해서 비효율이 발생한다.

**How to apply:** 질문하려는 순간, "이전 히스토리(session-compact, memory, git log, 문서)를 읽었는가?" 를 먼저 확인하라. 읽지 않았다면 읽고 나서 판단하라. 여전히 불명확하면 그때 질문하라.
