# collar 메모리 시스템 설계
**날짜:** 2026-05-14  
**목적:** gstack learnings vs 허예찬 메모리 방식 비교 → collar 메모리 설계 방향 결정

---

## 1. 현황 비교

### 1.1 gstack learnings 시스템

**저장 위치:** `~/.gstack/projects/{slug}/learnings.jsonl`

**저장 형식:**
```jsonl
{"skill":"gstack","type":"operational","key":"collar-generic-type","insight":"collar project has no package.json/Cargo.toml - detected as 'generic' type","confidence":8,"source":"observed"}
```

**로딩 방식:** 매 세션 Preamble에서 자동 로드
```bash
_LEARN_FILE="${GSTACK_HOME:-$HOME/.gstack}/projects/${SLUG:-unknown}/learnings.jsonl"
if [ -f "$_LEARN_FILE" ]; then
  _LEARN_COUNT=$(wc -l < "$_LEARN_FILE" 2>/dev/null | tr -d ' ')
  if [ "$_LEARN_COUNT" -gt 5 ]; then
    ~/.claude/skills/gstack/bin/gstack-learnings-search --limit 3 2>/dev/null || true
  fi
fi
```

**특징:**
- 스킬 실행 중 `gstack-learnings-log` 명령으로 기록
- 프로젝트별로 분리됨 (`{slug}` = git remote URL 기반)
- 세션마다 자동 검색 (관련 learnings 상위 3개 로드)
- `gstack-brain` 기능으로 원격 GitHub 레포에 동기화 가능 (크로스머신)

**한계:**
- gstack 스킬에 묶임 — gstack 없는 세션엔 로드 안 됨
- 스킬 실행 중에만 기록 — 일반 대화 중 발견한 것은 수동 기록 필요
- 구조: `skill`, `type`, `key`, `insight` 4필드 — AI가 판단한 운영 인사이트만

---

### 1.2 허예찬 OMX 메모리 방식

팟캐스트 + 커뮤니티 발표 기반 (직접 소스코드 미분석).

**핵심 발언:**
> "에이전트는 매 세션 이전 작업의 맥락을 가지고 시작해야 한다"

**관찰된 패턴:**
- AGENTS.md / CLAUDE.md 자체가 일종의 영속 메모리 (프로젝트 규칙이 학습 내용을 반영)
- OMX는 코덱스 마개조라 세션 상태가 없음 → 메모리 = 파일 기반 영속
- "에이전트를 직원처럼 관리" → 직원 온보딩 문서(AGENTS.md) = 축적된 메모리

**핵심 인사이트:**
허예찬의 메모리 철학 = **문서 자체가 메모리다**. 별도 메모리 DB가 아니라 CLAUDE.md/AGENTS.md가 지속적으로 업데이트되면서 학습 내용이 반영됨.

---

### 1.3 현재 collar 메모리

**없음.** CLAUDE.md는 정적 헌법이고, 프로젝트 경험에서 얻은 인사이트를 축적하는 메커니즘이 없다.

---

## 2. 비교 분석

| 특성 | gstack learnings | 허예찬 방식 | collar 현재 |
|------|-----------------|------------|------------|
| 저장 형식 | JSONL (구조화) | CLAUDE.md/AGENTS.md (문서) | 없음 |
| 로딩 방식 | Preamble 자동 | Claude Code 자동 읽음 | - |
| 적용 범위 | 프로젝트별 | 프로젝트별 | - |
| 글로벌 승격 | gstack-brain (GitHub) | 수동 | - |
| AI 독립성 | gstack 의존 | 모든 AI 가능 | - |
| 기록 시점 | 스킬 실행 후 | 수동 문서 업데이트 | - |
| 구조화 | 높음 (JSON) | 낮음 (자유 문서) | - |

---

## 3. collar 메모리 설계 제안

### 핵심 원칙

1. **AI 독립적**: gstack, Claude Code 외의 AI도 읽을 수 있어야 함
2. **파일 기반**: JSONL 또는 Markdown — 외부 DB 없음
3. **자동 로딩**: CLAUDE.md에 지시 포함 → AI가 세션 시작 시 자동 읽음
4. **글로벌 승격**: 프로젝트 메모리 → 글로벌(`~/.claude/`) 승격 메커니즘

### 3.1 저장 구조

```
프로젝트/
├── CLAUDE.md           ← "세션 시작 시 .collar/memory.md를 읽어라" 지시 포함
├── .collar/
│   ├── memory.md       ← 프로젝트 학습 내용 (Markdown, AI 친화적)
│   └── insights.jsonl  ← 구조화된 인사이트 (gstack learnings 호환)
```

글로벌:
```
~/.claude/
└── collar-memory/
    └── global-insights.jsonl   ← 모든 프로젝트에서 승격된 인사이트
```

### 3.2 memory.md 형식

```markdown
# Project Memory — {PROJECT_NAME}
마지막 업데이트: {DATE}

## 발견된 패턴

### [날짜] {제목}
**맥락:** {어떤 상황에서 발견했는지}
**발견:** {무엇을 배웠는지}
**적용:** {다음에 어떻게 활용할지}

---

### [2026-05-14] socialMakeit 검색 버그 패턴
**맥락:** 검색 기능이 3일 연속 같은 방식으로 재발
**발견:** AI가 "완료" 후 실제 실행 테스트를 하지 않음. 코드 변경 ≠ 동작 확인
**적용:** 검색 관련 수정 후 반드시 실제 검색어로 E2E 테스트
```

### 3.3 CLAUDE.md에 자동 로딩 지시 추가

collar-init이 생성하는 CLAUDE.md에 이 섹션 추가:

```markdown
## 세션 시작 프로토콜

새 세션 시작 시 반드시:
1. `.collar/memory.md` 파일이 있으면 읽어라 — 이전 세션의 학습 내용
2. 최근 3개 항목을 현재 작업에 적용
3. 새로운 인사이트 발견 시 `.collar/memory.md`에 추가
```

### 3.4 `collar remember` 명령어 (신규)

```bash
# 현재 세션에서 발견한 것을 메모리에 기록
collar remember "API 키 없이 호출하면 503이 아니라 200 빈 응답 옴"

# → .collar/memory.md에 추가
# → .collar/insights.jsonl에 구조화 저장
# → "글로벌에도 추가할까요? [y/e/v/N]" 프롬프트 (collar-init과 동일 방식)
```

### 3.5 글로벌 승격 흐름

```
세션 중 발견 → collar remember → .collar/memory.md
                                        ↓ (중요 패턴 판단)
                         "글로벌에 추가할까요? [y/e/v/N]"
                                        ↓ (y 선택)
                    ~/.claude/collar-memory/global-insights.jsonl
                                        ↓ (자동)
                         모든 프로젝트 세션 시작 시 참조
```

---

## 4. gstack learnings와의 차이

| | gstack learnings | collar memory |
|---|---|---|
| 대상 독자 | gstack 스킬 | 모든 AI (Claude, Codex, Gemini) |
| 기록 시점 | 스킬 완료 후 자동 | `collar remember` 명시적 기록 |
| 형식 | JSONL | Markdown + JSONL 병행 |
| 글로벌 | gstack-brain (GitHub sync) | `~/.claude/collar-memory/` |
| 승격 방식 | 자동 (사용 횟수 기반) | 사용자 의견 포함 [y/e/v/N] |

**결론:** gstack learnings는 "스킬이 자동으로 운영 인사이트를 수집"하는 방식. collar memory는 "사람이 중요하다고 판단한 것을 AI가 이해할 수 있는 형식으로 저장"하는 방식. 둘은 충돌하지 않고 보완된다.

---

## 5. 구현 우선순위

| 항목 | 우선순위 | 난이도 |
|------|---------|--------|
| CLAUDE.md.base에 세션 시작 프로토콜 추가 | 즉시 | 낮음 |
| collar-init에 `.collar/memory.md` 생성 | 즉시 | 낮음 |
| `collar remember` 명령어 | 단기 | 중간 |
| `~/.claude/collar-memory/` 글로벌 저장소 | 단기 | 낮음 |
| insights.jsonl 구조화 + 자동 검색 | 중기 | 높음 |

---

## 6. 즉시 적용 가능한 것

collar-init에 두 가지 추가:

1. `.collar/memory.md` 빈 파일 생성 (헤더만)
2. `CLAUDE.md` 생성 시 "세션 시작 프로토콜" 섹션 포함

이것만으로도 AI가 매 세션 시작 시 이전 학습을 참조할 수 있는 기반이 만들어진다.
