#!/usr/bin/env bash
# collar 25-project-boundary-guard — PreToolUse: 다른 프로젝트 파일 수정 hard block
#
# 목적: 현재 세션 프로젝트(cwd) 외부 파일을 Write/Edit/MultiEdit 하려 할 때 exit 2로 차단
#       collar 세션에서 investments 파일 수정 등 프로젝트 격리 원칙 위반 방지
#       (2026-06-05 사용자 지적 — collar 세션에서 investments 파일 114회 조작 사건)
#
# 허용 예외:
#   ~/.claude/**  — 글로벌 AI 설정 (메모리, CLAUDE.md 등)
#   ~/.collar/**  — 글로벌 collar 바이너리/설정

HOOK_DATA="$(cat)"

PARSED="$(echo "$HOOK_DATA" | python3 -c "
import json, sys, os
try:
    d = json.load(sys.stdin)
    event = d.get('hook_event_name', '')
    tool  = d.get('tool_name', '')
    inp   = d.get('tool_input', {})
    fp    = inp.get('file_path', '')
    cwd   = d.get('cwd', os.getcwd())
    print(event + '|' + tool + '|' + fp + '|' + cwd)
except:
    print('|||')
" 2>/dev/null)"

EVENT_TYPE="${PARSED%%|*}"
REST="${PARSED#*|}"
TOOL_NAME="${REST%%|*}"
REST="${REST#*|}"
FILE_PATH="${REST%%|*}"
CWD="${REST#*|}"

# PreToolUse + Write/Edit/MultiEdit 이벤트만 처리
[ "$EVENT_TYPE" = "PreToolUse" ] || exit 0
{ [ "$TOOL_NAME" = "Write" ] || [ "$TOOL_NAME" = "Edit" ] || [ "$TOOL_NAME" = "MultiEdit" ]; } || exit 0

# 파일 경로 없으면 통과
[ -n "$FILE_PATH" ] || exit 0
[ -n "$CWD" ] || exit 0

# 절대경로 정규화
ABS_FILE=$(python3 -c "
import os, sys
fp = '$FILE_PATH'
if fp.startswith('~'):
    fp = os.path.expanduser(fp)
print(os.path.realpath(fp))
" 2>/dev/null || echo "$FILE_PATH")

ABS_CWD=$(python3 -c "
import os
print(os.path.realpath('$CWD'))
" 2>/dev/null || echo "$CWD")

HOME_DIR="$HOME"

# 파일이 현재 프로젝트 내에 있으면 통과
case "$ABS_FILE" in
    "$ABS_CWD"/*|"$ABS_CWD") exit 0 ;;
esac

# 글로벌 허용 경로 (AI 설정, collar 바이너리)
case "$ABS_FILE" in
    "$HOME_DIR/.claude/"*) exit 0 ;;
    "$HOME_DIR/.collar/"*) exit 0 ;;
    "/tmp/"*) exit 0 ;;
esac

# ── 차단 ──────────────────────────────────────────────────────────────
echo "" >&2
echo "[PROJECT-GUARD] 🚫  프로젝트 경계 위반 — 파일 수정 차단" >&2
echo "[PROJECT-GUARD] 현재 세션 프로젝트: $ABS_CWD" >&2
echo "[PROJECT-GUARD] 수정 시도 파일:     $ABS_FILE" >&2
echo "" >&2
echo "[PROJECT-GUARD] 해당 파일은 소속 프로젝트 세션에서 수정하세요." >&2
echo "[PROJECT-GUARD] 다른 프로젝트 작업이 필요하면 해당 디렉토리로 새 세션을 열어주세요." >&2
echo "" >&2
exit 2
