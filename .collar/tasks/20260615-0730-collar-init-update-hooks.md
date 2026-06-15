# 2026-06-15 collar-init --update-hooks 추가 — 설치된 프로젝트 훅 공식 업데이트 경로

## 요청 원문 요약
"investments에 collar global로 동적 워치독 배포해줘"

## 발견한 갭 (소스 grep 근거)
- `collar global`(bash `collar-global` + npm `global.ts`): 규칙/메모리만 병합 → **훅 배포 불가**.
- `collar-init`: 훅 배포하지만 `if [ ! -f "$hook_dest" ]`(753행) → **기존 훅 건너뜀(멱등)** → 이미 설치된 프로젝트 훅 업데이트 불가.
- 결론: collar에 "설치된 프로젝트의 훅을 공식 채널로 업데이트하는 명령"이 없음 (investments/kiro/nomo 공통 갭).
- investments: 이번 턴 수동 cp로 검증본(238줄, context_window_size) 이미 배포됨 → 기능적 완료, 공식 경로만 부재.

## 사용자 선택
"collar-init --update-hooks 추가 (권장)" — collar-init이 훅 소유 → 덮어쓰기 플래그 추가, 단일 책임 유지.

## 체크리스트
- [x] bin/collar-init: `UPDATE_HOOKS=false` + 인자 파싱에 `--update-hooks` 추가
- [x] bin/collar-init: **인터뷰 앞단 fast-path**(line~26)로 훅만 갱신 후 `exit 0` — 비대화형 안전. 인플로우 루프는 원래 skip-existing(멱등) 복원
- [x] bin/collar-init: usage 주석(3-5행) 갱신
- [x] bash -n 문법 검사 (repo + 라이브 OK)
- [x] 라이브 배포본 ~/.collar/bin/collar-init 동기화 (cmp identical)
- [x] investments에 `collar-init --update-hooks` 실행(공식 경로) → 설치1·업데이트3·변경없음6, 10/10 템플릿 패리티, 60- 동적버전(context_window_size) bash -n OK
- [x] 멱등 보존 검증: fast-path 재실행 시 변경없음10·.bak 0개 (Mode B)
- [x] 커밋 (feat) → 76fb9de [DISCLOSED]
- [x] llm-logs best-effort

## 발견·정정한 설계 버그 (개발 중 포착, 미출시)
- 1차 구현: `--update-hooks` 분기를 인플로우 훅 루프(line~750)에 배치 → collar-init은 `set -euo pipefail`
  + line42 비가드 `read`(언어 선택)에서 비대화형 실행 시 중단 → fast-path 도달 불가(죽은 코드).
- 정정: 인자 파싱 직후(line~26) **fast-path 조기 종료** 블록으로 이동. 인터뷰 전에 훅만 갱신·`exit 0`.
  인플로우 루프는 원래 skip-existing(멱등)으로 되돌려 죽은 코드 제거. (feat 커밋이라 미출시 — [DISCLOSED] 불요)

## 설계
- `--update-hooks`: 기존 훅 존재 시 `.bak-update-<날짜>` 백업 후 templates/collar-hooks/ 기준으로 덮어쓰기.
- 플래그 없을 때(기본): 현행 skip-existing 멱등 동작 100% 보존 (collar-init 멱등성 규칙 준수).
- 실행 시 COLLAR_HOME=templates 소스 기준 → 레포 bin 직접 실행으로 검증본 템플릿 사용.

## 진행 로그
- [07:25] 갭 발견·보고, 사용자 "collar-init --update-hooks" 선택 수신
- [07:50] 1차 구현(인플로우 배치) → 비대화형 line42 중단 버그 포착·보고
- [07:55] fast-path 조기종료로 정정, 인플로우 루프 멱등 복원, bash -n OK
- [08:00] 3모드 격리테스트(설치/멱등/변조) 통과, 라이브 동기화
- [08:05] investments 공식 채널 실행 → 10/10 패리티, 60- 동적 VERIFIED, .bak 3개 백업
