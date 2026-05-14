# 대화 세션 Q&A 정리
**날짜:** 2026-05-14  
**세션:** collar 프로젝트 방향성 인터뷰 + 구현 + 분석

---

## Q1. collar가 하려는 것이 정확히 무엇인가?

**A:** 모든 프로젝트에서 `collar-init` 하나로 10초 만에 AI 하네스(CLAUDE.md + AGENTS.md + .claude/settings.json)를 설치하는 도구.

ez2claude(글로벌 OMC, `~/.claude/`)가 "AI가 어떻게 일할지"를 정한다면, collar는 "이 프로젝트에서 AI가 무엇을 어떻게 만들지"를 정한다.

현재 상태: 구현 완료. `~/Documents/dev/ai/collar/bin/collar-init`

---

## Q2. a/b/c (collar init, 기존 프로젝트 적용, Paperclip 오케스트레이션)는 어떻게 됐나?

**A:** 사용자가 "a, b, c는 향후 더 발전된 방향"이라고 답변. 즉시 구현 대상이 아님.

현재 방향:
1. collar-init으로 새 프로젝트 하네스 생성 ✓ 구현됨
2. 기존 프로젝트 소급 적용: CLAUDE.md가 없으면 생성, 있으면 건드리지 않음
3. Paperclip 연동: 장기 목표, 미구현

---

## Q3. collar-init을 매번 직접 실행해야 하나? 자동화 안되나?

**A:** 현재는 수동 실행이 맞다. 하지만 더 좋은 방향이 두 가지 있다:

**방향 1: collar-init 개선** (단기)
- 현재: 프로젝트 타입만 감지, TODO 항목은 사람이 채워야 함
- 개선: 코드베이스를 읽어서 TODO를 자동으로 채우는 `collar update` 명령 추가
  ```bash
  collar-init                 # 기본 하네스 생성
  collar update               # 코드 읽어서 CLAUDE.md TODO 자동 채우기
  ```

**방향 2: collar run (중기, 미구현)**
- 새 프로젝트 시작 시 자동으로 collar-init 실행하는 훅/스크립트
- 예: `~/.zshrc`에 `cd` 훅으로 .git 있는 디렉토리 진입 시 collar 존재 체크

**현재 답:** 매번 수동으로 실행해야 하지만, `collar update` 개념으로 자동화 가능.

---

## Q4. socialMakeit에 collar-init 실행 결과는?

**A:**
- AGENTS.md: 생성됨 (nextjs 타입으로 자동 감지)
- .claude/settings.json: 생성됨 (기본 권한 설정)
- CLAUDE.md: 기존 파일(`@AGENTS.md` + Gemini 통합 메모만 있던 상태) → 이번 세션에서 실제 프로젝트 내용으로 업데이트됨

socialMakeit은 TikTok 검색 → 다운로드 → TTS → 비디오 합성 → 업로드 파이프라인 + 쿠팡 파트너스 수익화 도구임을 파악, CLAUDE.md에 반영.

---

## Q5. 좌절 분석 결과는?

**A:** 2,423개 사용자 메시지 + bash 명령 14,000줄 분석 (2026-03-27 ~ 05-12).

**5가지 좌절 패턴:**

| 패턴 | 빈도 | 대표 사례 |
|------|------|---------|
| 작업 정체 (이어서 계속해줘 반복) | 67건 (22%) | "이어서 테스트해줘" 20회+ |
| 같은 버그 재발 | 55건 (18%) | "또 검색이 안됨" 3일 연속 |
| UI/기능 미동작 | 44건 (14%) | 단축키 5번 바꿔도 안됨 |
| 미검증 완료 주장 | 48건 (15%) | "검증도 없이 완료를 하냐?" |
| 요구사항 오해 | 42건 (13%) | OAuth를 두 번 동일하게 설명해야 함 |

**패턴 악화 추세:** 3월(보통) → 5월(심각) — 같은 패턴이 반복되며 점점 심해짐.

**근본 원인:** AI가 코드 변경(STARTED) 상태를 실제 동작 확인(VERIFIED)으로 속여 "완료" 선언.

**collar에 반영한 것:** 완료 3단계(STARTED/TESTED/VERIFIED), 모호한 표현 차단 목록, 다음 단계 명시 강제, 재발 버그 체크.

---

## Q6. gstack이 왜 이 문제들을 못 잡았나?

**A:**

| gstack 현재 설계 | 빠진 것 |
|----------------|--------|
| 검증 규칙이 CLAUDE.md 문서에만 있음 | 실행을 강제하는 체크포인트 없음 |
| "완료" 언어 미정의 | STARTED/TESTED/VERIFIED 구분 없음 |
| 요구사항 모호성 가드 없음 | "효율적으로" 같은 표현 통과됨 |
| 다음 단계 명시 규칙 없음 | 사용자가 계속 "이어서" 입력해야 함 |
| 재발 버그 체크 없음 | 새 수정 전 이전 수정 생존 확인 없음 |

gstack의 설계 철학(Boil the Lake, 완전한 것을 해라)은 맞지만, 검증 단계가 강제되지 않아서 AI가 완전하지 않은 것을 완전하다고 주장하는 것을 막지 못함.

**collar의 차별점:** 검증을 선택이 아닌 필수로 만들고, 완료의 의미를 명시적으로 3단계로 정의.

---

## Q7. 허예찬의 "가벼운 프로그램" 주장은 맞는가?

**A:** 맞다. 검증됨.

**가벼운 런타임 (codex exec, gemini -p)의 장점:**
- `codex exec "prompt" < input.ts` → 독립 프로세스, 상태 없음, 종료 코드로 성공/실패 판단 가능
- 10개 병렬 실행: `for f in *.ts; do codex exec "add types" < "$f" & done`
- Gemini CLI: `--approval-mode yolo`로 완전 자동, `--approval-mode auto_edit`으로 파일 편집만 자동

**Claude Code Max의 문제:**
1. 대화형 세션 = 무거움, 컨텍스트 누적
2. 병렬화 복잡 (run_in_background가 메인 컨텍스트를 무겁게 만듦)
3. 가장 좋은 기능들(`--fallback-model`, `--max-budget-usd`)이 대화형에서 작동 안 함

**실용적 결론:** 긴 복잡한 작업 = Claude Code 대화형. 단발성/batch 작업 = `claude --print` 또는 `codex exec` 또는 `gemini -p`.

---

## Q8. 멀티-LLM (Claude + Gemini + OpenAI) 환경 어떻게 써야 하나?

**A:** 현재 로컬 상태:
- Claude Code Max: 구독 중, 주력
- Gemini CLI 0.36.0: 설치됨, GEMINI_API_KEY 설정됨
- codex-cli 0.121.0: 설치됨
- OpenAI Pro: 구독 중, openai CLI 미설치

**권장 라우팅:**

| 작업 | 도구 | 이유 |
|------|------|------|
| 파일 검색, 간단한 질문 | `gemini -p` 또는 haiku | 빠름, 저비용 |
| 코드 수정, 기능 추가 | `claude --print` (sonnet) | 신뢰도 |
| 100KB+ 파일 분석 | `gemini -p` | 1M 토큰 컨텍스트 |
| 스크린샷/이미지 분석 | gemini_vision MCP | 멀티모달 |
| batch 처리 (여러 파일) | `codex exec` 병렬 | 독립 프로세스 |
| 아키텍처/보안 결정 | Claude opus | 중요한 한 번 |
| 장기 복잡한 대화 | Claude Code 대화형 | 풍부한 도구 |

**가장 활용 안 되는 것:** Gemini와 codex가 설치되어 있는데 Claude Code 대화형만 쓰는 상황.

---

## Q9. collar-init의 "매번 직접 채워야 하는 TODO" 문제를 어떻게 개선하나?

**A:** 2단계 명령 구조 제안:

```bash
# 1단계: 골격 생성 (현재 있음)
collar-init my-project

# 2단계: 코드 읽어서 TODO 자동 채우기 (미구현, 다음 단계)
cd my-project && collar update
```

`collar update`는:
1. package.json, src/, supabase/ 등 읽기
2. AI로 프로젝트 목적, 주요 파일, 도메인 파악
3. CLAUDE.md의 TODO 항목 자동으로 실제 내용으로 교체

이 세션에서 socialMakeit을 수동으로 한 작업이 `collar update`가 자동으로 해야 할 일.

---

## Q10. collar의 장기 목표 (Paperclip 연동)는 어떻게 되나?

**A:** 4계층 아키텍처 구조:

```
사용자 목표/미션
    ↓
Paperclip (오케스트레이션 제어 플레인)
    ↓
collar (프로젝트별 하네스 표준화)
    ↓
OMC/OMX (실행 런타임)
```

현재: collar와 Paperclip은 독립 운영 중.
단기: collar-init이 Paperclip이 인식하는 설정 파일 생성.
장기: Paperclip 오케스트레이터가 collar를 통해 멀티-LLM 작업 분배.

---

---

## Q11. collar의 정확한 포지션은?

**A:** collar는 OMC/OMX도 아니고 허예찬 툴의 활용도 아닌 **세 번째 포지션** — 설정 레이어.

```
Layer 3: Paperclip   (오케스트레이션)
Layer 2: collar      ← 하네스 템플릿 생성기
Layer 1: OMC / OMX   (실행 런타임 — 에이전트 실제 동작)
```

collar가 만든 CLAUDE.md를 OMC(Claude Code)가 읽는다. collar 자체는 에이전트를 실행하지 않는다. GitHub/GitLab 연동도 필요 없다. 독립적으로 동작한다.

**설계 문서:** `doc/2026-05-14-harness-system-plan.md` (4-레이어 아키텍처 다이어그램 포함)

---

## Q12. /gstack 없이도 스킬이 작동하나?

**A:** 그렇다. 두 가지 방식:

**자동 (PROACTIVE 모드):** CLAUDE.md에 `## Skill routing` 섹션이 있으면 키워드를 감지해서 Skill tool을 자동 호출한다. "버그가 있는데" → `/investigate` 자동 실행.

**명시적 호출:** `/qa`, `/investigate`, `/review` 같이 스킬 이름만 써도 된다. `/gstack`은 gstack 시스템 진입 + 일반 요청을 한 번에 쓸 때의 방식이었다.

**구동 순서:** 사용자 메시지 → CLAUDE.md Skill routing 패턴 매칭 → Skill tool 자동 호출 → 스킬 SKILL.md 워크플로우 실행

---

## Q13. 룰이 정립되면 글로벌로도 자동 반영되어야 하지 않나?

**A:** 맞다. 수동으로 ~/.claude/CLAUDE.md에 직접 쓰는 것은 불합리하다.

**해결책:** `collar-init` 마지막 단계에 글로벌 승격 프롬프트 추가 (2026-05-14 구현됨).

- collar-init 실행 후 `~/.claude/CLAUDE.md`에 STARTED/TESTED/VERIFIED 규칙이 없으면 자동 감지
- "글로벌에도 추가할까요? [y/N]" 입력 요청
- Y면 `~/.claude/CLAUDE.md` 끝에 collar 공통 규칙 블록 자동 추가

3-레이어 적용 방식:
| 적용 범위 | 저장 위치 |
|---|---|
| 모든 프로젝트 | `~/.claude/CLAUDE.md` (ez2claude) |
| gstack 사용 프로젝트 | `~/.gstack/projects/{slug}/learnings.jsonl` |
| 이 프로젝트만 | `프로젝트/CLAUDE.md` (collar가 생성) |

---

## Q14. 허예찬 영상에서 언급된 기술/개념 목록

**A:** 4개 영상 분석 기반 (2026-05-14 세션 초반 분석)

### 팟캐스트 #80 — 허예찬 OMC/OMX 개발 스토리

| 기술/개념 | 설명 |
|---|---|
| OMC (oh-my-claude-code) | Claude Code용 멀티에이전트 오케스트레이션 레이어 |
| OMX (oh-my-codex) | OpenAI Codex CLI 마개조 런타임 |
| CLAUDE.md | Claude Code 프로젝트 자동 로딩 헌법 파일 |
| AGENTS.md | Codex/Claude Code 자동 인식 에이전트 가이드 |
| 가벼운 런타임 | `codex exec` 같은 stdin→LLM→stdout 파이프라인 |
| 에이전트 팀 운영 | AI 에이전트를 팀원처럼 역할/예산/보고체계로 관리 |
| 하네스 엔지니어링 | 4요소: 헌법 + 작업구조 + 검증 + 실행루프 |
| 메모리 시스템 | 프로젝트별 학습 이력을 파일로 영속 저장, 세션마다 로드 |

### OMX 커뮤니티 발표 — 코덱스 마개조

| 기술/개념 | 설명 |
|---|---|
| codex exec | `codex exec "prompt"` — 비대화형 stdin→LLM→stdout |
| 비대화형 병렬화 | `for f in *.ts; do codex exec "..." < "$f" & done` |
| 종료 코드 에러 핸들링 | exit code로 성공/실패 판단 (대화형과 차이) |
| 런타임 마개조 | 순정 codex-cli와 다른 동작을 하네스로 구현 |

### 하네스 엔지니어링 따라하기 (Dori)

| 기술/개념 | 설명 |
|---|---|
| 하네스 4요소 | 헌법 / 작업구조 / 검증 / 실행루프 |
| PRP (Product Requirements Prompt) | 구조화된 작업 지시 문서 |
| VERIFIED 단계 | 코드 변경만으로는 완료가 아님 — 실제 동작 확인 필수 |

### MIT/Harvard AI 연구

| 기술/개념 | 설명 |
|---|---|
| Cognitive Debt (인지 부채) | AI 수동 의존 시 뇌 신경 연결성 약화 |
| 협력 도구로서의 AI | 자신의 사고를 유지하면서 AI를 도구로 사용 → 함께 성장 |
| 말 잘 듣는 AI의 조건 | 사람이 명확히 사고해야 AI도 잘 일한다 (양방향) |

**가장 중요한 발견:** 허예찬이 강조한 메모리 시스템은 "세션 종료 후에도 학습이 남는다"는 것. gstack의 `learnings.jsonl`이 이를 구현하고, collar는 이 개념이 빠져 있다.

---

## Q15. 에르메스 에이전트(Hermes Agent)란 무엇인가?

**출처:** 영상 `-p0e03kVdBI` (허예찬 OMC/OMX 개발자 인터뷰, AI 팟캐스트 #80)

**A:** 인터뷰에서 두 번 언급된 오픈소스 하네스 도구.

### 발언 맥락 1 (메모리 경쟁)
> "지금 오픈 소스나 뭐 에르메스 에이전트 같은 하네스들이 굉장히 뜨고 있는데, 이게 떠남과 동시에 지금 가장 도구들이 두 가지 도구들이 경쟁하고 있는 부분 중에 하나가 이제 **메모리 시스템이 어떻게 구축되어 있느냐**인 거 같거든요."

**허예찬의 반응:**
> "메모리 시스템이라는 건 구현하는데 시간이 많이 들어가는 종류의 일이 아니에요. 애초에 시스템한 게 아니에요. LLM이 리오거나이징을 어떻게 할지에 대한 가이던스를 주는 거고 그 이외에 런타임이라고 할 만한 컴포넌트가 없어요."

### 발언 맥락 2 (개인 AI 비서 용도)
> "오픈 클로우나 약간 에르메스 에이전트 같은 툴을 나만의 약간 인공지능 비서처럼 사용하려는 그런 생각들이 꽂혀 있지 않나라는 생각이 들더라고요."

### collar에 주는 시사점

| 항목 | 에르메스 에이전트 방향 | 허예찬/collar 방향 |
|------|----------------------|-------------------|
| 메모리 | 복잡한 시스템 구현 | 파일 기반 가이던스 (`.collar/memory.md`) |
| 런타임 | 별도 컴포넌트 | LLM 자체가 처리 |
| 경쟁 포인트 | 메모리 시스템 정교함 | 단순성과 이식성 |

**결론:** 에르메스 에이전트는 메모리 시스템에 공을 들이는 경쟁 오픈소스 하네스. collar는 허예찬의 철학("문서 자체가 메모리")을 따르므로 직접 경쟁이 아닌 다른 포지션. collar를 분석할 때 에르메스 에이전트와의 차별점 = **단순성 + 자동화 우선**.

> 에르메스 에이전트 GitHub: 검색 필요 (영상에서 링크 미제공)

---

## 작업 항목 현황 (2026-05-14 기준)

| 항목 | 상태 | 파일 |
|------|------|------|
| collar-init 스크립트 | 완료 | `bin/collar-init` |
| CLAUDE.md.base v2 템플릿 | 완료 | `templates/CLAUDE.md.base` |
| AGENTS.md.base v2 템플릿 | 완료 | `templates/AGENTS.md.base` |
| socialMakeit AGENTS.md 생성 | 완료 | `~/Documents/dev/ai/socialMakeit/AGENTS.md` |
| socialMakeit CLAUDE.md 업데이트 | 완료 | `~/Documents/dev/ai/socialMakeit/CLAUDE.md` |
| collar 프로젝트 AGENTS.md 채우기 | 완료 | `AGENTS.md` |
| collar 프로젝트 .claude/settings.json | 완료 | `.claude/settings.json` |
| collar-init 글로벌 승격 프롬프트 | 완료 | `bin/collar-init` |
| 좌절 분석 보고서 | 완료 | `doc/2026-05-14-frustration-analysis.md` |
| 런타임 환경 분석 | 완료 | `doc/2026-05-14-runtime-environment-analysis.md` |
| 용어집 | 완료 | `doc/2026-05-14-glossary.md` |
| Q&A 문서 (Q11~Q14 추가) | 완료 | `doc/2026-05-14-session-qa.md` |
| 영상 기술 목록 문서화 | 완료 (Q14) | `doc/2026-05-14-session-qa.md` |
| collar 메모리 시스템 | 미구현 | - |
| collar update 명령어 | 미구현 | - |
| collar run (멀티-LLM 라우팅) | 미구현 | - |
| Paperclip 연동 | 미구현 | - |
