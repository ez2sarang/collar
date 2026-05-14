#!/usr/bin/env bash
# collar session-monitor hook — Layer 2 collar hook
# collar-dispatcher.sh 가 stdin을 파이프로 전달해 실행
#
# 트리거 방식 (우선순위):
#   1순위: ctx% 기반 (transcript 파일 크기로 추정)
#   2순위: 메시지 카운트 폴백 (transcript 없을 때)

# stdin에서 hook event JSON 읽기
HOOK_DATA="$(cat)"

# UserPromptSubmit 이벤트만 처리
EVENT="$(echo "$HOOK_DATA" | python3 -c "
import json,sys
try: print(json.load(sys.stdin).get('hook_event_name',''))
except: print('')
" 2>/dev/null)"
[ "$EVENT" = "UserPromptSubmit" ] || [ "$EVENT" = "" ] || exit 0

COLLAR_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COUNTER_FILE="$COLLAR_DIR/session-counter"
CONFIG_FILE="$COLLAR_DIR/config.json"
PROJECT_DIR="$(cd "$COLLAR_DIR/.." && pwd)"

# ── 설정값 읽기 ────────────────────────────────────────────────────
CTX_THRESHOLD=60   # %: 이 이상이면 compact 실행
CTX_TARGET=15      # %: compact 목표 수준 (collar-compact에 전달)
MSG_THRESHOLD=20   # 폴백: transcript 없을 때 메시지 카운트
AUTO_COMPACT=true

if [ -f "$CONFIG_FILE" ]; then
  eval "$(python3 -c "
import json, pathlib
try:
    d = json.loads(pathlib.Path('$CONFIG_FILE').read_text())
    w = d.get('watchdog', {})
    print('CTX_THRESHOLD=' + str(w.get('ctx_percent_threshold', 60)))
    print('CTX_TARGET='    + str(w.get('ctx_percent_target', 15)))
    print('MSG_THRESHOLD=' + str(w.get('message_threshold', 20)))
    print('AUTO_COMPACT='  + ('true' if w.get('auto_compact', True) else 'false'))
except: pass
" 2>/dev/null)"
fi

# ── ctx% 추정 ─────────────────────────────────────────────────────
# Claude Code는 200K 토큰 컨텍스트를 사용.
# transcript JSONL 파일 크기로 대화 누적량을 추정한다.
# JSONL에서 실제 토큰으로의 변환 비율: ~4.5 bytes/token (JSON 오버헤드 포함)
# 200K tokens × 4.5 = 900KB → 100%
TRANSCRIPT="$(echo "$HOOK_DATA" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get('transcript_path',''))
except: print('')
" 2>/dev/null)"

CTX_PCT=0
USE_MSG_FALLBACK=false

if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  TRANSCRIPT_BYTES="$(wc -c < "$TRANSCRIPT" 2>/dev/null || echo 0)"
  # 200K tokens at 4.5 bytes/token = 900000 bytes
  CTX_PCT="$(python3 -c "print(int($TRANSCRIPT_BYTES * 100 / 900000))" 2>/dev/null || echo 0)"
  # 100% 초과 클램핑
  [ "$CTX_PCT" -gt 100 ] 2>/dev/null && CTX_PCT=100
else
  # transcript 경로 없음 → 메시지 카운트 폴백
  USE_MSG_FALLBACK=true
fi

# ── 메시지 카운트 폴백 ─────────────────────────────────────────────
if [ "$USE_MSG_FALLBACK" = "true" ]; then
  CURRENT=0
  [ -f "$COUNTER_FILE" ] && CURRENT=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
  CURRENT=$((CURRENT + 1))
  echo "$CURRENT" > "$COUNTER_FILE"
  # 메시지 임계값 미달 → 종료
  [ "$CURRENT" -lt "$MSG_THRESHOLD" ] && exit 0
else
  # ctx% 임계값 미달 → 종료
  [ "$CTX_PCT" -lt "$CTX_THRESHOLD" ] 2>/dev/null && exit 0
fi

# ── compact 실행 ───────────────────────────────────────────────────
[ "$AUTO_COMPACT" != "true" ] && exit 0

COLLAR_COMPACT_BIN=""
command -v collar-compact >/dev/null 2>&1 && COLLAR_COMPACT_BIN="collar-compact"
[ -z "$COLLAR_COMPACT_BIN" ] && [ -x "$HOME/Documents/dev/ai/collar/bin/collar-compact" ] && \
  COLLAR_COMPACT_BIN="$HOME/Documents/dev/ai/collar/bin/collar-compact"

TS="$(date '+%Y-%m-%d %H:%M')"

if [ -z "$COLLAR_COMPACT_BIN" ]; then
  echo "COLLAR_WATCHDOG: [$TS] collar-compact 없음. PATH에 collar/bin 추가 필요."
  exit 0
fi

# compact 실행 (프로젝트 디렉토리 기준)
cd "$PROJECT_DIR" && "$COLLAR_COMPACT_BIN" 2>/dev/null

# 카운터 리셋 (폴백 모드일 때)
[ "$USE_MSG_FALLBACK" = "true" ] && echo "0" > "$COUNTER_FILE"

# ── Claude에 알림 출력 ─────────────────────────────────────────────
if [ "$USE_MSG_FALLBACK" = "true" ]; then
  echo "COLLAR_WATCHDOG: [$TS] 메시지 ${MSG_THRESHOLD}개 도달 → session-compact.md 갱신. 새 세션 권장."
else
  echo "COLLAR_WATCHDOG: [$TS] ctx ${CTX_PCT}% (임계값 ${CTX_THRESHOLD}%) → session-compact.md 갱신. 새 세션 권장."
fi
