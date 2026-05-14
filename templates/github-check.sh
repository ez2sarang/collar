#!/usr/bin/env bash
# collar github-check hook — Layer 2 collar hook
# SessionStart 시 실행 → 미처리 GitHub 이슈 자동 확인

# stdin에서 hook event JSON 읽기
HOOK_DATA="$(cat)"

# SessionStart 이벤트만 처리 (다른 이벤트에서 실수로 실행되면 무시)
EVENT="$(echo "$HOOK_DATA" | python3 -c "
import json,sys
try: print(json.load(sys.stdin).get('hook_event_name',''))
except: print('')
" 2>/dev/null)"
[ "$EVENT" = "SessionStart" ] || [ "$EVENT" = "" ] || exit 0

COLLAR_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GITHUB_CONFIG="$COLLAR_DIR/github.json"

# github.json 없거나 비활성화 → 조용히 종료
[ -f "$GITHUB_CONFIG" ] || exit 0
ENABLED="$(python3 -c "
import json,pathlib
try:
    d=json.loads(pathlib.Path('$GITHUB_CONFIG').read_text())
    print(str(d.get('enabled', False)))
except: print('False')
" 2>/dev/null)"
[ "$ENABLED" = "True" ] || exit 0

# collar-github run 실행 (PATH에 있으면 그것, 없으면 절대경로)
COLLAR_GITHUB_BIN=""
command -v collar-github >/dev/null 2>&1 && COLLAR_GITHUB_BIN="collar-github"
[ -z "$COLLAR_GITHUB_BIN" ] && [ -x "$HOME/.collar/bin/collar-github" ] && \
  COLLAR_GITHUB_BIN="$HOME/.collar/bin/collar-github"

[ -z "$COLLAR_GITHUB_BIN" ] && exit 0

PROJECT_DIR="$(cd "$COLLAR_DIR/.." && pwd)"
TS="$(date '+%Y-%m-%d %H:%M')"

OUTPUT="$(COLLAR_GITHUB_TARGET="$PROJECT_DIR" "$COLLAR_GITHUB_BIN" run 2>&1 | tail -10)"
echo "COLLAR_GITHUB: [$TS] 세션 시작 GitHub 체크 완료."
echo "$OUTPUT" | grep -E "^\s+#[0-9]+" | head -5 || true
