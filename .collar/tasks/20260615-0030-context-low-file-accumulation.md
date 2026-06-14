# 2026-06-15 "Context low" 거짓 경고 2차 원인 — transcript 파일 누적 [DISCLOSED]

## 요청 원문 요약
"investments에서 여전히 문제가 있는데..." — ctx% 바이트 미터 수정(5d81300) 후에도
`Context low (11% remaining) · Run /compact` 경고가 낮은 ctx 에서 계속 뜸. 사용자 재신고.

## 정정 (이전 진단의 한계)
1차 수정(5d81300)은 **collar 자체** compact 트리거만 고쳤다. 사용자가 실제로 보는
`Context low` 경고는 **Claude Code 네이티브** 메시지로, 별개 메커니즘이다. "근본 해결" 선언은 과장.

## 2차 근본 원인 (이 세션 transcript 실측)
- 토큰 축: 마지막 메인스레드 턴 usage = 96,454 토큰 / 200K = **48% 사용 (여유)**
- 파일/페이로드 축: transcript 26.2MB / 32MB = **86% 사용 (~11% 남음)**
- 같은 세션 **compact 26회** → 매번 요약 append, 옛 줄 보존 → 파일 단조 증가
- 마지막 compact 이후(라이브 컨텍스트 근사) = **0.3MB**, 죽은 히스토리 = **25.9MB(파일의 98%)**
- 대형 줄(스크린샷 등) 200KB↑ = 단 1개 → 스크린샷이 아니라 **누적**이 원인

## 출처 확정 (grep)
- `Context low ... Run /compact` 문자열 → OMC dist 에 없음 → **Claude Code 네이티브**
- OMC `payload est` → `payload-estimate.js:43` `statSync(transcriptPath).size` = **파일 크기 기반**
  → 죽은 히스토리 98% 까지 세어 거짓 부풂

## 함정
`/compact` 는 파일을 줄이지 않고 요약을 append → 파일 더 커짐 → 파일 기반 경고 악화 → 폭주.
파일 축 리셋은 **`/clear`·새 세션**(새 transcript 파일)뿐.

## 대응 (사용자 선택: "운영 규칙 추가")
"Context low 거짓 경고 = transcript 파일 누적" 섹션 추가:
- [x] 라이브 글로벌 `~/.claude/CLAUDE.md` (즉시 반영 — investments 포함 모든 프로젝트 다음 세션)
- [x] collar 템플릿 소스 `templates/global/CLAUDE.md.rules` (향후 `collar global` 배포분)
- AI 가 직접 /clear·/compact 실행 불가 → 상황 감지 시 사용자에게 안내하는 형태로 작성(실행가능성 검증 통과)

## 패치 불가 영역 (보고만)
- Claude Code 네이티브 `Context low`: 컴파일된 바이너리, 패치 불가
- OMC `payload-estimate.js`: 3rd-party npm(oh-my-claude-sisyphus) dist, collar 코드 아님 → 미수정

## 체크리스트
- [x] 토큰 vs 파일 두 축 실측 비교
- [x] compact 26회 / 죽은 히스토리 98% 실측
- [x] 경고 문자열 출처 grep 확정 (네이티브 / OMC statSync)
- [x] 운영 규칙 2곳 추가
- [x] 실행 가능성 검증 (AI 는 안내만, 슬래시 커맨드 직접 실행 금지 규칙 준수)
- [ ] 사용자 검증: 다음 세션부터 거짓 경고 시 /clear 안내 동작 확인 (VERIFIED)

## 진행 로그
- [00:10] 사용자 재신고 → 라이브 transcript 두 축 실측 → 파일 누적이 진범 확정, 보고
- [00:25] 사용자 "운영 규칙 추가" 선택 → 글로벌+템플릿 2곳 규칙 추가
