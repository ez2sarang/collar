#!/usr/bin/env bash
# collar 40-session-recovery — SessionEnd: 세션 종료 시 컨텍스트 보존
#
# OMO 5단계 훅 계층 Layer 4: Recovery
# 목적: 세션이 끝나기 직전 transcript를 collar-compact로 압축해
#       session-compact.md에 보존 → 다음 세션 SessionStart 가 자동 복원.
#
# 중요(검증됨): SessionEnd 훅은 차단(blocking) 불가하고 세션당 정확히 1회 발생한다.
#   → collar-compact를 동기 실행하면 종료가 지연되거나 잘릴 수 있으므로
#     반드시 nohup 백그라운드로 fire-and-forget 한다.
#   (참고: 매 턴 발생하는 Stop 이벤트가 아니라 종료 1회성 SessionEnd 가 올바른 이벤트)

# stdin에서 hook event JSON 읽기
HOOK_DATA="$(cat)"

EVENT="$(printf '%s' "$HOOK_DATA" | python3 -c "
import json,sys
try: print(json.load(sys.stdin).get('hook_event_name',''))
except: print('')
" 2>/dev/null)"

# SessionEnd 이벤트만 처리 (다른 이벤트는 즉시 통과)
[ "$EVENT" = "SessionEnd" ] || exit 0

COLLAR_DIR="$(cd "$(dirname "$0")/.." && pwd)"
[ -d "$COLLAR_DIR" ] || exit 0
CONFIG_FILE="$COLLAR_DIR/config.json"
PROJECT_DIR="$(cd "$COLLAR_DIR/.." && pwd)"

# ── 설정값: auto_compact 비활성이면 보존도 생략 ─────────────────────
AUTO_COMPACT=true
if [ -f "$CONFIG_FILE" ]; then
  AUTO_COMPACT="$(python3 -c "
import json, pathlib
try:
    d = json.loads(pathlib.Path('$CONFIG_FILE').read_text())
    print('true' if d.get('watchdog', {}).get('auto_compact', True) else 'false')
except: print('true')
" 2>/dev/null || echo true)"
fi
[ "$AUTO_COMPACT" != "true" ] && exit 0

# ── 쿨다운: session-monitor 가 방금 compact 했으면 재실행 불필요 ─────
# 60-session-monitor.sh 와 동일한 락을 공유 → 5분 이내 중복 compact 방지
LOCK_FILE="$COLLAR_DIR/.compact-lock"
if [ -f "$LOCK_FILE" ]; then
  LOCK_AGE="$(python3 -c "import os,time; print(int(time.time() - os.path.getmtime('$LOCK_FILE')))" 2>/dev/null || echo 999)"
  [ "$LOCK_AGE" -lt 300 ] 2>/dev/null && exit 0
fi

# ── collar-compact 탐색 (PATH → ~/.collar/bin 폴백) ─────────────────
COLLAR_COMPACT_BIN=""
command -v collar-compact >/dev/null 2>&1 && COLLAR_COMPACT_BIN="collar-compact"
[ -z "$COLLAR_COMPACT_BIN" ] && [ -x "$HOME/.collar/bin/collar-compact" ] && \
  COLLAR_COMPACT_BIN="$HOME/.collar/bin/collar-compact"
[ -z "$COLLAR_COMPACT_BIN" ] && exit 0

# 락 갱신 → 다음 세션 시작 직후 session-monitor 와의 중복 방지
touch "$LOCK_FILE" 2>/dev/null || true

# ── fire-and-forget: SessionEnd 는 차단 불가 → nohup 백그라운드 실행 ──
# 종료 흐름을 막지 않도록 즉시 detach. transcript 는 SessionEnd 시점에도 존재한다.
( cd "$PROJECT_DIR" && nohup "$COLLAR_COMPACT_BIN" >/dev/null 2>&1 & ) >/dev/null 2>&1

exit 0
