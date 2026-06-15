# 2026-06-15 09:45 "Context low (0% remaining)" 진짜 근본원인 규명 + 이전 가설 반증 [DISCLOSED]

## 요청 원문 요약
investments에서 `Context low (0% remaining) · Run /compact` 가 계속 발생.
당시 컨텍스트: `Model: Opus 4.8 | ... | ctx:31% | 🔧58` — OMC ctx 는 31%(여유)인데 네이티브는 0%.

## ⚠️ 오류 보고 (이전 세션 문서가 틀렸음 — DISCLOSED)
이전 세션(2026-06-15 0030/0600 task)이 "네이티브 Context low = on-disk transcript ÷ 32MB,
파일 누적 거짓경고 → /clear 권장, 패치 불가"로 결론냈으나 **이는 상관관계를 인과로 착각한 오진**이었다.

### 반증 (실측)
- 현재 활성 investments transcript 파일 = **10MB** → ÷32MB = 31% → 파일 가설대로면 "69% remaining"이어야 함.
- 실제 경고 = **"0% remaining"**. 파일 크기로는 설명 불가 → 파일 가설 반증.

### 진짜 근본원인
- investments `.omc/state/hud-stdin-cache.json` 실측:
  `total_input_tokens=313,846`, `context_window_size=1,000,000`, `used_percentage=31`, `exceeds_200k_tokens=true`.
- 네이티브 auto-compact 경고 분모가 **실제 1M 윈도우가 아니라 ≈200K(또는 env `CLAUDE_CODE_AUTO_COMPACT_WINDOW`)로 고정**.
  `313,846 ÷ 200,000 = 157%` → 클램프 → **0% remaining**.
- 게다가 글로벌 `~/.claude/settings.json` 에 `CLAUDE_CODE_AUTO_COMPACT_WINDOW: "175000"` 이 있어 분모를
  기본 200K보다 **더 낮춰 상황을 악화**시키고 있었음 (`313,846 ÷ 175,000 = 179%`).
- 공식 근거(claude-code-guide): docs context-window 시뮬레이터 `const MAX=200000`,
  changelog v2.1.154 "standard context limit". 1M 윈도우로 스케일 안 됨 = 확인된 구조적 한계.
- 추가 검증: investments 는 이미 `autoCompactEnabled: false` 인데도 경고 발생
  → `autoCompactEnabled:false` 는 경고 UI 를 못 막는다(자동 동작만 차단). 진짜 레버는 env 분모.

## 체크리스트
- [x] hud-stdin-cache.json 실측으로 토큰/윈도우 확인 (313,846 / 1,000,000 = 31%)
- [x] 파일 가설 반증 (활성 파일 10MB → 0% remaining 설명 불가)
- [x] claude-code-guide 공식문서 검증 (const MAX=200000, v2.1.154)
- [x] 글로벌 settings.json `CLAUDE_CODE_AUTO_COMPACT_WINDOW` 175000 → 900000 (1M의 90%)
- [x] 글로벌 규칙 `~/.claude/CLAUDE.md` "Context low" 섹션 교정 (틀린 ÷32MB 가설 제거)
- [x] collar 템플릿 `templates/global/CLAUDE.md.rules` 동일 교정
- [x] collar `.collar/session-compact.md` 틀린 줄 교정 + 해시 재계산
- [ ] 사용자: investments 세션 재시작 (env 는 세션 시작 시 로드 → 새 세션부터 적용)
- [x] [DISCLOSED] 커밋

## 적용한 수정
| # | 대상 | 변경 |
|---|------|------|
| 1 | `~/.claude/settings.json` | `CLAUDE_CODE_AUTO_COMPACT_WINDOW` 175000 → 900000 |
| 2 | `~/.claude/CLAUDE.md` | "Context low" 섹션 근본원인 재작성 |
| 3 | `templates/global/CLAUDE.md.rules` | 동일 재작성 (템플릿 동기화) |
| 4 | `.collar/session-compact.md` | 틀린 ÷32MB 줄 교정 + COLLAR_HASH 재계산 |

## 검증 결과
- `313,846 ÷ 900,000 = 35% 사용 → 65% remaining` → 거짓 경고 해소.
- env 변경은 **새 세션부터** 적용 (현재 실행 중 세션엔 미반영). investments 재시작 시 해소 확인 필요 = VERIFIED 대기.

## 주의/트레이드오프
- `CLAUDE_CODE_AUTO_COMPACT_WINDOW=900000` 은 글로벌이라 모든 프로젝트에 적용.
  1M 계정(현재 active, 확인됨)에선 정상. 만약 비-1M(200K) 세션을 쓰면 실제 200K 한계에서
  컴팩션이 안 걸려 위험 → 그 경우에만 값 하향 필요. 현재 계정은 1M active 라 안전.
- 별개 위생 이슈: investments transcript 디렉토리 총 591MB(개별 최대 55MB). 경고와 무관하나 디스크/훅 stat 부담.

## 진행 로그
- [09:30] investments transcript 실측 → 활성 파일 10MB
- [09:35] hud-stdin-cache.json 실측 → 313,846/1,000,000=31%, exceeds_200k=true → 파일 가설 반증, 200K 분모 가설 확정
- [09:40] claude-code-guide 공식문서 검증 → const MAX=200000 확정
- [09:42] 글로벌 settings.json 175000 → 900000
- [09:44] 글로벌 CLAUDE.md + 템플릿 규칙 교정
- [09:46] task 문서 작성, session-compact 교정, 커밋 준비
