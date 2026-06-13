#!/usr/bin/env bash
# collar session-monitor hook — Layer 2 collar hook
# collar-dispatcher.sh 가 stdin을 파이프로 전달해 실행
#
# 트리거 방식 (우선순위):
#   1순위: ctx% (transcript 의 실제 토큰 usage 기반 — Claude 네이티브 미터와 일치)
#   2순위: 메시지 카운트 폴백 (transcript/usage 없을 때)

# stdin에서 hook event JSON 읽기
HOOK_DATA="$(cat)"

# UserPromptSubmit + PostToolUse 이벤트만 처리
EVENT="$(echo "$HOOK_DATA" | python3 -c "
import json,sys
try: print(json.load(sys.stdin).get('hook_event_name',''))
except: print('')
" 2>/dev/null)"
[ "$EVENT" = "UserPromptSubmit" ] || [ "$EVENT" = "PostToolUse" ] || [ "$EVENT" = "" ] || exit 0

COLLAR_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COUNTER_FILE="$COLLAR_DIR/session-counter"
CONFIG_FILE="$COLLAR_DIR/config.json"
PROJECT_DIR="$(cd "$COLLAR_DIR/.." && pwd)"

# ── 설정값 읽기 ────────────────────────────────────────────────────
CTX_THRESHOLD=80   # %: 이 이상이면 compact 실행
CTX_TARGET=15      # %: compact 목표 수준 (collar-compact에 전달)
MSG_THRESHOLD=20   # 폴백: transcript 없을 때 메시지 카운트
CTX_LIMIT=200000   # 컨텍스트 창 토큰 한도 (200K 기본; config 로 재정의 가능)
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
    print('CTX_LIMIT='     + str(w.get('context_token_limit', 200000)))
    print('AUTO_COMPACT='  + ('true' if w.get('auto_compact', True) else 'false'))
except: pass
" 2>/dev/null)"
fi

# ── memory.md 중복 섹션 자동 감지 + 정리 ─────────────────────────
# PostToolUse는 빈도가 높으므로 UserPromptSubmit에서만 실행
MEMORY_FILE="$COLLAR_DIR/memory.md"
if [ "$EVENT" = "UserPromptSubmit" ] && [ -f "$MEMORY_FILE" ]; then
  DEDUP_RESULT="$(python3 - "$MEMORY_FILE" << 'PYEOF'
import pathlib, re, sys
from collections import defaultdict

memory_path = sys.argv[1]
content = pathlib.Path(memory_path).read_text()

# h3 헤더([DATE] TITLE 형식) 위치 전부 찾기
h3_pattern = re.compile(r'\n(### \[(\d{4}-\d{2}-\d{2})\] (.+))\n')
headers = list(h3_pattern.finditer(content))

if not headers:
    sys.exit(0)

# 섹션별 분리: (start, end, date, title)
sections = []
for i, m in enumerate(headers):
    start = m.start()
    end = headers[i+1].start() if i + 1 < len(headers) else len(content)
    sections.append({'start': start, 'end': end,
                     'date': m.group(2), 'title': m.group(3).strip(),
                     'text': content[start:end]})

# 같은 title이 2개 이상이면 최신 날짜만 유지
by_title = defaultdict(list)
for s in sections:
    by_title[s['title']].append(s)

to_remove = set()
for title, group in by_title.items():
    if len(group) > 1:
        for s in sorted(group, key=lambda x: x['date'])[:-1]:
            to_remove.add(id(s))

if not to_remove:
    sys.exit(0)

preamble = content[:headers[0].start()]
kept = [s for s in sections if id(s) not in to_remove]
pathlib.Path(memory_path).write_text(preamble + ''.join(s['text'] for s in kept))
print(len(to_remove))
PYEOF
  )" 2>/dev/null || true

  if [ -n "$DEDUP_RESULT" ] && [ "$DEDUP_RESULT" != "0" ]; then
    TS_NOW="$(date '+%Y-%m-%d %H:%M')"
    echo "COLLAR_WATCHDOG: [$TS_NOW] memory.md 중복 ${DEDUP_RESULT}개 자동 정리 완료."
  fi
fi

# ── ctx% 측정 (실제 토큰 usage 기반) ───────────────────────────────
# Claude Code transcript JSONL 의 마지막 메인스레드 assistant 턴 usage 에서
# 실제 컨텍스트 점유량을 읽는다: input + cache_creation + cache_read
# = 그 턴에 컨텍스트 창을 채운 실제 토큰 수 → Claude 네이티브 미터와 일치한다.
# (구버전은 transcript 바이트 ÷ 7.4MB 로 "대화 증분"만 측정 → 스크린샷·tool 결과로
#  바이트가 폭증하면 실제 토큰과 무관하게 100% 오탐 → 낮은 ctx 에서도 compact 폭주.
#  transcript 는 compact 해도 줄지 않으므로 한번 커지면 영구 고정됨. usage 직접 읽기로 교체.)
# 서브에이전트(isSidechain) 턴은 별도 컨텍스트이므로 제외한다.
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
  CTX_PCT="$(python3 - "$TRANSCRIPT" "$CTX_LIMIT" <<'PYEOF'
import json, sys
path, limit = sys.argv[1], int(sys.argv[2])
try:
    lines = open(path).read().splitlines()
except Exception:
    print(-1); sys.exit(0)
total = None
for ln in reversed(lines):                 # 최신 턴부터 역순 탐색
    try:
        d = json.loads(ln)
    except Exception:
        continue
    if d.get('isSidechain'):               # 서브에이전트 컨텍스트 제외
        continue
    msg = d.get('message') if isinstance(d.get('message'), dict) else {}
    u = msg.get('usage') or d.get('usage')
    if not isinstance(u, dict):
        continue
    total = (u.get('input_tokens', 0)
             + u.get('cache_creation_input_tokens', 0)
             + u.get('cache_read_input_tokens', 0))
    break
if total is None:
    print(-1)                              # usage 못 찾음 → 폴백 신호
else:
    pct = int(total * 100 / limit) if limit > 0 else 0
    print(min(pct, 100))
PYEOF
)"
  CTX_PCT="${CTX_PCT:--1}"
  if [ "$CTX_PCT" -lt 0 ] 2>/dev/null; then
    # transcript 에 usage 없음 → 메시지 카운트 폴백
    USE_MSG_FALLBACK=true
    CTX_PCT=0
  fi
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

# 쿨다운: 마지막 compact 실행 후 5분 이내면 스킵 (PostToolUse 폭발 방지)
LOCK_FILE="$COLLAR_DIR/.compact-lock"
if [ -f "$LOCK_FILE" ]; then
  LOCK_AGE="$(python3 -c "import os,time; print(int(time.time() - os.path.getmtime('$LOCK_FILE')))" 2>/dev/null || echo 999)"
  [ "$LOCK_AGE" -lt 300 ] 2>/dev/null && exit 0
fi

COLLAR_COMPACT_BIN=""
command -v collar-compact >/dev/null 2>&1 && COLLAR_COMPACT_BIN="collar-compact"
[ -z "$COLLAR_COMPACT_BIN" ] && [ -x "$HOME/.collar/bin/collar-compact" ] && \
  COLLAR_COMPACT_BIN="$HOME/.collar/bin/collar-compact"

TS="$(date '+%Y-%m-%d %H:%M')"

if [ -z "$COLLAR_COMPACT_BIN" ]; then
  echo "COLLAR_WATCHDOG: [$TS] collar-compact 없음. PATH에 collar/bin 추가 필요."
  exit 0
fi

# 락 파일 갱신 → 5분간 재실행 방지
touch "$LOCK_FILE"

# compact 실행 (프로젝트 디렉토리 기준)
cd "$PROJECT_DIR" && "$COLLAR_COMPACT_BIN" 2>/dev/null

# (usage 기반 측정에서는 compact 후 다음 턴 usage 가 자동으로 줄므로
#  별도의 transcript baseline 저장이 필요 없다 — 구버전 .transcript-baseline /
#  .baseline-session-id 기준점 로직 제거됨.)

# 카운터 리셋 (폴백 모드일 때)
[ "$USE_MSG_FALLBACK" = "true" ] && echo "0" > "$COUNTER_FILE"

# ── Claude에 알림 출력 ─────────────────────────────────────────────
if [ "$USE_MSG_FALLBACK" = "true" ]; then
  echo "COLLAR_WATCHDOG: [$TS] 메시지 ${MSG_THRESHOLD}개 도달. 지금 즉시 /compact를 실행하라."
else
  echo "COLLAR_WATCHDOG: [$TS] ctx ${CTX_PCT}% (임계값 ${CTX_THRESHOLD}%) 초과. 지금 즉시 /compact를 실행하라."
fi
