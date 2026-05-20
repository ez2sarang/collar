# collar

> **AI 자율 운전 인프라.** 세션 관리·학습·GitHub 자동화를 사용자 개입 없이 처리한다.

---

## 핵심 철학

사용자가 할 일: **방향 설정 + 결과 리뷰**. 나머지는 collar가 알아서.

- 컨텍스트 창이 60%를 넘으면 → 자동 압축, 다음 세션 준비
- 세션 중 발견한 패턴 → 자동으로 전역 규칙으로 승격 판단
- GitHub 이슈가 열리면 → 자동 분류, 버그는 PR까지 자동 생성
- 새 프로젝트 → `collar-init` 하나로 AI 하네스 10초 설치
- 모델 성능 측정 → `collar-eval-model`로 작업 유형별 최적 모델 자동 배치

---

## 구조

```
collar = Claude Code 위의 하네스 레이어
         (Claude Code를 대체하지 않는다. 더 나은 컨텍스트를 추가한다)

┌─────────────────────────────────────────────────────────┐
│                       사용자                             │
│           방향 설정 + 결과 리뷰만                          │
├─────────────────────────────────────────────────────────┤
│                      collar                              │
│  ┌──────────────┐ ┌──────────────┐ ┌─────────────────┐  │
│  │ 세션 관리    │ │ 학습 기록    │ │ GitHub 자동화   │  │
│  │ watchdog     │ │ remember     │ │ collar-github   │  │
│  └──────────────┘ └──────────────┘ └─────────────────┘  │
│  ┌──────────────┐ ┌──────────────┐ ┌─────────────────┐  │
│  │ 모델 평가    │ │ 글로벌 규칙  │ │ npm 패키지      │  │
│  │ eval-model   │ │ collar-global│ │ collar-cli      │  │
│  └──────────────┘ └──────────────┘ └─────────────────┘  │
├─────────────────────────────────────────────────────────┤
│                   Claude Code (CLI)                      │
└─────────────────────────────────────────────────────────┘
```

---

## 빠른 시작

```bash
# 1. 설치 (~/.collar/bin 에 배포)
git clone https://github.com/ez2sarang/collar.git
cd collar && bash setup.sh
# → PATH 자동 등록 안내 (zsh/bash rc 파일에 한 줄 추가)

# 2. 프로젝트 하네스 설치
cd my-project
collar-init

# 3. 세션 자동 관리 활성화
collar-watchdog

# 4. GitHub 자동화 연결 (선택)
collar-github setup
collar-github watch   # 세션 시작마다 이슈 자동 체크
```

또는 npm 패키지로:

```bash
npm install -g collar-cli
collar setup
collar init
```

---

## 핵심 사용자 경험 흐름

collar를 처음 도입하면 3단계를 거친다.

```
1단계: 초기화 (~10초)
────────────────────────────────────────────
$ collar-init                  # 하네스 설치 (언어·프로바이더 자동 감지)
$ collar-watchdog              # 세션 자동 관리 등록
$ collar-github setup          # GitHub 연동 (선택)

2단계: 인터뷰 (~5~10분, 최초 1회)
────────────────────────────────────────────
$ collar-interview             # standard 모드 (기본값)
$ collar-interview --deep      # 고강도: 82% 명확성 + pressure pass 필수
$ collar-interview --quick     # scoring 없이 7문만
$ collar-interview --dry-run   # 구조 검증용 미리보기

  7개 질문 + Ouroboros 명확성 점수 기반 자동 follow-up:
  - 이 프로젝트가 무엇인가? (목적, 사용자)
  - 배포 환경은? (Vercel / AWS / 앱스토어 등)
  - 우선순위는? (기능구현 / 안정성 / 코드품질)
  - AI가 절대 하면 안 되는 것은?
  - 성공 기준과 테스트 명령어는?

  → LLM이 7개 차원을 점수화, 약한 차원에 자동 follow-up 질문
  → --deep: 가장 취약한 가정에 pressure pass (압박 재질문) 1회 추가
  → 답변 기반 CLAUDE.md 생성 + 인터뷰 기록 doc/ 저장
  → 이후 모든 세션에서 AI가 이 맥락으로 시작한다.

$ collar-update                # AI가 CLAUDE.md TODO 항목만 자동 채우기

3단계: 자동화 (이후 사용자 개입 없음)
────────────────────────────────────────────
  컨텍스트 창 60% 초과 → 자동 압축 + 다음 세션 준비
  세션 중 발견한 패턴 → LLM이 자동으로 전역 규칙으로 승격
  GitHub 이슈 등록 → 분류 + 버그 PR 자동 생성
  새 세션 시작 → session-compact.md 로드 → 즉시 맥락 복원
```

---

## 도구 목록

| 도구 | 역할 |
|------|------|
| `collar-init` | 프로젝트 하네스 설치 (CLAUDE.md + AGENTS.md + .claude/settings.json). 언어·프레임워크·AI 프로바이더 자동 감지 |
| `collar-interview` | 대화형 인터뷰 (7문 + Ouroboros 명확성 점수 + follow-up) → 프로젝트 맞춤 CLAUDE.md 생성 (`--quick/--standard/--deep`) |
| `collar-watchdog` | ctx% 모니터링 훅 설치 → 60% 초과 시 자동 compact |
| `collar-compact` | 세션 컨텍스트 압축 → `.collar/session-compact.md` |
| `collar-remember` | 발견한 패턴 기록 → LLM이 전역 승격 여부 자동 판단 |
| `collar-update` | CLAUDE.md TODO 항목 AI 자동 채우기 |
| `collar-github` | GitHub 이슈 자동 분류·처리·PR 생성. 이슈 복잡도 기반 모델 자동 라우팅 |
| `collar-global` | 템플릿 규칙/메모리를 `~/.claude/CLAUDE.md`와 프로젝트 메모리에 LLM 중복 제거 후 병합 (`--force`로 일괄 배포) |
| `collar-eval-model` | Claude/Gemini/Cerebras 모델을 3차원 평가 (정확성·사고력·속도) → simple/standard/complex 카테고리 자동 배치 |
| `collar-usage` | Claude Max / Gemini Pro 구독 사용량 현황 요약 (날짜별·프로바이더별·모델별) |
| `collar-template-sync` | 글로벌 규칙과 프로젝트 메모리의 갭을 LLM으로 분석 → 템플릿 자동 업데이트 |

---

## 글로벌 vs 프로젝트별 작동

collar는 두 레벨에서 독립적으로 동작한다.

```
글로벌 레벨 (~/.claude/)
  적용 범위: 모든 프로젝트
  ├── CLAUDE.md          공통 규칙 (완료 3단계, 모호한 표현 차단 등)
  ├── settings.json      collar-dispatcher 전역 등록
  └── hooks/             공급망 보안, 메모리 쓰기 가드 등 공통 훅

프로젝트 레벨 (.collar/)
  적용 범위: 해당 프로젝트만
  ├── memory.md          이 프로젝트에서 발견된 패턴
  ├── session-compact.md 세션 간 컨텍스트 전달 (압축본)
  ├── config.json        watchdog/github 설정
  ├── github.json        GitHub 레포 연결 정보
  └── hooks/             프로젝트 전용 훅
```

글로벌 규칙은 한 번 설정하면 모든 프로젝트에 자동 적용된다.  
프로젝트 메모리는 해당 레포에만 격리되어 다른 프로젝트와 간섭하지 않는다.

---

## 메모리 관리 — 반복적인 LLM 실수 방지

AI가 같은 실수를 반복하는 가장 큰 원인은 **세션 간 컨텍스트 단절**이다.  
collar는 두 가지 메커니즘으로 이를 해결한다.

```
패턴 기록 (collar-remember)
  세션 중 AI가 실수 또는 발견을 감지하면:
  $ collar-remember "xargs -I{}는 macOS에서 파이프라인 안에서 불안정"
  
  → LLM이 자동 판단:
    confidence ≥ 8점  →  글로벌 CLAUDE.md에 자동 추가 (모든 프로젝트 방지)
    confidence 5~7점  →  사용자 확인 후 추가 [y/e/v/N]
    confidence < 5점  →  프로젝트 memory.md에만 기록

세션 컨텍스트 압축 (collar-compact / collar-watchdog)
  세션이 길어지면 (ctx 60%+):
  → memory.md + CLAUDE.md 핵심만 추출 → session-compact.md 저장
  → 다음 세션 시작 시 이것만 로드 → 토큰 절약 + 맥락 유지

결과:
  - 같은 실수 → 두 번 다시 발생하지 않는다
  - 각 프로젝트의 특수 규칙이 세션마다 자동 로드된다
  - 글로벌 패턴은 모든 프로젝트에서 자동 적용된다
```

---

## 모델 평가 프레임워크 (collar-eval-model)

작업 유형에 맞는 모델을 자동으로 찾는다.

```bash
# 모델 평가
collar-eval-model                    # 현재 기본 모델 평가
collar-eval-model --compare          # Claude vs Gemini vs Cerebras 비교
collar-eval-model --provider gemini  # 특정 프로바이더 지정

# 결과 조회 및 적용
collar-eval-model --report           # 저장된 평가 결과 조회
collar-eval-model --apply --latest   # 최신 평가 결과로 라우팅 자동 적용
```

평가 체계:

| 카테고리 | 기준 | 판단 기준 |
|---------|------|---------|
| **simple** | 오타·1줄 수정 | 정확성 60% + 속도 40% |
| **standard** | 일반 버그·기능 추가 | 정확성 70% + 속도 30% |
| **complex** | 아키텍처·보안·마이그레이션 | 정확성 85% + 속도 15% |

- Judge: Gemini Flash가 정확성·사고력 채점 (자가심사 편향 제거)
- 결과 저장: `~/.collar/eval-results/`
- 라우팅 적용: `~/.collar/model-routing.json`

---

## 보안 훅 (자동 차단)

collar는 위험한 명령어를 hooks 레이어에서 자동 차단한다.

```
20-destructive-guard.sh (PreToolUse):
  차단 대상: db reset, rm -rf, git reset --hard, DROP TABLE, format 등
  → 사용자 승인 없이 자동 실행 불가

30-commit-guard.sh (PreToolUse):
  차단 대상: git push --force, git push (미확인)
  → push 전 확인 요구

10-session-ctx.sh (UserPromptSubmit):
  → ctx% 감시, 60% 초과 시 자동 compact 트리거
```

---

## GitHub 자동화 파이프라인

```bash
# 1. 설정
collar-github setup
# → 레포 URL 입력, 자동처리 레벨 선택
#   레벨 1: 분류 + 라벨 + 댓글 (안전)
#   레벨 2: + 버그 자동 수정 PR (권장)
#   레벨 3: + 기능 PR 자동 생성 (공격적)

# 2. 수동 실행
collar-github run

# 3. 세션 자동 실행 등록
collar-github watch
```

처리 흐름:
```
이슈 수집 → LLM 분류 (bug/feature/question)
  bug      → 코드 분석 → 수정 → PR 자동 생성
  feature  → 로드맵 기록 (레벨3: PR까지)
  question → 자동 답변 댓글

이슈 복잡도 자동 판단:
  simple   → Haiku (max-turns: 10)
  standard → Sonnet (max-turns: 20)
  complex  → Opus (max-turns: 30)

→ .collar/github-processed.log 기록
```

---

## 이중 훅 구조

collar는 Claude Code 훅을 두 레이어로 분리한다.

```
Layer 1 (Native)    .claude/settings.json
                    └─ UserPromptSubmit / SessionStart / PreToolUse
                           └─ collar-dispatcher.sh  ← thin router

Layer 2 (Collar)    .collar/hooks/
                    ├─ 10-session-ctx.sh    ctx% 감시 + 자동 compact
                    ├─ 20-destructive-guard.sh  파괴적 명령어 차단
                    ├─ 30-commit-guard.sh   push 전 확인
                    ├─ 50-todo-enforcer.sh  TODO 강제 처리
                    └─ github-check.sh      세션 시작 시 GitHub 이슈 체크
```

새 기능 훅은 `.collar/hooks/`에 파일 하나만 추가하면 자동 등록.

---

## npm 패키지 (collar-cli)

TypeScript 기반 공식 npm 패키지.

```bash
npm install -g collar-cli
collar setup    # 글로벌 설정 (MCP + hooks)
collar init     # 프로젝트 초기화
collar doctor   # 설치 상태 검증
collar global --force  # 전체 프로젝트 일괄 배포
```

### MCP 서버

```bash
collar mcp-serve
```

| MCP 도구 | 기능 |
|---------|------|
| `collar_state_write` | 모드 상태 저장 |
| `collar_state_read` | 모드 상태 조회 |
| `collar_gate_check` | 완료 게이트 확인 |
| `collar_spawn_agent` | 에이전트 프롬프트 준비 |

### 스킬 시스템

키워드 트리거로 활성화:

| 키워드 | 스킬 | 기능 |
|--------|------|------|
| `$ralph` | ralph | 집중 실행 루프 (작업 완료까지 반복) |
| `$ralplan` | ralplan | 다중 에이전트 합의 기반 계획 |
| `$deep-interview` | deep-interview | 자기 성찰 + 패턴 학습 |

---

## 지원 프로젝트 타입

`collar-init`이 자동 감지:

| 타입 | 감지 조건 | 검증 명령 |
|------|----------|----------|
| Next.js | `package.json`에 `"next"` | `pnpm typecheck && pnpm build` |
| React | `package.json`에 `"react"` | `pnpm typecheck && pnpm build` |
| Node.js API | express / fastify / hono | `pnpm typecheck && pnpm build` |
| Python | `pyproject.toml` / `requirements.txt` | `uv run pytest` |
| Rust | `Cargo.toml` | `cargo test && cargo clippy` |
| Go | `go.mod` | `go test ./... && go vet` |
| Bash/Shell | `*.sh` 파일 / `bin/` shebang | `shellcheck bin/*` |
| Swift | `Package.swift` / `.xcodeproj` | `swift build` |
| Kotlin | `build.gradle.kts` | `./gradlew build` |
| Java | `pom.xml` / `build.gradle` | — |
| 기타 | — | TODO 직접 입력 |

---

## 레포 구조

```
collar/
├── bin/                   핵심 CLI 스크립트 (Shell)
│   ├── collar-init        프로젝트 하네스 설치
│   ├── collar-interview   대화형 인터뷰 → 맞춤 CLAUDE.md 생성
│   ├── collar-watchdog    세션 모니터링 훅 설치
│   ├── collar-compact     컨텍스트 압축
│   ├── collar-remember    패턴 기록 + 전역 승격
│   ├── collar-update      CLAUDE.md 자동 업데이트
│   ├── collar-github      GitHub 자동화 파이프라인
│   ├── collar-global      글로벌 규칙/메모리 일괄 배포
│   ├── collar-eval-model  멀티 프로바이더 모델 평가
│   ├── collar-usage       구독 사용량 모니터
│   └── collar-template-sync  템플릿-규칙 갭 분석 + 자동 동기화
├── package/               npm 패키지 (TypeScript)
│   ├── src/cli/           CLI 명령어 (init, setup, global, doctor)
│   ├── src/mcp/           MCP 서버 + 도구
│   ├── src/hooks/         키워드 트리거
│   ├── skills/            스킬 정의 (ralph, ralplan, deep-interview)
│   └── prompts/           역할 기반 에이전트 프롬프트
├── templates/             하네스 템플릿
│   ├── CLAUDE.md.base         공통 헌법 템플릿
│   ├── AGENTS.md.base         에이전트 가이드 템플릿
│   ├── collar-dispatcher.sh   이중 훅 Layer 1 라우터
│   ├── collar-hooks/          보안·모니터링 훅 모음
│   ├── global/                글로벌 규칙 + 메모리 템플릿
│   ├── session-monitor.sh     ctx% 감시 훅
│   └── config.json            기본 설정 템플릿
├── doc/                   설계 문서
│   ├── 2026-05-14-architecture-v2.md
│   ├── 2026-05-14-harness-system-plan.md
│   ├── 2026-05-17-npm-package-design.md
│   └── 2026-05-20-eval-framework.md
├── CLAUDE.md              collar 자체 헌법 (이 레포 개발 규칙)
└── AGENTS.md              에이전트 가이드
```

---

## 경쟁 도구 비교

| | Hermes Agent | OMX | **collar** |
|--|-------------|-----|-----------|
| 포지션 | 개인 AI 비서 (클라우드) | Codex 오케스트레이션 | Claude Code 프로젝트 하네스 |
| 메모리 | SQLite + FTS5 (복잡) | 파일 기반 | 파일 기반 (단순) |
| 프로젝트 셋업 | ❌ | ❌ | ✅ collar-init |
| GitHub 자동화 | ❌ | ❌ | ✅ collar-github |
| 모델 평가/라우팅 | ❌ | ❌ | ✅ collar-eval-model |
| 보안 훅 | ❌ | ❌ | ✅ 파괴적 명령어 자동 차단 |
| Claude Code 전용 | ❌ | ❌ (Codex 전용) | ✅ |

---

## 현재 기술 의존성 및 로드맵

**현재 (v1~v2):**

| 기능 | 현재 의존 | 이유 |
|------|---------|------|
| 세션 모니터링 | gstack, OMC | 훅 오케스트레이션, 스킬 시스템 |
| 모델 라우팅 | OMC (oh-my-claudecode) | opus/sonnet/haiku 자동 선택 |
| 에이전트 팀 | OMC `Team` | 병렬 에이전트 실행 |

gstack/OMC가 없는 환경에서도 core 기능(collar-init, collar-watchdog, collar-github)은 독립적으로 동작한다.

**향후 비전 (v3+):**

```
현재:  collar → gstack/OMC → Claude Code
목표:  collar → Claude Code (직접)

로드맵:
  - collar-watchdog: Claude Code 기본 훅만으로 완전 자율화 ← 진행 중
  - collar-github:   Claude API 직접 호출 + gh CLI           ← 진행 중
  - collar-team:     Claude Code Agent Teams API 직접 활용  ← 계획
  - 글로벌 배포:    npm/brew 패키지로 완전 자동화            ← 진행 중
```

---

## 요구 사항

- macOS / Linux
- [Claude Code CLI](https://claude.ai/code)
- Python 3 (훅 스크립트)
- `gh` CLI (GitHub 자동화 사용 시): `brew install gh`
- Node.js 18+ (npm 패키지 사용 시)

---

*collar는 Claude Code를 대체하지 않는다. 더 나은 하네스 레이어를 추가한다.*
