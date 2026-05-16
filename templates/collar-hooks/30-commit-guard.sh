#!/usr/bin/env bash
# collar commit-guard hook — PostToolUse: Bash 실행 후 미커밋 변경 감지 → 경고
#
# 목적: AI가 코드를 변경하고 커밋 없이 작업 "완료"를 선언하는 것을 방지
#       lottery 프로젝트 사고 재발방지 (2026-05-16)
#
# 동작:
#   1. PostToolUse + Bash 이벤트만 처리
#   2. git status로 미커밋 변경 감지
#   3. 변경이 있으면 커밋 의무 리마인더 출력 (hard block 아님)

HOOK_DATA="$(cat)"

# PostToolUse + Bash 이벤트만 처리
EVENT="$(echo "$HOOK_DATA" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get('hook_event_name',''))
except: print('')
" 2>/dev/null)"
[ "$EVENT" = "PostToolUse" ] || exit 0

TOOL="$(echo "$HOOK_DATA" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get('tool_name',''))
except: print('')
" 2>/dev/null)"
[ "$TOOL" = "Bash" ] || exit 0

# 실행된 명령어 확인 (git 커밋/add/push 명령은 스킵)
CMD="$(echo "$HOOK_DATA" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    inp=d.get('tool_input',{})
    print(inp.get('command',''))
except: print('')
" 2>/dev/null)"

# git 관련 명령이면 스킵 (커밋 중이거나 git 작업 중)
if echo "$CMD" | grep -qE '^\s*git (commit|add|push|status|diff|log|stash|tag)'; then
  exit 0
fi

# 읽기 전용 명령 스킵 (grep, cat, ls, find, echo 등)
if echo "$CMD" | grep -qE '^\s*(grep|cat|ls|find|echo|head|tail|wc|which|python|node|ruby|go run|cargo run|uv run pytest)'; then
  exit 0
fi

# CWD 추출
CWD="$(echo "$HOOK_DATA" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get('cwd',''))
except: print('')
" 2>/dev/null)"
[ -z "$CWD" ] && exit 0

# git 레포인지 확인
cd "$CWD" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# 미커밋 변경 감지
UNCOMMITTED="$(git status --porcelain 2>/dev/null | grep -v '^??' || true)"
[ -z "$UNCOMMITTED" ] && exit 0

# 변경된 파일 수
CHANGED_COUNT="$(echo "$UNCOMMITTED" | grep -c . || echo 0)"

TS="$(date '+%Y-%m-%d %H:%M')"
echo "COLLAR_COMMITGUARD: [$TS] 미커밋 변경 ${CHANGED_COUNT}개 감지."
echo "  규칙: 작업 완료 후 반드시 커밋. '완료'를 선언하기 전에 git commit을 실행하라."
echo "  변경 파일: $(echo "$UNCOMMITTED" | head -3 | awk '{print $2}' | tr '\n' ', ' | sed 's/,$//')"
