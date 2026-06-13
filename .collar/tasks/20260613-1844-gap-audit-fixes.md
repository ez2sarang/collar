# 2026-06-13 collar 갭 감사 미구현/버그 구현

## 요청 원문 요약
`/goal 미구현 된거 구현해줘` — collar 코드베이스의 미구현/스텁/버그/드리프트를 구현·수정.
종합 감사(57 에이전트) 결과 확정 46건(오탐 6건 제외) 발견.

## 체크리스트 — HIGH (9건, 버그·보안)
- [x] H1: collar-remember JUDGE_PROMPT unbound variable 초기화 (bin/collar-remember:104)
- [x] H2: collar-github COLLAR_HOME SCRIPT_DIR 기반으로 통일 (bin/collar-github:20)
- [x] H3: collar-github shell=True 인젝션 → gh/git 리스트 인자 + --body-file stdin
- [x] H4: collar-interview eval → printf -v (bin/collar-interview:77)
- [x] H5: collar-conductor UNKNOWN → NEEDS_WORK 처리 (bin/collar-conductor:268)
- [x] H6: collar global --dry-run CLI 등록 (package/src/cli/index.ts:16) — 빌드+CLI 검증
- [x] H7: global.ts computeHash statSync.isFile 필터 — OLD="" → NEW 실해시 증명
- [x] H8: package.json files에 templates/ 포함 + sync-templates.mjs + getTemplatesDir 1순위
- [x] H9: collar-github feature 파이프라인 구현 (implement_and_pr 공용 함수)

## 체크리스트 — MEDIUM 코드버그·drift
- [x] M11: collar-eval-model COLLAR_HOME SCRIPT_DIR 통일 + collar-github:318 model-routing.json 경로 통일
- [x] M12: collar-github 기본 브랜치 동적 감지 (default_branch() lazy+cache)
- [x] M13: collar-template-sync git repo guard
- [x] M14: collar-init DOMAIN_TABLE 치환 (멀티로우 렌더 검증) + 잘못된 에이전트명(frontend/backend/database) 교정
- [x] M15: templates/session-monitor.sh divisor 7400000 동기화 [DISCLOSED — 7891b89 반쪽수정 완료]
- [x] M16: silent-fix/db-choice-guard 설치 경로 처리 (CLAUDE.md.base 문구 정직화)
- [x] M17: browser-test.py CDP 수명 준수 재작성 + setup.sh uninstall 등록
- [x] M18: global.ts Phase2 탐색 경로 환경변수화 (COLLAR_PROJECT_ROOTS)
- [ ] M10: collar-init --force 구현

## 체크리스트 — 미구현 기능
- [ ] F19: watchdog 자동 compact+재시작 (config auto_restart + session-monitor)
- [x] F20: collar-github question LLM 답변 (answer_question, auto_level>=2 게이트)
- [ ] F21: collar-init GitHub Actions collar.yml 생성
- [ ] F23: collar migrate-gstack
- [ ] F25: collar-learn (gstack learnings 자동 추출)
- [ ] F45: 40-session-recovery.sh
- [ ] F46: collar-metrics

## 체크리스트 — LOW docs/dead-code
- [ ] L: AGENTS.md/CLAUDE.md/README.md 트리 동기화
- [ ] L: registerStateTools dead stub 정리
- [ ] L: setup.ts 재귀 복사
- [ ] L: CLAUDE.md ## bin/ 섹션 추가

## 보류 (문서가 이미 미구현 인정 — 외부의존/장기)
- collar-plugin (v3 예정)
- PaperCompany UI 연동 (장기, Paperclip 외부 구현 선행 필요)
- gstack 대체 스킬 4종 (Phase 3b, 범위 큼 — 별도 결정)

## 진행 로그
- [18:44] 감사 완료, 보고, 추적 문서 생성
- [HIGH] H1~H9 + F20/M12/M18 커밋 완료 (0d2c664)
- [MEDIUM] M11/M13/M14/M15/M16/M17 구현 + 검증 (bash -n, ast.parse, render 스모크 테스트) — 커밋 대기
