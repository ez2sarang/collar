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

COLLAR_DIR="$(pwd)/.collar"
[ -d "$COLLAR_DIR" ] || exit 0

# session-compact.md에서 미완료 항목 탐지
COMPACT_FILE="$COLLAR_DIR/session-compact.md"
TODO_COUNT=0
if [ -f "$COMPACT_FILE" ]; then
  TODO_COUNT=$(grep -c '^\- \[ \]' "$COMPACT_FILE" 2>/dev/null || echo 0)
fi

# memory.md에서도 확인
MEMORY_FILE="$COLLAR_DIR/memory.md"
if [ -f "$MEMORY_FILE" ]; then
  MEM_TODO=$(grep -c '^\- \[ \]' "$MEMORY_FILE" 2>/dev/null || echo 0)
  TODO_COUNT=$((TODO_COUNT + MEM_TODO))
fi

if [ "$TODO_COUNT" -gt 0 ]; then
  echo "COLLAR_TODO_ENFORCER: 미완료 TODO ${TODO_COUNT}개 감지"
  echo "COLLAR_TODO_ENFORCER: 작업이 완전히 완료되지 않은 것 같습니다."
  echo "COLLAR_TODO_ENFORCER: 남은 항목을 계속 진행하거나, 완료 불가 시 이유를 기록하세요."
fi
