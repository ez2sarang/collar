# 2026-06-14 글로벌 ~/.claude/CLAUDE.md 지도화 (컨텍스트 베이스라인 절감)

## 요청 원문 요약
investments "Context low 얼마 안 썼는데 경고" 진단 → collar 통제 가능한 최대 상시주입물인
글로벌 ~/.claude/CLAUDE.md(50.6KB/1115줄)를 "지도(map)" 구조로 정리. 핵심 규칙은 본문 유지,
레퍼런스·코드 부록은 ~/.collar/ref/*.md 로 분리 후 포인터. 사용자 본인 원칙("메모리는 지도")을 글로벌에도 적용.

## 결정 (AskUserQuestion)
- 강도: "지도화" — 규칙 의미 100% 보존, 코드블록/사례연구만 분리
- 원본 .bak 백업
- 재팽창 방지: collar global이 섹션 제목으로 dedup → 제목 유지하면 본문 줄여도 재병합 안 됨 (검증 완료)
- 리스크 최소화: 안전 핵심 섹션(공급망/완료 프로토콜/Memory Discipline)은 미변경, 레퍼런스 5개만 추출

## 체크리스트
- [x] ~/.collar/ref/ + templates/global/ref/ 디렉토리 생성
- [x] ref/browser-cdp.md 작성 (원문 보존)
- [x] ref/claude-api.md 작성
- [x] ref/llm-logs-api.md 작성
- [x] ref/model-routing.md 작성
- [x] ref/gemini-design.md 작성
- [x] ~/.claude/CLAUDE.md .bak 백업 (50633 bytes)
- [x] 섹션1 브라우저 CDP 슬림화 (제목 유지, 탭닫기금지 하드룰 본문 보존)
- [x] 섹션2 Anthropic API 슬림화
- [x] 섹션3 LLM Logs API 슬림화
- [x] 섹션4 모델 라우팅 슬림화
- [x] 섹션5 Gemini/Design 슬림화
- [x] ~/.collar/ref/ 로 배포 (cp) — 5개 파일
- [~] Workflow 적대적 검증 (원본 .bak vs 슬림+ref, 누락 디렉티브 0 확인) — 실행 중
- [x] setup.sh: ref 배포 1줄(install) + uninstall 대칭 제거
- [x] 절감 측정: 1115→851줄, 50633→41351 bytes (9282/18.3%, ~2300토큰) + 모든 ## 제목 보존 확인
- [ ] collar 레포 변경분 커밋

## 구현 계획
| # | 항목 | 방법 | 파일/위치 |
|---|------|------|---------|
| 1 | ref 파일 5종 | Write (원문 보존) | templates/global/ref/*.md |
| 2 | 슬림화 | Edit ×5 (제목 유지) | ~/.claude/CLAUDE.md |
| 3 | 배포 | cp -r → ~/.collar/ref | (포인터 즉시 해소) |
| 4 | 검증 | Workflow 적대적 다중검증 | .bak vs 현재+ref |
| 5 | durable | setup.sh 배포라인 + uninstall | setup.sh |

## 진행 로그
- [06:50] 디렉토리 생성, setup.sh 구조 확인, 작업 시작
- [07:10] ref 5종 작성(원문 보존) → ~/.collar/ref 배포, CLAUDE.md.bak 백업
- [07:20] 5개 섹션 슬림화 완료. 1115→851줄, 50.6KB→41.4KB (-18.3%, ~2300토큰). 모든 ## 제목·5개 포인터 보존 확인
- [07:25] setup.sh install/uninstall ref 배선 대칭 추가
- [07:26] Workflow 적대적 무손실 검증 실행(wf_c2ff826c) — 결과 대기
