#!/usr/bin/env bash
# collar 50-todo-enforcer — Stop: 미완료 TODO 감지 → 계속 진행 권고
#
# OMO 5단계 훅 계층 Layer 5: Continuation
# OMO Todo Enforcer 패턴: AI가 TODO 미완료 상태로 멈추면 재개 권고
# 참고: OMO는 60초 watchdog으로 유휴 감지

HOOK_DATA="$(cat)"

EVENT=$(printf '%s' "$HOOK_DATA" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get('hook_event_name',''))
except: print('')
" 2>/dev/null)

[ "$EVENT" = "Stop" ] || exit 0

# 형제 훅(40/60)과 동일하게 $0 기준으로 .collar 해석 (cwd 비의존, 더 견고)
COLLAR_DIR="$(cd "$(dirname "$0")/.." && pwd)"
[ -d "$COLLAR_DIR" ] || exit 0

# 미완료 TODO 카운트 헬퍼
#   주의: `grep -c`는 0매칭이어도 stdout에 "0"을 출력하고 exit 1을 반환한다.
#   따라서 `|| echo 0`을 붙이면 "0\n0"이 되어 $(( )) 산술이 깨진다(에러 토큰 0).
#   → grep 출력만 받고, 비정상 시에만 0으로 폴백 (echo 중복 금지).
count_todo() {
  local f="$1" n
  [ -f "$f" ] || { printf 0; return; }
  n="$(grep -c '^\- \[ \]' "$f" 2>/dev/null)"
  printf '%s' "${n:-0}"
}

# session-compact.md + memory.md 에서 미완료 항목 탐지
TODO_COUNT=$(( $(count_todo "$COLLAR_DIR/session-compact.md") + $(count_todo "$COLLAR_DIR/memory.md") ))

if [ "$TODO_COUNT" -gt 0 ]; then
  echo "COLLAR_TODO_ENFORCER: 미완료 TODO ${TODO_COUNT}개 감지"
  echo "COLLAR_TODO_ENFORCER: 작업이 완전히 완료되지 않은 것 같습니다."
  echo "COLLAR_TODO_ENFORCER: 남은 항목을 계속 진행하거나, 완료 불가 시 이유를 기록하세요."
fi
