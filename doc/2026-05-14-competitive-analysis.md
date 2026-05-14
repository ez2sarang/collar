# collar 경쟁 분석 — Hermes Agent vs OMX vs collar
**날짜:** 2026-05-14  
**목적:** 3개 도구의 설계 철학·아키텍처 비교 → collar에 즉시 적용할 수 있는 것 추출

---

## 1. 도구 개요

| 항목 | Hermes Agent | OMX (oh-my-codex) | collar (현재) |
|------|-------------|-------------------|--------------|
| **제작** | Nous Research | 허예찬 (Yeachan-Heo) | 이 프로젝트 |
| **GitHub** | NousResearch/hermes-agent | Yeachan-Heo/oh-my-codex | - |
| **스타** | 27,000+ (2026.04) | - | - |
| **출시** | 2026.02 | 2025~2026 | 2026.05 |
| **포지션** | 개인 AI 비서 (클라우드 중심) | Codex CLI 오케스트레이션 레이어 | 프로젝트 하네스 표준화 도구 |
| **대상** | 개인 사용자 | Codex CLI 사용자 | Claude Code 프로젝트 |

---

## 2. 메모리 시스템 상세 비교

### Hermes Agent — 3-레이어 메모리
```
Layer 1: Procedural Memory (Skills)
  → 작업 완료 후 자동 Skill 생성
  → 사용 중 자동 Skill 개선 (learning loop)
  → agentskills.io 오픈 표준 호환

Layer 2: User Profiling
  → Honcho dialectic modeling
  → 사용자 패턴 학습 및 프로파일링

Layer 3: Session Memory
  → FTS5 전문 검색 인덱스
  → LLM이 세션 요약 생성
  → 세션 간 검색 및 recall
```

**특징:** 복잡한 DB 기반, 자동 Skill 생성/개선이 핵심 차별점

### OMX — 파일 기반 상태
```
.omx/
├── plans/         # 작업 계획 (프로젝트 스코프)
├── logs/          # 실행 로그
├── memory/        # 세션 메모리
└── runtime/       # 런타임 상태
```

**특징:** 경량 파일 기반. 프로젝트별 격리. 중앙 서버 없음.

### collar — 현재 구현
```
.collar/
├── memory.md          # 발견된 패턴 (Markdown)
├── session-compact.md # 압축된 세션 요약
├── session-counter    # watchdog 카운터
├── config.json        # 설정
└── hooks/
    └── session-monitor.sh  # 자동 compact 트리거
```

**특징:** 가장 단순. 허예찬 철학("문서 자체가 메모리") 반영. 런타임 컴포넌트 없음.

### 메모리 철학 비교

| | Hermes | OMX | collar |
|--|--------|-----|--------|
| 저장소 | SQLite + FTS5 | 파일 (.omx/) | 파일 (.collar/) |
| 자동 생성 | ✅ (Skill 자동 생성) | ⚠️ (워크플로우 기반) | ❌ (수동 + LLM 판단) |
| 검색 | ✅ (FTS5 전문 검색) | ❌ | ❌ |
| 세션 간 지속 | ✅ | ✅ | ✅ |
| 구현 복잡도 | 높음 | 중간 | 낮음 |
| 허예찬 철학 일치 | ❌ (과도하게 복잡) | ⚠️ | ✅ |

---

## 3. 훅/자동화 시스템 비교

### Hermes Agent
- 플랫폼별 네이티브 훅 (Telegram 봇, Discord 봇 등)
- Cron 스케줄링 내장
- MCP 서버 통합
- **자동화 수준:** 완전 자율 (클라우드 상시 실행)

### OMX — 이중 훅 레이어
```
Layer 1: Native Codex Hooks (.codex/hooks.json)
  → Codex CLI 기본 생명주기 훅

Layer 2: OMX Plugin Hooks (.omx/hooks/*.mjs)
  → 추가 런타임 경로
  → tmux watcher + notification gateway

팀 실행: tmux 기반
  → omx team 3:executor "task"  # 3개 병렬 실행
  → omx team status <name>
  → omx team resume <name>
```

**자동화 수준:** 반자율 (사용자가 워크플로우 시작, 이후 자동)

### collar — 현재 구현
```
UserPromptSubmit Hook (.claude/settings.json)
  → 메시지 카운터 증가
  → 임계값(20) 도달 시 collar-compact 자동 실행
  → COLLAR_WATCHDOG: 알림 출력 → AI가 인식

향후: GitHub 연동 (collar-github)
```

**자동화 수준:** 세션 관리 자동화 (v1). GitHub 자동화 계획 중 (v2).

---

## 4. 에이전트 팀 운영

### OMX (참조 가능한 구현)
```bash
# 3개 executor 병렬 실행
omx team 3:executor "fix all TypeScript errors"

# 상태 확인
omx team status my-task

# 재개
omx team resume my-task

# 강제 종료
omx team shutdown my-task --force
```

**collar에 적용:** collar-github가 병렬 에이전트 팀을 쓸 때 이 패턴 참조

---

## 5. collar vs 경쟁사 포지션 매트릭스

```
                    복잡도 →
단순 ←──────────────────────────── 복잡
  |
  ↓  collar          OMX         Hermes
로컬  [●]─────────────[●]──────────[●]
  |   파일기반        파일+훅     DB+클라우드
  |   프로젝트셋업    Codex확장   개인AI비서
클라우드
```

**collar의 명확한 포지션:**
- Hermes = 개인 사용자용 AI 비서 (클라우드, 복잡한 메모리)
- OMX = Codex CLI 사용자용 오케스트레이션
- **collar = Claude Code 프로젝트의 하네스 표준화 + 자동화**

셋이 직접 경쟁하지 않음. 허예찬이 OMX/OMC를 만들고, collar는 그 위에서 프로젝트 셋업을 표준화.

---

## 6. collar에 즉시 적용 가능한 것

### 🔴 즉시 (이번 세션 가능)
| 항목 | 출처 | 적용 방법 |
|------|------|----------|
| **Skill 자동 생성** | Hermes | collar-remember 이후 LLM이 "다음에 쓸 수 있는 패턴" 자동 추출 → skills/ 폴더 |
| **이중 훅 레이어** | OMX | collar-watchdog에 native hooks + collar hooks 분리 구조 도입 |

### 🟡 단기 (다음 세션)
| 항목 | 출처 | 적용 방법 |
|------|------|----------|
| **tmux 팀 패턴** | OMX | collar-github의 병렬 에이전트 실행에 tmux 기반 팀 구조 |
| **FTS5 검색** | Hermes | .collar/memory.md의 내용을 SQLite FTS5로 인덱싱하는 선택적 기능 |
| **Cron 스케줄링** | Hermes | collar-watchdog에 launchd/cron 기반 정기 compact 옵션 |

### 🟢 장기 (아키텍처 레벨)
| 항목 | 출처 | 적용 방법 |
|------|------|----------|
| **Serverless 실행** | Hermes | collar-github가 클라우드에서 상시 실행 가능하도록 |
| **agentskills.io** | Hermes | collar skill 오픈 표준 호환 고려 |
| **Honcho 사용자 프로파일링** | Hermes | 사용자별 맞춤 하네스 생성 시 참조 |

---

## 7. OMX 핵심 설계에서 배울 것

### "Codex를 대체하지 않는다" 원칙
> OMX does NOT replace Codex. It adds a better working layer around it.

→ collar도 동일: Claude Code를 대체하지 않음. 더 나은 하네스 레이어를 추가.  
→ **collar는 Claude Code 위의 레이어, Hermes는 Claude Code와 독립적**

### .omx/ 구조 = .collar/ 구조와 동일한 철학
```
OMX:     .omx/plans/ .omx/memory/ .omx/logs/
collar:  .collar/memory.md .collar/session-compact.md .collar/config.json
```
→ collar가 올바른 방향으로 설계됐음이 확인됨.

### 33개 에이전트 프롬프트 / 36개 워크플로우 스킬
→ collar도 collar-init 시 프로젝트 타입별 전문 에이전트 프롬프트 추가 가능

---

## 8. Hermes 핵심 설계에서 배울 것

### Skill 자동 생성 루프
```
작업 완료 → LLM이 "이 작업에서 배운 패턴" 추출 → skills/ 저장 → 다음 작업에서 자동 로드
```
→ collar-remember가 이미 유사한 역할. 하지만 **자동** 생성이 없음.  
→ collar-remember에 "작업 완료 후 자동 실행" 옵션 추가 시 Hermes 수준 달성 가능.

### 허예찬이 반박한 것: 복잡한 메모리 시스템
> "메모리 시스템이라는 건 구현하는데 시간이 많이 들어가는 종류의 일이 아니에요."

Hermes는 이 반박의 정반대 방향. 하지만 Hermes는 **개인 AI 비서**이기 때문에 복잡도가 정당화됨.  
collar는 **프로젝트 하네스**이므로 허예찬 철학(단순 파일 기반)이 올바른 선택.

---

## 9. 결론

| 질문 | 답 |
|------|---|
| collar가 Hermes를 따라야 하나? | ❌ 포지션이 다름. 복잡한 메모리 시스템 불필요 |
| collar가 OMX를 따라야 하나? | ✅ 이중 훅 레이어, tmux 팀 패턴은 바로 적용 가능 |
| collar의 차별점은? | 프로젝트 초기 셋업 자동화(collar-init) + GitHub 자동화 = 둘 다 없음 |
| collar가 이길 수 있는 영역? | Claude Code 사용자의 "프로젝트 하네스 즉시 설치" 니즈 |
