# collar 아키텍처 v2 — 자율 운전 + GitHub 연동
**날짜:** 2026-05-14  
**트리거:** 인터뷰 재확인 → collar 범위 대폭 확장

---

## 1. 핵심 재정의

### v1 (오해)
> collar = 프로젝트에 CLAUDE.md/AGENTS.md를 생성하는 **템플릿 도구**

### v2 (실제)
> collar = AI 세션을 **자율 운전**하고 GitHub 이슈를 **자동 처리**하는 **자율 에이전트 인프라**

**사용자가 원하는 것: 귀찮은 일은 collar가 알아서 처리한다.**
- 세션 컨텍스트가 커졌다 → collar가 자동으로 compact + 재시작
- GitHub 이슈 들어왔다 → collar가 자동으로 분석, 수정, PR 생성
- 사용자는 결과만 확인

---

## 2. 시스템 구조

```
collar/
├── 현재 구현 (v1 — 유지)
│   ├── collar-init          # 프로젝트 하네스 설치
│   ├── collar-remember      # 인사이트 기록 (LLM 자동 글로벌 판단)
│   ├── collar-update        # CLAUDE.md TODO 자동 채우기
│   └── collar-compact       # 세션 컨텍스트 압축
│
├── v2 추가 예정
│   ├── collar-watchdog      # 세션 상태 모니터링 → 자동 compact/재시작
│   ├── collar-github        # GitHub 이슈 자동 처리 파이프라인
│   └── collar-plugin        # 플러그인 인터페이스
│
└── .collar/                 # 프로젝트별 데이터
    ├── memory.md            # 학습 기록
    ├── session-compact.md   # 압축된 세션 컨텍스트
    └── config.json          # collar 설정 (임계값, GitHub 설정 등)
```

---

## 3. collar-watchdog 설계

### 역할
외부 프로세스로 ClaudeCode 세션을 모니터링. 임계값 도달 시 자동 처리.

### 트리거 조건 (config.json으로 설정 가능)
```json
{
  "watchdog": {
    "ctx_threshold": 40,        // ctx% 초과 시 compact
    "message_threshold": 20,    // 메시지 수 초과 시 compact
    "auto_restart": true        // compact 후 새 세션 자동 시작
  }
}
```

### 동작 흐름
```
watchdog 실행 중
  → ClaudeCode 세션 상태 polling (ctx%, 메시지 수)
  → 임계값 초과 감지
  → collar-compact 자동 실행
  → session-compact.md 저장 확인
  → ClaudeCode 새 세션 시작 (claude 명령 재실행)
  → 사용자에게 알림만: "세션 재시작됨. 컨텍스트 복원 완료."
```

### 구현 방법
- Claude Code hooks (PreToolUse/PostToolUse) → 메시지 카운터
- 또는 독립 watchdog 데몬 (launchd on macOS)

---

## 4. GitHub 연동 설계

### 원칙
- GitHub 미연결 → 기능 skip (에러 아님)
- paperClip은 외부 프로젝트 → collar와 독립
- collar 자체가 standalone으로 GitHub 관리

### collar-github 파이프라인
```
GitHub 이슈 생성
  → collar-github detect (webhook 또는 polling)
  → 이슈 분석 (LLM: 버그/기능/질문 분류)
  → 자동 처리:
      버그 → collar-github fix (코드 수정 → 테스트 → PR)
      기능 → collar-github feature (설계 → 구현 → PR)
      질문 → collar-github reply (자동 답변 코멘트)
  → PR 생성 + 이슈 링크
  → 사용자 리뷰 요청 (자동 머지는 설정에 따라)
```

### collar-init GitHub 연동 추가
```bash
collar-init 실행 시:
  - GitHub repo 연결 여부 확인
  - 연결 있으면: .collar/config.json에 GitHub 설정 추가
  - GitHub Actions 워크플로우 생성 (.github/workflows/collar.yml)
  - 연결 없으면: skip (나중에 collar-github setup으로 추가)
```

---

## 5. 플러그인 아키텍처

### 목적
paperClip 같은 외부 프로젝트가 collar 기능을 확장할 수 있도록.

```
collar plugin 구조:
  ~/.collar/plugins/
    └── paperclip/           # paperClip collar 플러그인
        ├── plugin.json      # 플러그인 메타데이터
        ├── hooks/           # collar 훅 확장
        └── commands/        # collar 명령어 확장

collar-init 시 플러그인 자동 감지 및 로드
```

---

## 6. 최종 비전 (PaperCompany UI)

```
PaperCompany UI (웹 대시보드)
  ↓ 제어
collar (자율 에이전트 인프라)
  ├── 세션 관리 (watchdog)
  ├── GitHub 자동화 (collar-github)
  ├── 프로젝트별 하네스 (collar-init)
  └── 학습/메모리 (collar-remember/compact)
  ↓ 실행
Claude Code 세션들 (여러 프로젝트 병렬 처리)
```

사용자는 PaperCompany에서:
- 어떤 프로젝트에서 AI가 무엇을 하고 있는지 확인
- 자동 처리 결과 리뷰 (PR, 버그 수정)
- 우선순위 지정, 중단/재개

---

## 7. 구현 우선순위

| 단계 | 항목 | 복잡도 | 가치 |
|------|------|--------|------|
| 즉시 | collar-watchdog (hooks 기반) | 중 | 높음 |
| 단기 | GitHub 연동 (collar-github) | 높음 | 매우 높음 |
| 중기 | 플러그인 아키텍처 | 중 | 중 |
| 장기 | PaperCompany UI 연동 | 높음 | 매우 높음 |

**지금 당장 만들 수 있는 것: collar-watchdog (hooks 기반)**  
Claude Code의 PostToolUse hook으로 메시지 카운터 추적 → 임계값 시 자동 compact.

---

## 8. 변경된 collar 정의

> collar는 **프로젝트 수준의 AI 자율 운전 인프라**다.  
> 세션 관리, 학습 기록, GitHub 자동화를 사용자 개입 없이 처리한다.  
> paperClip/PaperCompany의 플러그인으로 확장 가능.
