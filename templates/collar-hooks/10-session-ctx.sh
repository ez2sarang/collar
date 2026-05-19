#!/usr/bin/env bash
# collar 10-session-ctx — SessionStart: session-compact.md 해시 검증 + 컨텍스트 힌트
#
# OMO 5단계 훅 계층 Layer 1: Session
# 세션 시작 시 session-compact.md 무결성 확인 후 AI에게 로드 힌트 출력

HOOK_DATA="$(cat)"

EVENT=$(printf '%s' "$HOOK_DATA" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get('hook_event_name',''))
except: print('')
" 2>/dev/null)

[ "$EVENT" = "SessionStart" ] || exit 0

# .collar 위치 탐지
COLLAR_DIR="$(pwd)/.collar"
[ -d "$COLLAR_DIR" ] || exit 0

COMPACT_FILE="$COLLAR_DIR/session-compact.md"
[ -f "$COMPACT_FILE" ] || exit 0

# Hashline 검증
STORED_HASH=$(grep -o 'COLLAR_HASH: [a-f0-9]*' "$COMPACT_FILE" 2>/dev/null | awk '{print $2}')
if [ -n "$STORED_HASH" ]; then
  CONTENT=$(grep -v "COLLAR_HASH:" "$COMPACT_FILE")
  ACTUAL=$(printf '%s' "$CONTENT" | sha256sum 2>/dev/null | cut -c1-8 || printf '%s' "$CONTENT" | md5sum | cut -c1-8)
  if [ "$STORED_HASH" != "$ACTUAL" ]; then
    echo "COLLAR_SESSION_CTX: ⚠️  session-compact.md Hashline 불일치 — 외부 수정 가능성"
    echo "COLLAR_SESSION_CTX: 해시 불일치 compact는 참고만 하고 memory.md를 우선 신뢰하세요."
  fi
fi

echo "COLLAR_SESSION_CTX: session-compact.md 존재 — 작업 시작 전 먼저 읽으세요: $COMPACT_FILE"
