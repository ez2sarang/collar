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
collar/                      # 레포 (개발 / 배포 원본)
├── setup.sh                 # 설치 스크립트 → ~/.collar/bin + templates/ 배포
│
├── v1 구현 완료
│   ├── collar-init          # 프로젝트 하네스 설치 (Swift/Kotlin/JS/Python/Rust/Go/bash)
│   ├── collar-interview     # 7문 인터뷰 + Ouroboros clarity scoring → CLAUDE.md 생성
│   │                        #   --quick / --standard(기본,72%) / --deep(82%+pressure pass)
│   ├── collar-remember      # 인사이트 기록 (LLM 자동 글로벌 판단, [y/e/v/N])
│   ├── collar-update        # CLAUDE.md TODO 자동 채우기 (preamble 오염 방지)
│   └── collar-compact       # 세션 컨텍스트 압축 (haiku 모델)
│
├── v2 구현 완료
│   ├── collar-watchdog      # 훅 기반 ctx% 감시 + 자동 compact + memory 중복 감지
│   └── collar-github        # GitHub 이슈 자동 처리 (분류→수정→review→PR)
│
├── v3 예정
│   └── collar-plugin        # 플러그인 인터페이스 (paperClip 연동용)
│
~/.collar/                   # 표준 설치 경로 (setup.sh 가 배포)
├── bin/                     # 모든 collar-* 실행 파일
├── templates/               # CLAUDE.md.base, session-monitor.sh 등
│
project/.collar/             # 프로젝트별 런타임 데이터 (collar-init 이 생성)
├── memory.md                # 학습 기록 (자동 중복 정리)
├── session-compact.md       # 압축된 세션 컨텍스트
├── config.json              # collar 설정 (임계값, GitHub 설정 등)
└── hooks/
    ├── session-monitor.sh   # ctx% 감시 + memory dedup
    └── github-check.sh      # 세션 시작 시 이슈 자동 체크
```

---

## 3. collar-watchdog 설계

### 역할
외부 프로세스로 ClaudeCode 세션을 모니터링. 임계값 도달 시 자동 처리.

### 트리거 조건 (config.json으로 설정 가능)
```json
{
  "watchdog": {
    "ctx_percent_threshold": 80,   // ctx% 초과 시 compact
    "ctx_percent_target": 15,      // compact 목표 수준
    "message_threshold": 20,       // transcript 없을 때 메시지 수 폴백
    "auto_compact": true,          // 임계값 도달 시 collar-compact 자동 실행
    "auto_restart": false,         // (전방호환) 외부 데몬/헤드리스 루프 전용 — 아래 주의 참고
    "notify": true
  }
}
```

> ⚠️ **auto_restart 주의 (구현 현실):** 훅은 자신의 부모 인터랙티브 Claude Code 세션을
> kill+respawn 할 수 없다. 따라서 "새 세션 자동 시작"은 **인터랙티브 세션에서 불가능**하다.
> 대신 `autoCompactEnabled: true`(네이티브)로 **제자리(in-place) 압축 후 세션 연속**되므로
> 재시작 자체가 불필요하다. `auto_restart`는 향후 독립 watchdog 데몬/헤드리스 `claude -p`
> 루프에서만 의미가 있으며, 인터랙티브 세션에서는 무시된다.

### 동작 흐름 (현재 구현 — 훅 기반)
```
session-monitor.sh (UserPromptSubmit/PostToolUse 훅)
  → transcript JSONL 크기로 ctx% 추정 (compact 이후 delta 기준)
  → 임계값(기본 80%) 초과 감지
  → collar-compact 자동 실행 → session-compact.md 갱신
  → transcript baseline 재설정 (다음 delta 기준점)
  → autoCompactEnabled(네이티브)가 인플레이스 압축으로 세션 연속
  → Claude에 알림: "ctx N% 초과. /compact 실행하라."
세션 종료 시 (SessionEnd 1회성 이벤트):
  → 40-session-recovery.sh → collar-compact 로 컨텍스트 보존
    (SessionEnd 는 차단 불가 → nohup 백그라운드 fire-and-forget)
  → 다음 세션 SessionStart 가 session-compact.md 자동 주입 → 복원 완료
매 턴 종료 시 (Stop 이벤트):
  → 50-todo-enforcer.sh → 미완료 TODO 가 남아있으면 계속 진행 권고
```

### 구현 방법
- **현재:** Claude Code hooks — UserPromptSubmit/PostToolUse(ctx% 감시) +
  SessionEnd(종료 시 1회 컨텍스트 보존) + Stop(매 턴 미완료 TODO 권고).
  인터랙티브 세션은 네이티브 `autoCompactEnabled`로 제자리 압축·연속(재시작 불필요).
- **향후:** 독립 watchdog 데몬(launchd) 또는 헤드리스 `claude -p` 루프 —
  이 경우에만 `auto_restart`로 실제 프로세스 재실행이 가능.

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

| 단계 | 항목 | 상태 |
|------|------|------|
| ✅ 완료 | collar-watchdog (hooks 기반, 이중 훅) | 구현 완료 (2026-05-14) |
| ✅ 완료 | collar-github (Anthropic API 직접 호출) | 구현 완료 (2026-05-14) |
| ✅ 완료 | collar-interview (대화형 7문 인터뷰) | 구현 완료 (2026-05-15) |
| ✅ 완료 | watchdog memory.md 자동 dedup | 구현 완료 (2026-05-15) |
| ✅ 완료 | collar-interview clarity scoring (Ouroboros 패턴) | 구현 완료 (2026-05-15) |
| 🔜 중기 | 플러그인 아키텍처 (collar-plugin) | 미구현 |
| 🔜 장기 | PaperCompany UI 연동 | 미구현 |

---

## 8. 변경된 collar 정의

> collar는 **프로젝트 수준의 AI 자율 운전 인프라**다.  
> 세션 관리, 학습 기록, GitHub 자동화를 사용자 개입 없이 처리한다.  
> paperClip/PaperCompany의 플러그인으로 확장 가능.
