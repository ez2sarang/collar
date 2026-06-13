# 2026-06-14 collar 워치독 ctx% 미터 수정 — 바이트 추정 → 실제 토큰 usage [DISCLOSED]

## 요청 원문 요약
"ctx 얼마 안 썼는데 Context low 경고" + "ctx:14%인데도 컴팩트하네" — 낮은 컨텍스트에서
collar 가 자동 compact 를 폭주시키는 문제. 사용자가 AskUserQuestion 에서 "실제 usage 읽기" 선택.

## 근본 원인 (실측)
collar `60-session-monitor.sh` 의 `CTX_PCT = transcript_bytes ÷ 7.4MB`.
- transcript JSONL 은 compact 해도 줄지 않음(요약 append, 옛 줄 보존).
- 스크린샷(base64 PNG)·tool 결과로 바이트 폭증 → 실제 토큰과 무관하게 100% 오탐.
- 이 세션 실측: 파일 25.9MB → 구버전 350%(클램프100%) vs 실제 토큰 50~65%.
- `7891b89`(900KB→7.4MB)은 임계값만 옮긴 반창고였음.
- OMC `ctx:NN%` 는 네이티브 % 사용 → 무죄. 직전 가설(OMC가 범인) 정정함.

## 수정 내용
실제 토큰 usage 직접 읽기: transcript 마지막 메인스레드 턴의
`input_tokens + cache_creation_input_tokens + cache_read_input_tokens ÷ CTX_LIMIT(200K)`.
isSidechain(서브에이전트) 제외. usage 없으면 메시지 카운트 폴백.

## 체크리스트
- [x] 근본 원인 실측 확인 (세 미터 동일조건 비교: 구350% / 신50% / OMC네이티브)
- [x] OMC HUD 소스 확인 → 무죄 판정 (getContextPercent = 네이티브 우선)
- [x] templates/collar-hooks/60-session-monitor.sh 수정 (collar-init 배포원)
- [x] templates/session-monitor.sh 수정 (collar-watchdog 배포원)
- [x] 두 템플릿 ctx 측정 블록 동일성 확인 (diff)
- [x] bash -n 문법 검사 통과 (양쪽)
- [x] 라이브 3곳 배포 (.collar/hooks/60-, ~/.collar/templates/collar-hooks/60-, ~/.collar/templates/session-monitor.sh)
- [x] 7400000 전수 제거 확인
- [x] 배포 훅 end-to-end 실행 → 65%<80% 정상 silent exit, compact 미발동 확인
- [x] obsolete .baseline-session-id git rm
- [x] [DISCLOSED] 커밋
- [ ] 사용자 검증: investments 세션에서 재발 없음 확인 (VERIFIED 는 사용자 몫)

## 잔여/후속
- 템플릿 2벌(collar-hooks/60- vs session-monitor.sh) 드리프트 위험은 이번 사고의 2차 원인.
  consolidate 는 별도 리팩터(범위 확대 방지로 분리).
- investments 적용: 프로젝트 격리 — 사용자가 investments 세션에서 collar-init 재실행 또는
  .collar/hooks/60-session-monitor.sh 를 ~/.collar/templates 에서 갱신해야 반영됨.

## 진행 로그
- [09:00] OMC 소스 추적(stdin.js/context.js/payload-estimate.js) → OMC 무죄 확정
- [09:05] 실측 ground-truth (25.9MB/350% vs 토큰 50%) → collar 워치독 단독 범인 확정, 사용자 보고
- [09:10] 배포원 2개 파일 5개 편집, 라이브 3곳 배포, e2e 검증 통과
