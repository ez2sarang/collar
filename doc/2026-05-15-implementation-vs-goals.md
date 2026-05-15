# collar 구현 현황 분석 — 목표 대비 실제 구현 + Hermes Agent 비교
**날짜:** 2026-05-15  
**목적:** 원래 계획한 4-Phase 목표 대비 실제 구현 상태 점검 + Hermes Agent 심층 비교

---

## 1. 원래 목표 vs 현재 구현 상태

### Phase 1: 하네스 표준 문서 (목표: 1주)

| 항목 | 목표 | 상태 | 비고 |
|------|------|------|------|
| `templates/CLAUDE.md.base` | 공통 헌법 템플릿 | ✅ 완료 | 208줄 → 56줄로 슬림화 |
| `templates/AGENTS.md.base` | 에이전트 가이드 템플릿 | ✅ 완료 | — |
| `templates/CLAUDE.md.nodejs` | Node.js 특화 | ❌ 미구현 | collar-init이 타입 감지만 |
| `templates/CLAUDE.md.python` | Python 특화 | ❌ 미구현 | — |
| `templates/AGENTS.md.team` | 팀 에이전트 패턴 | ❌ 미구현 | — |

**평가:** 기본 템플릿은 완료. 언어별 특화 템플릿은 미구현.

---

### Phase 2: collar init CLI (목표: 2주)

| 항목 | 목표 | 상태 | 비고 |
|------|------|------|------|
| 프로젝트 타입 감지 | Node.js, Python, Rust 등 | ✅ 완료 | Swift, Kotlin 포함 8가지 |
| CLAUDE.md 생성 | 적절한 템플릿으로 | ✅ 완료 | — |
| AGENTS.md 생성 | — | ✅ 완료 | — |
| `.collar/` 디렉토리 구조 생성 | hooks/, config.json 등 | ✅ 완료 | — |
| collar-watchdog 자동 설치 | — | ✅ 완료 | — |
| collar-update 자동 실행 | — | ✅ 완료 | — |
| collar-github 선택 연동 | — | ✅ 완료 | 인터랙티브 [y/N] |
| collar-interview 안내 | — | ✅ 완료 (2026-05-15) | — |
| 글로벌 ~/.claude/CLAUDE.md 통합 | 계획 외 추가 | ✅ 완료 | opt-in 방식 |
| 멱등성 (여러 번 실행 안전) | — | ✅ 완료 | — |

**평가:** Phase 2는 목표 초과 달성. collar-interview 연동과 글로벌 통합은 계획 외 추가.

---

### Phase 3: Paperclip 연동 (목표: 3주)

| 항목 | 목표 | 상태 | 비고 |
|------|------|------|------|
| Paperclip API 태스크 체크아웃 | — | ❌ 미구현 | — |
| 완료 시 자동 검증 후 보고 | — | ❌ 미구현 | — |
| 신뢰 점수 연동 | — | ❌ 미구현 | — |
| 비용 추적 | — | ❌ 미구현 | — |

**평가:** Phase 3 전체 미구현. Paperclip 프로젝트 자체가 진행 중이므로 의존성 문제.

---

### Phase 4: 메모리/학습 시스템 (목표: 4주)

| 항목 | 목표 | 상태 | 비고 |
|------|------|------|------|
| 성공 패턴 자동 추출 | — | ⚠️ 부분 | collar-remember 수동 기록 |
| 템플릿화 | — | ❌ 미구현 | — |
| 실패 패턴 자동 차단 hooks | — | ⚠️ 부분 | CLAUDE.md 규칙으로 대체 |
| gstack learnings 확장 | — | ❌ 미구현 | — |

**평가:** Phase 4는 단순화된 형태로만 구현. 자동 학습 루프 없음.

---

### 계획 외 추가 구현 (Bonus)

| 항목 | 설명 |
|------|------|
| `collar-interview` | 7단계 대화형 인터뷰 + Ouroboros clarity scoring → CLAUDE.md 자동 생성 |
| `collar-compact` | 세션 컨텍스트 압축 → session-compact.md |
| `collar-watchdog` | ctx% 임계값 감시 + 자동 compact |
| `collar-github` | GitHub 이슈 자동 분류·처리·PR 생성 (Level 1~2) |
| `templates/collar-dispatcher.sh` | 이중 훅 Layer 1 라우터 |
| `templates/session-monitor.sh` | ctx% 기반 watchdog |
| `templates/github-check.sh` | SessionStart 시 GitHub 이슈 체크 |
| `setup.sh` / `install.sh` | 자동 설치 스크립트 |
| 글로벌 CLAUDE.md 통합 | 공통 규칙 중앙화 |

---

## 2. collar vs Hermes Agent 심층 비교

> Hermes Agent: NousResearch, 2026.02 출시, 27,000+ GitHub Stars

### 2.1 포지션 & 철학

| 항목 | Hermes Agent | collar |
|------|-------------|--------|
| **포지션** | 개인 AI 비서 (클라우드 상시 실행) | 프로젝트 하네스 표준화 도구 |
| **대상** | 개인 사용자 (Telegram/Discord 등) | Claude Code 프로젝트 개발팀 |
| **철학** | 복잡하고 강력한 영속 에이전트 | 단순 파일 기반, 런타임 없음 |
| **의존성** | 클라우드 서버, DB, 외부 플랫폼 | bash, Python3만 필요 |
| **설치** | 클라우드 배포 필요 | `bash setup.sh` 10초 완료 |

**포지션 결론:** 직접 경쟁하지 않음. Hermes는 "AI를 상시 실행"하는 비서, collar는 "AI가 일할 환경"을 구성.

---

### 2.2 메모리 시스템 비교

| 항목 | Hermes Agent | collar |
|------|-------------|--------|
| **저장소** | SQLite + FTS5 전문 검색 | Markdown 파일 (.collar/) |
| **자동 생성** | ✅ 작업 완료 후 Skill 자동 생성 | ❌ collar-remember로 수동 기록 |
| **검색** | ✅ FTS5 전문 검색 | ❌ 없음 (직접 읽기) |
| **세션 지속** | ✅ DB 영속 | ✅ session-compact.md |
| **사용자 프로파일링** | ✅ Honcho dialectic modeling | ❌ 없음 |
| **구현 복잡도** | 높음 | 낮음 |

**collar 격차:** 자동 Skill 생성 루프와 FTS5 검색이 없음.  
**collar 강점:** 런타임 없이 파일만으로 동작 → 설치 간단, 프라이버시 보호.

---

### 2.3 자동화 수준 비교

| 항목 | Hermes Agent | collar |
|------|-------------|--------|
| **실행 모델** | 클라우드 상시 실행 (24/7) | 세션 중에만 동작 |
| **훅 시스템** | 플랫폼 네이티브 (Telegram/Discord) | Claude Code 생명주기 훅 |
| **Cron 스케줄링** | ✅ 내장 | ❌ 없음 |
| **GitHub 자동화** | ✅ (이슈 → PR 자동) | ✅ collar-github (Level 1~2) |
| **세션 관리** | ✅ 자동 | ✅ collar-watchdog + compact |
| **MCP 통합** | ✅ 내장 | ❌ 없음 (Claude Code MCP 의존) |

**collar 격차:** 상시 실행 불가. Cron 스케줄링 없음.  
**collar 강점:** Claude Code 생명주기와 네이티브 통합. 별도 인프라 불필요.

---

### 2.4 에이전트 팀 운영 비교

| 항목 | Hermes Agent | collar |
|------|-------------|--------|
| **병렬 실행** | ✅ 다중 에이전트 조율 | ⚠️ Claude Code Agent tool 의존 |
| **팀 상태 관리** | ✅ 내장 | ❌ 없음 |
| **역할 분리** | ✅ 내장 에이전트 역할 | ✅ CLAUDE.md 역할 분리 테이블 |
| **자율성 조정** | ✅ 신뢰 점수 기반 | ❌ 없음 |

---

### 2.5 설치 & 온보딩 비교

| 항목 | Hermes Agent | collar |
|------|-------------|--------|
| **설치 시간** | 수십 분 (클라우드 배포) | 10초 (bash setup.sh) |
| **의존성** | Node.js, DB, 클라우드 계정 | bash, Python3 |
| **새 프로젝트 적용** | 수동 설정 | `collar-init` 1명령 |
| **인터뷰 온보딩** | ❌ 없음 | ✅ collar-interview |
| **기존 프로젝트 레트로핏** | 어려움 | ✅ collar-init (멱등성) |

---

### 2.6 핵심 차별점 요약

```
Hermes Agent                       collar
─────────────────────────────────────────────────────
복잡한 영속 메모리 (DB)         단순 파일 기반 메모리
클라우드 상시 실행              세션 중 실행 (hooks)
개인 AI 비서                    프로젝트 하네스 표준화
플랫폼 통합 (Telegram 등)       Claude Code 통합
복잡한 설치                     10초 설치
자동 Skill 생성 학습 루프       수동 기록 (collar-remember)
자율 에이전트 팀                CLAUDE.md 역할 분리
```

---

## 3. collar가 Hermes보다 나은 것 / 못한 것

### collar가 Hermes보다 나은 것

| 항목 | 이유 |
|------|------|
| **설치 간편성** | bash 하나로 10초. 클라우드 불필요 |
| **프로젝트 온보딩** | collar-init 1명령 + collar-interview 자동 CLAUDE.md |
| **Claude Code 통합** | 생명주기 훅 네이티브 지원. Hermes는 외부 도구 |
| **프라이버시** | 모든 데이터 로컬. 클라우드 전송 없음 |
| **언어/도구 무관** | 어떤 프로젝트에도 적용. Hermes는 자체 런타임 |
| **팀 공유 용이** | CLAUDE.md/AGENTS.md git 커밋으로 팀 공유 |

### collar가 Hermes보다 못한 것

| 항목 | Hermes의 구현 | collar의 현재 | 필요성 |
|------|-------------|-------------|------|
| **메모리 검색** | FTS5 전문 검색 | 없음 (grep 충분) | ⚠️ 규모 의존 (하단 분석 참조) |
| **자동 학습** | 작업 완료 후 Skill 자동 생성 | 수동 기록만 | 🟡 단기 개선 가능 |
| **상시 실행** | 24/7 클라우드 | 세션 중에만 | ❌ collar 포지션과 불일치 |
| **사용자 프로파일링** | Honcho 기반 적응형 | 없음 | ❌ 현재 불필요 |
| **에이전트 자율성** | 신뢰 점수 기반 자동 조정 | 없음 | ❌ Paperclip 연동 시 고려 |

---

## 4. 미구현 목표 중 우선순위

### 즉시 가능 (추가 구현 없이)
- 언어별 CLAUDE.md 특화 템플릿 (Node.js, Python)
  - collar-init의 타입 감지 로직이 이미 있어서 연결만 하면 됨

### 단기 가능 (1~2 세션)
- collar-remember → 자동 실행 옵션 추가 (PostToolUse 훅)
  - Hermes의 "Skill 자동 생성 루프"에 근접 가능
- collar-github Level 3: 복잡한 버그 병렬 에이전트로 처리

### 중기 (Paperclip 의존)
- Paperclip API 연동 (Phase 3 전체)
  - Paperclip 완성도에 따라 결정

### 미정 (포지션 재검토 필요)
- **FTS5 메모리 검색**: 아래 분석 참조 — 현재 규모에서는 불필요
- Cron 스케줄링: 상시 실행 니즈가 있을 때

---

## 4-1. FTS5 메모리 검색 필요성 분석 (2026-05-15)

**Hermes가 FTS5를 쓰는 이유:** 수백 개의 세션 × 수백 개의 Skill을 관리하는 "상시 실행 비서"이기 때문.

### 현재 collar memory.md 규모

| 프로젝트 | memory.md 크기 | 판단 |
|---------|--------------|------|
| collar | 41줄 | 전체 읽기로 충분 |
| cmux | 27줄 | 전체 읽기로 충분 |
| myWorkHistory | 18줄 | 전체 읽기로 충분 |

### 규모별 권장 방식

| memory.md 크기 | 권장 방식 |
|--------------|---------|
| ~100줄 | 전체 읽기 (현재 방식) |
| 100~500줄 | `grep` 기반 collar-search 래퍼 |
| 500줄+ | SQLite FTS5 검토 (collar 철학과 충돌 가능성 재검토) |

### 결론

**현재 collar에 FTS5 검색은 불필요.** 이유:

1. 모든 프로젝트의 memory.md가 100줄 미만
2. collar는 프로젝트당 파일 하나 — Hermes 규모에 도달하기 어려움
3. SQLite 도입 시 "파일 기반 단순성"이라는 collar 핵심 철학과 충돌
4. Claude Code가 세션 시작 시 파일 전체를 읽으므로 검색 필요성 낮음

**재검토 조건:** memory.md가 100줄을 초과하기 시작할 때.

---

## 5. 결론

| 평가 기준 | collar (현재) |
|---------|-------------|
| Phase 1 달성도 | 60% (기본 완료, 언어별 특화 미구현) |
| Phase 2 달성도 | 110% (목표 초과 + bonus 기능) |
| Phase 3 달성도 | 0% (Paperclip 의존) |
| Phase 4 달성도 | 25% (수동 기록만) |
| Hermes 대비 포지션 | 다른 영역. 직접 경쟁 불필요 |
| 오픈소스 출시 준비도 | 70% (doc/ 정리 필요, 핵심 기능 완성) |

**collar의 핵심 가치**: Hermes가 "강력한 AI 비서"를 목표한다면, collar는 "AI가 잘 일할 환경을 10초에 구축"하는 것. 이 포지션에서 collar는 이미 동작하는 도구다.
