---
name: feedback-report-format
description: 보고 시 표 필수 + 프로세스 설명 시 Mermaid 사용 (ASCII 순서도 금지)
metadata:
  type: feedback
---

보고하거나 설명이 필요한 상황에서 형식 규칙:

1. **표 우선**: 항목이 3개 이상이거나 비교/상태 요약이 필요하면 표를 반드시 포함
2. **Mermaid 사용**: 흐름/순서/구조 시각화 시 ASCII 그림 대신 Mermaid 사용
   - 흐름도: `flowchart LR` / `flowchart TD`
   - 시퀀스: `sequenceDiagram`
   - 상태: `stateDiagram-v2`

**Why:** 표와 Mermaid가 ASCII보다 가독성이 높고, 사용자가 명시적으로 요청한 선호 방식이다.

**How to apply:** 보고 요청이 오면 → 표 먼저 → 설명 추가. 흐름 설명 필요하면 → Mermaid 블록 사용.
