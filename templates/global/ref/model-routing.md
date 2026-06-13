# 카테고리 기반 모델 라우팅 상세 레퍼런스

> 글로벌 CLAUDE.md "카테고리 기반 모델 라우팅" 섹션의 상세 표/다이어그램/collar 자동 라우팅.
> 핵심 규칙(Opus 직접=판단·분석·전략, Sonnet 위임=구현, Haiku 명시위임=검색, 소스 우선 Read/Grep, 위임 후 자기검증 금지)은 CLAUDE.md 본문에 있다.
> 모델은 "더 좋다/나쁘다"가 아니라 **작업 성격과의 적합도**로 선택한다. (OMO 철학)

## 현재 오케스트레이션 구조 (2026-06-02 변경)

**구현 방법:** `~/.claude/settings.json`에 `"model": "opusplan"` 설정
- Plan mode → Opus가 판단·계획 (지휘자)
- Execution mode → Sonnet이 구현·실행 (실행자)
- Agent() 호출 → Sonnet (`CLAUDE_CODE_SUBAGENT_MODEL: "sonnet"`)
- Thinking depth: `effortLevel: "xhigh"` (Opus 4.7+ 공식 방법, MAX_THINKING_TOKENS/DISABLE_ADAPTIVE_THINKING은 Opus 4.7+에서 무의미)

**안전망:** `~/.claude/hooks/opus-guard.sh` — Sonnet 세션에서도 분석 키워드 감지 시 Opus 위임 강제

```
사용자 메시지
    ↓
Opus (Plan mode) — 지휘자: 계획·판단·감독·복잡한 분석 직접 수행
    ↓ Agent() 위임
Sonnet (Execution mode + 기본 서브에이전트) — 실행자: 코드 작성, 기능 추가, 버그 수정
    ↓ Agent(model="haiku") 명시
Haiku — 보조: 파일 검색, 빠른 조회, 단순 확인
```

**Opus가 직접 처리하는 것 (위임 금지):** 판단, 계획, 전략, 아키텍처, 복잡한 분석
**Sonnet에게 위임:** 코드 구현, 기능 추가, 파일 수정, 일반 버그 수정
**Haiku에게 명시 위임:** grep 검색, 파일 찾기, 단순 확인, 빠른 질문

## 모델 성격 분류

| 모델 계열 | 세션 역할 | 강점 |
|----------|----------|------|
| **Claude Opus** | **메인 루프 (지휘자)** | 판단, 전략, 분석, 아키텍처 — Opus가 직접 |
| **Claude Sonnet** | 기본 서브에이전트 (실행자) | 코드 수정, 기능 추가, 표준 버그 |
| **Claude Haiku** | 명시 위임 서브에이전트 | 검색, 조회, 단순 확인 |

## Opus가 판단해서 자동 위임하는 기준

Opus(메인)가 스스로 작업 성격을 판단해서 아래 기준으로 Agent를 호출한다. 사용자가 지정하지 않는다.

| Opus의 판단 | Opus가 내부적으로 호출하는 방식 | 이유 |
|-----------|---------------------------|------|
| 코드 수정, 기능 추가, 일반 버그 | `Agent(prompt="...")` — 기본값 sonnet | 구현 신뢰도 |
| 파일 검색, grep, 단순 확인 | `Agent(prompt="...", model="haiku")` | 속도·비용 |
| UI/CSS/레이아웃 구현 | `Agent(prompt="...", subagent_type="designer")` | 시각적 reasoning |
| 독립 검증, 코드 리뷰 | `Agent(prompt="...", subagent_type="verifier")` | 자기 승인 방지 |

**Opus(메인)는 위임 판단 후 직접 실행·검증하지 말고 별도 Agent로 분리한다.**

## 소스 우선 분석 원칙 (분석 요청 시 의무)

분석·확인·근거 요청이 오면 **반드시 Read/Grep 먼저**, Bash/Write/Edit는 그 다음이다.

```
금지 순서: 분석 요청 → 추측으로 즉시 답변
올바른 순서: 분석 요청 → Read/Grep(소스 확인) → 근거 기반 응답 → 필요 시 위임
```

## 핵심 규칙

1. **Opus는 단순 구현을 직접 하지 않는다** — 코드 작성은 Sonnet Agent에게 위임
2. **Opus가 작업 복잡도를 판단해서 자동 위임** — 검색·확인 → `Agent(model="haiku")`, 구현 → `Agent()` (기본 sonnet)
3. **판단·분석은 Opus가 직접** — 이것은 위임하지 않는다 (Opus가 메인이므로)
4. **위임 후 자기 검증 금지** — 위임한 결과는 별도 Verifier Agent로 확인

## collar에서의 자동 라우팅

collar-github run 시 이슈 복잡도 자동 평가:
- `simple` 판정 → haiku (max-turns: 10)
- `standard` 판정 → sonnet (max-turns: 20)
- `complex` 판정 → opus (max-turns: 30)

평가 기준: `collar eval-model <model>` 으로 모델별 카테고리 적합도 측정 가능.
