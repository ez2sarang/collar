# collar — 하네스 엔지니어링 표준화 레이어

collar는 **프로젝트 수준의 AI 자율 운전 인프라**다.

세션 관리, 학습 기록, GitHub 자동화를 사용자 개입 없이 처리한다.
사용자가 할 일: 방향 설정과 결과 리뷰. 나머지는 collar가 알아서.

---

## 이 프로젝트의 목표

**단기:** 세션 관리 완전 자동화 (watchdog → 임계값 시 자동 compact + 재시작)

**중기:** GitHub 연동 — 이슈 자동 분석, 버그 수정, PR 생성 (미연결 시 skip)

**장기:** PaperCompany UI에서 전체 흐름 관리 (플러그인 형태로 연동)

> 상세 설계: `doc/2026-05-14-architecture-v2.md`

---

## 에이전트 규칙

### 역할 분리
- 이 프로젝트는 **도구 제작** 프로젝트다.
- 에이전트는 코드를 짜기 전 반드시 `doc/` 문서를 먼저 읽는다.
- 구현 → `executor` (sonnet), 설계 → `architect` (opus), 검토 → `code-reviewer`

### 핵심 규칙
1. collar는 자기 자신의 하네스를 가진다 (메타 프로젝트)
2. 템플릿 파일 변경 시 실제 적용 프로젝트에 영향을 확인한다
3. `collar-init` 스크립트는 멱등성(idempotent)을 유지한다 — 여러 번 실행해도 안전

### 검증 기준
- [ ] `collar-init` 후 새 프로젝트에서 AI가 맥락 없이 작업 시작 가능한가?
- [ ] 템플릿이 언어/프레임워크 무관하게 적용되는가?
- [ ] Paperclip API 연동 없이도 독립 동작하는가?

---

## 작업 구조

```
collar/
├── CLAUDE.md              # 이 파일 (collar 헌법)
├── AGENTS.md              # 에이전트 가이드
├── README.md              # 사용자를 위한 설명
├── .claude/
│   └── settings.json      # Claude Code 권한/훅 설정
├── .collar/               # 세션 상태 저장소 (session-compact.md, memory.md)
├── bin/                   # 실행 스크립트
│   ├── collar-init           # 프로젝트 하네스 설치 (언어·프로바이더 자동 감지)
│   ├── collar-interview      # 대화형 인터뷰 (Ouroboros 명확성 점수) → CLAUDE.md 생성
│   ├── collar-watchdog       # 컨텍스트 임계값 감시 + 자동 compact
│   ├── collar-compact        # 세션 컨텍스트 압축 → session-compact.md
│   ├── collar-remember       # 세션 중 인사이트 기록 (LLM 자동 글로벌 판단)
│   ├── collar-update         # CLAUDE.md TODO 항목 AI로 자동 채우기
│   ├── collar-github         # GitHub 이슈 분석 + 복잡도 기반 모델 라우팅 + PR 자동 생성
│   ├── collar-global         # 글로벌 규칙/메모리를 ~/.claude/CLAUDE.md에 LLM 중복 제거 후 병합
│   ├── collar-eval-model     # 멀티 프로바이더 모델 평가 → simple/standard/complex 카테고리 배치
│   ├── collar-usage          # Claude Max / Gemini Pro 구독 사용량 현황 요약
│   ├── collar-template-sync  # 글로벌 규칙-템플릿 갭 LLM 분석 + 자동 동기화
│   └── collar-conductor      # 관리·감독 오케스트레이터 (Executor→Verifier 루프, 합의 기반 완료)
├── package/               # npm 패키지 (collar-cli, TypeScript)
│   ├── src/cli/               # CLI 명령어 (init, setup, global, doctor)
│   ├── src/mcp/               # MCP 서버 + 상태/게이트/에이전트 도구
│   ├── src/hooks/             # 키워드 트리거 시스템
│   ├── skills/                # 스킬 정의 (ralph, ralplan, deep-interview)
│   └── prompts/               # 역할 기반 에이전트 프롬프트
├── templates/             # 다른 프로젝트에 적용할 하네스 템플릿
│   ├── CLAUDE.md.base         # 공통 헌법 (모든 프로젝트)
│   ├── AGENTS.md.base         # 에이전트 가이드 템플릿
│   ├── collar-dispatcher.sh   # 훅 디스패처
│   ├── collar-hooks/          # 보안·모니터링 훅 모음 (10/20/30/50번)
│   ├── global/                # 글로벌 규칙 + 메모리 템플릿
│   ├── config.json            # 기본 설정 템플릿
│   ├── github-check.sh        # GitHub 체크 훅
│   └── session-monitor.sh     # 세션 모니터 훅
└── doc/                   # 설계 문서
    ├── 2026-05-14-architecture-v2.md
    ├── 2026-05-14-harness-system-plan.md
    ├── 2026-05-14-session-qa.md
    ├── 2026-05-14-memory-system-design.md
    ├── 2026-05-17-npm-package-design.md
    └── 2026-05-20-eval-framework.md
```

---

## 모델 라우팅

ez2claude 글로벌 라우팅을 따른다. 추가 규칙:
- 템플릿 작성 → sonnet (빠른 반복)
- 하네스 설계 결정 → opus (한 번만)
- 검증 스크립트 → haiku (단순 실행)

---

## 완료 기준

변경은 다음 조건에서 완료:
1. `collar-init` 실행 시 오류 없음
2. 생성된 CLAUDE.md가 ez2claude 글로벌 설정과 충돌하지 않음
3. 최소 1개 실제 프로젝트에서 검증

---

## 세션 시작 프로토콜

1. `.collar/project-facts.md` — **항상** 읽어라 (포트, DB, 스택, 명령어)
2. `.collar/session-compact.md`가 있으면 읽어라 (압축된 핵심 컨텍스트)
3. `.collar/memory.md`에서 최근 패턴 확인
4. session-compact.md가 없으면 memory.md 전체를 읽어라

## 세션 종료 프로토콜

1. 새 패턴 발견 시 `collar-remember "내용"` 실행
2. 대화가 길어졌다면 (메시지 10개 이상) `collar-compact` 실행
3. CLAUDE.md에 틀린 내용 있으면 직접 수정

---

## 참고 자료
- ez2claude: `~/Documents/dev/ai/ez2claude/` (글로벌 하네스 구현체)
- paperclip: `~/Documents/dev/ai/paperCompany/paperclip/` (에이전트 제어 플레인)
- 하네스 4요소: `doc/2026-05-14-harness-system-plan.md`

## 요청사항 체크리스트 의무 관리 (모든 프로젝트 공통)

**요청에 2개 이상의 독립 작업** 또는 **다단계 구현**이 포함되면, 작업 시작 전 반드시 아래 절차를 따른다.

### 1단계: 요청 분석 표 (작업 시작 전 사용자에게 보여주기)

요청을 받으면 먼저 **표로 정리**해서 누락 없이 확인하라:

| # | 요청 항목 | 구현 방법 | 대상 위치 | 완료 |
|---|----------|---------|---------|------|
| 1 | ...      | ...     | ...     | [ ] |

### 2단계: 작업 추적 문서 생성

`.collar/tasks/` 가 있으면 거기에, 없으면 `.tasks/` 디렉토리에 `YYYYMMDD-HHMM-<요약>.md` 파일 생성:

```
# [날짜] 요청 요약

## 요청 원문 요약
[사용자 요청 핵심 내용]

## 체크리스트
- [ ] 항목 1: 상세 설명
- [ ] 항목 2: 상세 설명

## 구현 계획
| # | 항목 | 방법 | 파일/위치 |
|---|------|------|---------|

## 진행 로그
- [HH:MM] 항목 1 완료
```

### 3단계: 진행 중 체크

각 항목 완료 시마다 파일의 `[ ]` → `[x]` 업데이트. **파일 수정 없이 머릿속으로만 체크 금지.**

### 4단계: 완료 선언 조건

- 모든 `[ ]` → `[x]` 전환 확인 후에만 완료 선언
- 완료 선언 시 체크리스트 파일 경로 명시
- 미완료 항목이 남아있으면 완료 선언 불가

### 단일 항목 요청 예외

한 줄 요청이나 명확한 단일 작업은 문서 생성 생략 가능. 단, 작업 중 추가 항목이 발견되면 즉시 문서 생성.

## 규칙 추가 전 실행 가능성 검증 의무 (모든 프로젝트 공통)

CLAUDE.md에 새로운 자동화 규칙·훅 동작·슬래시 커맨드를 추가하기 전에 반드시 검증하라.

**검증 질문:**
1. 이 동작을 Claude(AI 모델)가 직접 실행할 수 있는가?
2. 아니면 Claude Code(클라이언트)가 실행해야 하는가?
3. 훅 스크립트(bash)가 실행해야 하는가?

**금지 패턴:**
- Claude가 `/compact`, `/clear` 등 슬래시 커맨드를 직접 실행하게 하는 규칙 → 구조상 불가
- 훅 출력 메시지만으로 Claude가 자동으로 시스템 명령을 실행하게 하는 규칙

**올바른 접근:**
- Claude가 직접 못 하는 것 → Claude Code 네이티브 설정(settings.json)으로 처리
- 예: `autoCompactEnabled: true` (Claude Code가 compact 실행)

실패 사례: `/compact` 자동 실행 규칙을 CLAUDE.md에 2번 추가했다가 2번 revert (2026-05-29)

---

## 반복 위반 → 강제 전환 원칙 (모든 프로젝트 공통)

같은 규칙이 2회 이상 위반되면 텍스트 규칙은 효과 없음으로 판정하고 즉시 강제 수단으로 전환한다.

| 위반 횟수 | 대응 |
|----------|------|
| 1회 | CLAUDE.md에 텍스트 규칙 추가 |
| 2회 | 훅 스크립트(~/.claude/hooks/)로 자동 차단 |
| 3회+ | 훅 차단 + 사용자에게 즉시 보고 의무 |

근거: socialMakeit 세션 분석 결과, CDP 탭 닫힘 규칙이 텍스트로 명시됐음에도 6회+ 반복 위반됨 (2026-05-29 분석).

## UI/프론트엔드 변경 시 브라우저 실제 확인 의무

UI 컴포넌트, CSS, 레이아웃, 차트, 테이블 등 시각적 변경 후 반드시 브라우저 실제 렌더링 확인.
스크린샷: `uv run --with patchright python3 ~/.collar/bin/browser-test.py http://localhost:<PORT> /tmp/ui-check.png --cdp=http://localhost:9222`
코드만 보고 완료 선언 금지. 근거: investments revert 사고 (2026-05-29).

## 외부 API 공식 문서 우선 원칙

외부 API 사용 코드 작성 전 반드시 공식 문서 확인 (파라미터, 응답 형식, 인증).
추측으로 API 구현 금지. 근거: KIS API 스펙 미확인 → 연쇄 수정 4회 (investments 2026-05-29).

## 모듈 구조 변경 시 영향도 분석 의무

함수 이동, 파일 분리 등 구조 변경 시 반드시 import 영향도 먼저 분석:
`grep -r "from.*모듈명\|import.*심볼명"` 로 전체 참조 확인 후 변경.
영향도 미분석 후 변경 금지. 근거: investments 모듈 분리 오류 (2026-05-29).

## Opus 강제 트리거 실제 준수

근거/소스레벨/심도/전략/분석/왜 키워드가 있는 요청은 즉시 Opus 사용.
Sonnet으로 시작 후 재요청 받는 패턴 금지. 근거: investments 분석 품질 저하 사고 (2026-05-29).
