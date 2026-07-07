# [2026-07-07 18:10] Fable 5 오케스트레이션 시스템 collar 통합

## 요청 원문 요약
localhost:3204 공유 영상("클로드 페이블5 토큰 90% 아끼는 궁극의 세팅법", 성공지식백과 2026-07-05,
YouTube I-JuFhY5W54, 슬라이드 76장 OCR 분석)을 정밀 검토하여 collar에 추가할 것을 표로 정리하고,
추가 후 investments 및 다른 프로젝트에서도 즉시 사용 가능하게 작업.

## 영상 핵심 내용 (4계층 오케스트레이션)
1. effort: max/xhigh 대신 high (벤치 -1%, 비용 -40%) — DeepSWE 벤치마크 근거
2. Sonnet 5 = 성능↓ 가격↑ → 실행 모델은 Opus 4.8로 리매핑 (ANTHROPIC_DEFAULT_SONNET_MODEL)
3. 계층1 선언: fable.md 지휘 지침 + active.md 심링크 스위치 + CLAUDE.md @import 한 줄
4. 계층2 역할: deep-reasoner(Opus 4.8, effort max) / runner(Haiku 4.5, effort low, 읽기 도구만)
5. 계층3 리매핑: claude() 셸 래퍼 — 스위치 on일 때만 env 주입
6. 계층4 강제: PreToolUse 게이트 — 메인 에이전트 턴당(prompt_id) 코드 파일 2개 제한,
   서브에이전트(agent_id 존재) 무제한 통과, Bash 우회(sed -i 등) 차단, fail-open, off 시 통과
7. fable on/off/status 토글 CLI
8. advisor 전략(Anthropic 공식, 2026-04-09): SDK용 — 참고 문서로만 기록

## 체크리스트
- [x] 1. templates/fable/fable.md — 오케스트레이션 지침
- [x] 2. templates/fable/empty.md — off 상태용 빈 파일
- [x] 3. templates/fable/env.sh — Sonnet→Opus 리매핑 셸 래퍼 (zsh/bash 겸용)
- [x] 4. templates/fable/agents/deep-reasoner.md — Opus 4.8 / effort max
- [x] 5. templates/fable/agents/runner.md — Haiku 4.5 / effort low / 읽기 도구
- [x] 6. templates/fable/hooks/orchestration-gate.py — PreToolUse 강제 게이트
- [x] 7. bin/collar-fable — install/on/off/status (멱등), `fable` 심링크
- [x] 8. 게이트 스크립트 단위 검증 — 14케이스 전부 기대대로 (exit 0/2)
- [x] 9. 글로벌 설치 실행 — 로딩 코드 4종 전부 [OK]
- [x] 10. fable status 검증 + ~/.collar/{bin,templates} 동기화 — 재설치 10건 SKIP(멱등), on/off 토글 정상
- [x] 11. CLAUDE.md·AGENTS.md 구조 문서 갱신
- [x] 12. 커밋

## 구현 계획
| # | 항목 | 방법 | 파일/위치 |
|---|------|------|---------|
| 1-6 | 템플릿 세트 | 영상 가이드 macOS/zsh 적응 | templates/fable/ |
| 7 | 토글 CLI | bash, collar-init 멱등 패턴 준수 | bin/collar-fable |
| 8 | 검증 | 합성 stdin payload 6케이스 | scratchpad |
| 9-10 | 글로벌 설치 | collar-fable install (전 프로젝트 즉시 적용) | ~/.claude/fable |

## 진행 로그
- [18:10] 영상 76슬라이드 OCR + 스크립트 추출·분석 완료, 갭 분석 완료
- [18:20] templates/fable/ 6파일 + bin/collar-fable 작성, bash -n / py_compile 통과
- [18:25] 게이트 합성 payload 14케이스 검증: 턴당 2파일 허용·3번째 차단(exit 2)·동일파일
  재수정 무과금·서브에이전트(agent_id) 통과·새 턴(prompt_id) 리셋·sed -i / > 리다이렉트
  차단·off 시 전부 통과·prompt_id 없으면 fail-open — 전부 기대값 일치
- [18:27] collar-fable install 실행(VERIFIED): ~/.claude/fable 4계층 + agents 심링크 +
  settings.json PreToolUse 등록 + ~/.zshrc 로더 + ~/.claude/CLAUDE.md @import. 재설치
  멱등(10 SKIP), fable on/off 심링크 전환 확인, settings.json JSON 유효성 확인
- [18:30] 글로벌 설치라 investments 등 모든 프로젝트에서 새 세션부터 즉시 적용.
  단, 이미 떠 있는 세션에는 미적용(가이드 명시). effort high는 사용자가 /effort로 기적용.
- [18:45] README 도구 표·사용법 섹션 + doc/2026-07-07-fable-orchestration.md 설계 문서
  반영(5cf809f), GitHub push (7891b89..5cf809f — 미배포 19커밋 일괄 배포)
- [19:03] **실세션 끝단 검증 (VERIFIED)** — 새 claude 세션 2개(비대화형, 격리 디렉토리):
  1) 메인 에이전트 c1/c2/c3.ts 직접 생성 → c1·c2 생성, c3 도구 호출 단계 차단
     (차단 메시지 원문 수신, c3.ts 디스크 미존재), gate.json에 session_id+prompt_id+파일 2건 기록
  2) executor 서브에이전트 위임 d1/d2/d3.ts → 3개 전부 생성 (agent_id 통과 확인)
  → 가이드 완성 기준(메인 차단 + 서브 통과 동시 충족) 만족

## 참고 (영상의 나머지 권고 — 별도 조치 불필요)
- effort max 금지·high 권장: 현재 settings effortLevel=high ✅
- Sonnet 5 워커 금지: 리매핑이 sonnet→claude-opus-4-8 강제 ✅
- advisor 전략(Anthropic 블로그 2026-04-09): SDK 앱용 — 글로벌 CLAUDE.md에
  advisor_20260301 항목 기존재, Claude API 앱 작업 시 /claude-api 스킬 참조
