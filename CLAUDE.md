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
│   ├── collar-init        # 프로젝트 하네스 세팅 스크립트
│   ├── collar-watchdog    # 컨텍스트 임계값 감시 + 자동 compact
│   ├── collar-compact     # 세션 컨텍스트 압축 → session-compact.md
│   ├── collar-remember    # 세션 중 인사이트 기록 (LLM 자동 글로벌 판단)
│   ├── collar-update      # CLAUDE.md TODO 항목 AI로 자동 채우기
│   ├── collar-github      # GitHub 이슈 분석 + PR 자동 생성
│   └── collar-global      # 글로벌 규칙/메모리 템플릿을 ~/.claude/CLAUDE.md와 프로젝트 메모리에 LLM 중복 제거 후 병합
├── templates/             # 다른 프로젝트에 적용할 하네스 템플릿
│   ├── CLAUDE.md.base         # 공통 헌법 (모든 프로젝트)
│   ├── AGENTS.md.base         # 에이전트 가이드 템플릿
│   ├── collar-dispatcher.sh   # 훅 디스패처
│   ├── config.json            # 기본 설정 템플릿
│   ├── github-check.sh        # GitHub 체크 훅
│   └── session-monitor.sh     # 세션 모니터 훅
└── doc/                   # 설계 문서
    ├── 2026-05-14-architecture-v2.md
    ├── 2026-05-14-harness-system-plan.md
    ├── 2026-05-14-session-qa.md
    ├── 2026-05-14-memory-system-design.md
    ├── 2026-05-14-frustration-analysis.md
    ├── 2026-05-14-runtime-environment-analysis.md
    ├── 2026-05-14-competitive-analysis.md
    ├── 2026-05-14-interview-prep.md
    └── 2026-05-14-glossary.md
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

1. `.collar/session-compact.md`가 있으면 **먼저** 읽어라 (압축된 핵심 컨텍스트)
2. `.collar/memory.md`에서 최근 패턴 확인
3. session-compact.md가 없으면 memory.md 전체를 읽어라

## 세션 종료 프로토콜

1. 새 패턴 발견 시 `collar-remember "내용"` 실행
2. 대화가 길어졌다면 (메시지 10개 이상) `collar-compact` 실행
3. CLAUDE.md에 틀린 내용 있으면 직접 수정

---

## 참고 자료
- ez2claude: `~/Documents/dev/ai/ez2claude/` (글로벌 하네스 구현체)
- paperclip: `~/Documents/dev/ai/paperCompany/paperclip/` (에이전트 제어 플레인)
- 하네스 4요소: `doc/2026-05-14-harness-system-plan.md`
