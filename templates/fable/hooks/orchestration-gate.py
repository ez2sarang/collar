#!/usr/bin/env python3
# ~/.claude/fable/hooks/orchestration-gate.py — fable 강제 게이트 (PreToolUse)
#
# 메인 에이전트가 한 턴(prompt_id)에 코드 파일을 LIMIT개까지만 직접 수정하게 허용하고,
# 그 이후부터 차단하며 위임 지시를 돌려준다. Bash를 통한 코드 파일 수정은 항상 차단.
# 서브에이전트(payload에 agent_id/agent_type 존재)는 전부 통과 — 위임이 실행 경로다.
# 스위치(~/.claude/fable/fable-state)가 off면 모든 검사를 건너뛴다.
# 오류 시 통과(fail-open): 게이트가 버그로 죽어도 세션이 마비되지 않는다.
#
# prompt_id 필드는 Claude Code v2.1.196+ 에서 제공된다. 없으면 통과시킨다.

import json
import os
import re
import sys

LIMIT = 2

CODE_EXTS = {
    ".py", ".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".go", ".rs", ".java",
    ".kt", ".kts", ".c", ".cc", ".cpp", ".h", ".hpp", ".m", ".mm", ".rb", ".php",
    ".swift", ".sh", ".bash", ".zsh", ".sql", ".vue", ".svelte", ".dart", ".scala",
    ".pl", ".lua", ".ex", ".exs", ".css", ".scss", ".less",
}

FABLE_HOME = os.path.expanduser("~/.claude/fable")
STATE_DIR = os.path.join(FABLE_HOME, "state")
GATE_STATE = os.path.join(STATE_DIR, "gate.json")

# Bash 우회 경로: 코드 파일을 셸로 고치는 패턴은 개수와 무관하게 차단
BASH_WRITE_PATTERNS = [
    r"\bsed\s+(-[a-zA-Z]*\s+)*-i",          # sed -i / sed -E -i
    r"\bperl\s+(-[a-zA-Z]*\s+)*-i",         # perl -i
    r"\btee\s+(-a\s+)?(\S+)",               # tee file
    r">>?\s*(\S+)",                          # > file / >> file
]


def allow():
    sys.exit(0)


def deny(msg):
    print(msg, file=sys.stderr)
    sys.exit(2)


def is_code_file(path):
    _, ext = os.path.splitext(path or "")
    return ext.lower() in CODE_EXTS


def bash_touches_code(command):
    for pat in BASH_WRITE_PATTERNS:
        for m in re.finditer(pat, command):
            groups = [g for g in m.groups() if g]
            # sed/perl -i: 대상 파일은 명령 끝쪽 인자 — 명령 전체에서 코드 확장자 탐색
            if pat.startswith(r"\bsed") or pat.startswith(r"\bperl"):
                if any(is_code_file(tok.strip("'\"")) for tok in command.split()):
                    return True
            else:
                target = groups[-1].strip("'\"") if groups else ""
                if is_code_file(target):
                    return True
    return False


def load_state():
    try:
        with open(GATE_STATE) as f:
            return json.load(f)
    except Exception:
        return {}


def save_state(state):
    os.makedirs(STATE_DIR, exist_ok=True)
    # 세션 엔트리가 무한히 쌓이지 않게 최근 50개만 유지
    if len(state) > 50:
        for key in list(state.keys())[: len(state) - 50]:
            state.pop(key, None)
    tmp = GATE_STATE + ".tmp"
    with open(tmp, "w") as f:
        json.dump(state, f)
    os.replace(tmp, GATE_STATE)


def main():
    # 스위치 off → 전부 통과
    try:
        with open(os.path.join(FABLE_HOME, "fable-state")) as f:
            if f.read().strip() != "on":
                allow()
    except Exception:
        allow()

    data = json.load(sys.stdin)

    # 서브에이전트 호출은 전부 통과 — 위임이 실행 경로다
    if data.get("agent_id") or data.get("agent_type"):
        allow()

    tool = data.get("tool_name", "")
    tool_input = data.get("tool_input", {}) or {}

    if tool == "Bash":
        command = tool_input.get("command", "") or ""
        if bash_touches_code(command):
            deny(
                "[fable 게이트] Bash로 코드 파일을 수정하는 우회 경로는 차단됩니다. "
                "이 작업을 서브에이전트(executor 등)에 위임하세요."
            )
        allow()

    if tool not in ("Write", "Edit", "MultiEdit", "NotebookEdit"):
        allow()

    path = tool_input.get("file_path") or tool_input.get("notebook_path") or ""
    if not is_code_file(path):
        allow()  # md/json/yaml 같은 설정·문서 파일은 제한하지 않는다

    prompt_id = data.get("prompt_id")
    if not prompt_id:
        allow()  # 턴 경계를 알 수 없으면 fail-open

    session_id = data.get("session_id", "default")
    state = load_state()
    gate = state.get(session_id, {})
    if gate.get("prompt_id") != prompt_id:
        gate = {"prompt_id": prompt_id, "files": []}  # 새 턴 → 카운터 리셋

    files = gate.get("files", [])
    norm = os.path.abspath(os.path.expanduser(path))
    if norm in files:
        allow()  # 같은 파일 재수정은 개수에 세지 않는다

    if len(files) >= LIMIT:
        deny(
            f"[fable 게이트] 이 턴에서 이미 코드 파일 {LIMIT}개를 직접 수정했습니다. "
            f"추가 코드 수정({os.path.basename(norm)})은 재시도하지 말고 "
            "서브에이전트(executor 등)에 위임하세요."
        )

    files.append(norm)
    gate["files"] = files
    state[session_id] = gate
    save_state(state)
    allow()


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception:
        sys.exit(0)  # fail-open
