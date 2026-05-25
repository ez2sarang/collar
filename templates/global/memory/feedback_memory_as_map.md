---
name: feedback-memory-as-map
description: "메모리는 지도(map)여야 한다 — 백과사전(encyclopedia) 금지. 포인터만, 내용은 개별 파일에"
metadata:
  type: feedback
---

memory.md / MEMORY.md는 **지도(map)**여야 한다. 백과사전처럼 내용을 직접 쓰지 말 것.

**Why:** 메모리 파일에 내용을 직접 쓰면 파일이 커져서 AI가 전체를 읽지 못하거나 컨텍스트를 낭비한다. 파일시스템 + 에이전트 검색(Bash, ls, grep)으로 개별 파일을 찾는 것이 임베딩/RAG보다 코딩 에이전트에게 더 정확하고 효율적이다. (OpenClaw Seoul Meetup 발표 검증)

**How to apply:**
- memory.md/MEMORY.md에는 포인터(파일 경로, 링크)만 기록
- 실제 내용은 별도 파일(`./patterns/`, `./decisions/`, `./feedback/` 등)에 저장
- 임베딩/벡터DB 도입 유혹 금지 — 파일시스템 + grep으로 충분
- 파일이 커지기 시작하면 내용을 별도 파일로 분리하고 포인터로 교체

```
# 올바른 패턴 (지도)
- [인증 오류 처리](./patterns/auth-error.md) — JWT 만료 시 refresh 먼저
- [DB 스키마 규칙](./feedback/db-schema.md) — 프로젝트별 스키마 분리

# 잘못된 패턴 (백과사전)
## 인증 오류 처리
JWT가 만료됐을 때는 refresh 토큰을 먼저 확인하고...
(내용이 길어져서 파일 자체가 커짐)
```

[[feedback-analyze-before-asking]]
