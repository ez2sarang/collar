# AGENTS.md — collar

AI 및 인간 기여자를 위한 가이드.

---

## 1. 목적

collar는 **하네스 표준화 도구**다. 새 프로젝트에 `collar-init` 하나로 CLAUDE.md + AGENTS.md + .claude/settings.json을 10초 안에 생성한다.

이 AGENTS.md는 collar 자체 개발용이다 — collar로 만든 하네스 템플릿이나 스크립트를 수정할 때 읽어라.

---

## 2. 시작 전 읽을 것

변경 전 이 순서로 읽어라:
1. `CLAUDE.md` — collar 프로젝트 규칙
2. `doc/2026-05-14-harness-system-plan.md` — 전체 설계 계획
3. `doc/2026-05-14-session-qa.md` — Q&A 의사결정 이력
4. `templates/CLAUDE.md.base` — 생성하는 헌법 템플릿

---

## 3. 레포 구조

```
collar/
├── CLAUDE.md              # collar 자체 헌법 (이 프로젝트 규칙)
├── AGENTS.md              # 이 파일
├── README.md              # 사용자용 퀵스타트
├── bin/
│   ├── collar-init        # 프로젝트 하네스 설치 스크립트
│   ├── collar-interview   # 대화형 인터뷰 → 프로젝트 맞춤 CLAUDE.md 생성
│   ├── collar-watchdog    # 컨텍스트 임계값 감시 + 자동 compact
│   ├── collar-compact     # 세션 컨텍스트 압축 → session-compact.md
│   ├── collar-remember    # 세션 인사이트 기록 (LLM 글로벌 자동 판단)
│   ├── collar-update      # CLAUDE.md TODO AI 자동 채우기
│   └── collar-github      # GitHub 이슈 자동 분류·처리·PR 생성
├── templates/
│   ├── CLAUDE.md.base         # 모든 프로젝트 공통 헌법 템플릿
│   ├── AGENTS.md.base         # 에이전트 가이드 템플릿
│   ├── collar-dispatcher.sh   # 이중 훅 Layer 1 라우터
│   ├── session-monitor.sh     # ctx% 감시 + memory.md 자동 정리
│   ├── github-check.sh        # 세션 시작 시 GitHub 이슈 체크
│   └── config.json            # 기본 설정 템플릿
└── doc/
    ├── 2026-05-14-architecture-v2.md
    ├── 2026-05-14-harness-system-plan.md
    ├── 2026-05-14-session-qa.md
    ├── 2026-05-14-memory-system-design.md
    ├── 2026-05-14-competitive-analysis.md
    ├── 2026-05-14-frustration-analysis.md
    ├── 2026-05-14-runtime-environment-analysis.md
    ├── 2026-05-14-interview-prep.md
    └── 2026-05-14-glossary.md
```

---

## 4. 개발 환경

```sh
# 설치 (표준)
./install.sh          # ~/.collar/bin 에 배포 + PATH 등록 안내

# 개발 중 레포에서 직접 실행하려면
export PATH="$HOME/.collar/bin:$PATH"   # 설치 후
# 또는 레포 bin/ 직접 사용
export PATH="/path/to/collar/bin:$PATH"

# 새 프로젝트에 적용
cd /path/to/project && collar-init

# 스크립트 위치 자동 감지: COLLAR_HOME은 스크립트 위치 기준으로 결정됨
# ~/.collar/bin/ 에 설치됐으면 COLLAR_HOME=~/.collar
# 레포 bin/에서 실행하면 COLLAR_HOME=레포 루트
```

---

## 5. 핵심 엔지니어링 규칙

1. **멱등성 필수**: `collar-init`을 여러 번 실행해도 기존 파일을 덮어쓰지 않는다
2. **템플릿 변경 시 검증**: 템플릿 수정 후 실제 프로젝트에 적용하여 동작 확인
3. **3단계 완료**: 코드 변경(STARTED) ≠ 실행 확인(TESTED) ≠ 실제 프로젝트 적용(VERIFIED)
4. **재발 버그**: "또 안됨" 보고 시 이전 수정 생존 확인 우선
5. **다음 단계 명시**: 작업 후 "다음: [내용]. 진행할까요?" 패턴 필수

---

## 6. 에이전트 효율성 규칙

- 모호한 표현("잘", "효율적으로") → 코드 전 구체화 요청
- 같은 실패 접근 2회 이상 → 즉시 멈추고 사용자에게 보고
- 5분 이상 조용히 작업 금지 → 상태 업데이트 전송

---

## 7. 도메인 라우팅

| 도메인 | 에이전트 | 모델 |
|--------|----------|------|
| 스크립트 수정 (`bin/`) | executor | sonnet |
| 템플릿 작성 (`templates/`) | executor | sonnet |
| 설계 결정 (새 기능 방향) | architect | opus |
| 문서 작성 (`doc/`) | writer | haiku |

---

## 8. 완료 검증 형식

```
STATUS: TESTED
- [x] collar-init 실행 시 오류 없음
- [x] 생성된 파일이 ez2claude 글로벌 설정과 충돌 없음
- [ ] 실제 프로젝트에서 VERIFIED (사용자 직접 확인)

다음: [다음 단계]. 진행할까요?
```
