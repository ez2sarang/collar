---
name: feedback-auto-commit
description: 작업 후 자동 커밋 규칙 — 사용자 요청 없이도 작업 마무리 시 커밋 실행
metadata:
  type: feedback
---

작업 지시 후 백그라운드 작업 없이 개발이 완전히 마무리됐다면, 사용자가 별도로 요청하지 않아도 반드시 커밋을 실행한다.

**Why:** 매번 커밋을 요청하는 것은 사용자 입장에서 불필요한 반복이다.

**How to apply:**
- 작업 마무리 → git status/diff 확인 → 관련 파일 스테이징 → 커밋
- 커밋 전 사용자 확인이 필요한 예외 2가지:
  1. breaking change가 포함된 경우
  2. 여러 작업이 섞여 커밋 단위가 불명확한 경우
- 백그라운드 작업이 남아있거나 STARTED 상태면 커밋 보류
