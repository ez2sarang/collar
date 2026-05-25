---
name: feedback-repeated-failure-pipeline
description: "반복 실패 → 운영 규칙 파이프라인 — 같은 실수를 두 번 하면 규칙으로 굳혀라"
metadata:
  type: feedback
---

반복 실패를 그냥 넘기지 말고 **운영 규칙으로 굳혀야** 재발을 막는다.

**Why:** 일회성 수정은 다음 세션에서 컨텍스트가 리셋되면 사라진다. 실패 패턴을 규칙으로 굳히지 않으면 같은 실수가 반복된다. (OpenClaw Seoul Meetup: "반복 실패를 운영 규칙으로 굳혀야 하는 구조가 있어야 한다")

**How to apply:**
- 같은 실패가 2번 발생 → 즉시 `collar remember "규칙"` 실행
- memory.md의 "반복 실패 → 운영 규칙 파이프라인" 테이블에 기록
- CLAUDE.md에 영구 규칙으로 추가 (단순 메모가 아닌 행동 규칙)
- 규칙 형식: "금지/의무 + Why + How to apply"

```
# 올바른 파이프라인
실패 발생 → 원인 분석 → collar remember "이런 상황에서 X 금지, 대신 Y 사용" → CLAUDE.md 반영

# 잘못된 패턴
실패 발생 → 그냥 수정 → 다음 세션에서 또 같은 실수
```

[[feedback-completion-protocol]]
