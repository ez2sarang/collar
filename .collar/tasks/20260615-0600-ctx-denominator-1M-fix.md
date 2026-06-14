# 2026-06-15 ÷200K 하드코딩 버그 정정 — 1M 컨텍스트 대응 [DISCLOSED]

## 요청 원문 요약
"investments에서 여전히 Context low" 재신고 → 재조사 중 **세션이 1M 컨텍스트**임을 발견
(stdin cache: context_window_size=1,000,000). 토큰 사용량을 200K로 나누던 모든 곳이 5배 과대.

## 발견한 오류 (실측·grep 근거)
- E1(보고 오류): 직전에 토큰을 48%→68%(÷200K)로 보고. 실제 102K/1M=10%. 과대보고.
- E2(규칙 버그): 897123a 글로벌 규칙에 `÷ 200K` 하드코딩 → 1M에서 규칙 자체가 오판.
- E3(워치독 버그): 60-session-monitor.sh `CTX_LIMIT=200000` 하드코딩 → 1M 세션 토큰% 5배 과대
  → 거짓 자동 compact 위험.
- 네이티브 `Context low (N% remaining)`: OMC dist 전체 grep 무출력 → Claude Code 네이티브 확정.
  on-disk transcript 29.1MB/32MB=90%(=경고)지만 실제 요청은 102K토큰≈~0.4-3MB=32MB의 1%.
  → 파일 누적(compact 26회 죽은 히스토리 98%)으로 부푼 거짓경고. 패치 불가(네이티브) → 운영 안내가 정답.

## 사용자 선택
"규칙+워치독 둘 다 (권장)" — E2 규칙 정정 + E3 워치독 동적 window size.

## 체크리스트
- [x] E2: 라이브 ~/.claude/CLAUDE.md 규칙 ÷200K → context_window_size/used_percentage 정정
- [x] E2: 템플릿 templates/global/CLAUDE.md.rules 동일 정정
- [x] E3: templates/collar-hooks/60-session-monitor.sh — OMC stdin cache 에서 used_percentage/window_size 동적 읽기
- [x] E3: templates/session-monitor.sh — 동일 수정
- [x] 라이브 배포 3곳 (.collar/hooks/60-, ~/.collar/templates/collar-hooks/60-, ~/.collar/templates/session-monitor.sh) — diff -q 모두 identical
- [x] bash -n 문법 검사 (양쪽 OK + 라이브 OK)
- [x] e2e: 6 케이스 합성 — Case1 native:10→10, Case2 window1M:318K→31, Case3 fallback200K→100(구동작보존), Case4 config1M→31, Case5 transcript없음+native→10, Case6 전무→-1(msg폴백). 1M 세션 구코드 100%(거짓compact)→신코드 10/31%(임계80 미만, compact 안함) 확인
- [ ] [DISCLOSED] 커밋
- [ ] llm-logs 기록

## 설계: 워치독 토큰% 단일 출처
1순위: $PROJECT_DIR/.omc/state/hud-stdin-cache.json 의 context_window.used_percentage (=네이티브, OMC ctx:와 동일)
2순위: 같은 캐시의 context_window_size 로 CTX_LIMIT 설정 후 transcript usage ÷ window
3순위: config.context_token_limit 또는 200000 (OMC 없는 standalone 폴백)
4순위: 메시지 카운트
→ OMC 있으면 네이티브와 100% 일치, 없으면 graceful degrade.

## 진행 로그
- [06:00] 1M 발견, 두 축 실측, 네이티브/OMC grep 확정, 사용자 보고+공개, "둘 다" 선택 수신
