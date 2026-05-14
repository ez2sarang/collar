# collar

> **AI 자율 운전 인프라.** 세션 관리·학습·GitHub 자동화를 사용자 개입 없이 처리한다.

---

## 핵심 철학

사용자가 할 일: **방향 설정 + 결과 리뷰**. 나머지는 collar가 알아서.

- 컨텍스트 창이 60%를 넘으면 → 자동 압축, 다음 세션 준비
- 세션 중 발견한 패턴 → 자동으로 전역 규칙으로 승격 판단
- GitHub 이슈가 열리면 → 자동 분류, 버그는 PR까지 자동 생성
- 새 프로젝트 → `collar-init` 하나로 AI 하네스 10초 설치

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
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐ │
│  │ 세션 관리   │  │ 학습 기록    │  │ GitHub 자동화  │ │
│  │ watchdog    │  │ remember     │  │ collar-github  │ │
│  └─────────────┘  └──────────────┘  └────────────────┘ │
├─────────────────────────────────────────────────────────┤
│                   Claude Code (CLI)                      │
└─────────────────────────────────────────────────────────┘
```

---

## 빠른 시작

```bash
# 1. PATH 추가
export PATH="$HOME/path/to/collar/bin:$PATH"

# 2. 프로젝트 하네스 설치
cd my-project
collar-init

# 3. 세션 자동 관리 활성화
collar-watchdog

# 4. GitHub 자동화 연결 (선택)
collar-github setup
collar-github watch   # 세션 시작마다 이슈 자동 체크
```

---

## 도구 목록

| 도구 | 역할 |
|------|------|
| `collar-init` | 프로젝트 하네스 설치 (CLAUDE.md + AGENTS.md + .claude/settings.json) |
| `collar-watchdog` | ctx% 모니터링 훅 설치 → 60% 초과 시 자동 compact |
| `collar-compact` | 세션 컨텍스트 압축 → `.collar/session-compact.md` |
| `collar-remember` | 발견한 패턴 기록 → LLM이 전역 승격 여부 자동 판단 |
| `collar-update` | CLAUDE.md TODO 항목 AI 자동 채우기 |
| `collar-github` | GitHub 이슈 자동 분류·처리·PR 생성 |

---

## 이중 훅 구조 (OMX 패턴)

collar는 Claude Code 훅을 두 레이어로 분리한다.

```
Layer 1 (Native)    .claude/settings.json
                    └─ UserPromptSubmit / SessionStart
                           └─ collar-dispatcher.sh  ← thin router

Layer 2 (Collar)    .collar/hooks/
                    ├─ session-monitor.sh   ctx% 감시 + 자동 compact
                    └─ github-check.sh      세션 시작 시 GitHub 이슈 체크
```

새 기능 훅은 `.collar/hooks/`에 파일 하나만 추가하면 자동 등록.

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
| **Bash/Shell** | `*.sh` 파일 / `bin/` shebang | `shellcheck bin/*` |
| Java | `pom.xml` / `build.gradle` | — |
| 기타 | — | TODO 직접 입력 |

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
# → 이후 Claude Code 세션 시작마다 미처리 이슈 자동 확인
```

처리 흐름:
```
이슈 수집 → LLM 분류 (bug/feature/question)
  bug      → 코드 분석 → 수정 → PR 자동 생성
  feature  → 로드맵 기록 (레벨3: PR까지)
  question → 자동 답변 댓글
→ .collar/github-processed.log 기록
```

---

## 레포 구조

```
collar/
├── bin/
│   ├── collar-init        프로젝트 하네스 설치
│   ├── collar-watchdog    세션 모니터링 훅 설치
│   ├── collar-compact     컨텍스트 압축
│   ├── collar-remember    패턴 기록 + 전역 승격
│   ├── collar-update      CLAUDE.md 자동 업데이트
│   └── collar-github      GitHub 자동화 파이프라인
├── templates/
│   ├── CLAUDE.md.base         공통 헌법 템플릿
│   ├── AGENTS.md.base         에이전트 가이드 템플릿
│   ├── collar-dispatcher.sh   이중 훅 Layer 1 라우터
│   ├── session-monitor.sh     ctx% 감시 훅
│   ├── github-check.sh        GitHub 체크 훅
│   └── config.json            기본 설정 템플릿
├── doc/                   설계 문서
├── CLAUDE.md              collar 자체 헌법
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
| Claude Code 전용 | ❌ | ❌ (Codex 전용) | ✅ |

---

## 요구 사항

- macOS / Linux
- [Claude Code CLI](https://claude.ai/code)
- Python 3 (훅 스크립트)
- `gh` CLI (GitHub 자동화 사용 시): `brew install gh`

---

## 문의

도입 상담, 커스터마이징, 엔터프라이즈 연동 문의:

**sales@com.dooray.com**

---

*collar는 Claude Code를 대체하지 않는다. 더 나은 하네스 레이어를 추가한다.*
