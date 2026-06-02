#!/usr/bin/env bash
# tests/unit/test-collar-init.sh — collar-init 단위 테스트

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$TESTS_DIR/lib/assert.sh"

COLLAR_HOME_DEV="$(cd "$TESTS_DIR/.." && pwd)"

suite "collar-init: 파일 생성 검증"

# 비대화형 자동 입력 헬퍼 (프롬프트 순서: 언어→목표→프로바이더→CI→패키지매니저→DB→포트→확인)
_init_project() {
  local target="$1"
  printf '\n\n\n\nn\n1\n1\n3000\ny\n' \
    | COLLAR_HOME="$COLLAR_HOME_DEV" bash "$COLLAR_HOME_DEV/bin/collar-init" "$target" \
    > /dev/null 2>&1
}

# ── 기본 파일 생성 ─────────────────────────────────────────────────
T=$(tmpdir)
mkdir -p "$T/my-project"
_init_project "$T/my-project"

assert_exists "CLAUDE.md 생성됨" "$T/my-project/CLAUDE.md"
assert_exists "AGENTS.md 생성됨" "$T/my-project/AGENTS.md"
assert_exists ".collar/ 디렉토리 생성됨" "$T/my-project/.collar"
assert_exists ".collar/project-facts.md 생성됨" "$T/my-project/.collar/project-facts.md"
assert_exists ".collar/memory.md 생성됨" "$T/my-project/.collar/memory.md"
assert_exists ".claude/ 디렉토리 생성됨" "$T/my-project/.claude"
assert_exists ".claude/settings.json 생성됨" "$T/my-project/.claude/settings.json"

# ── 파일 내용 검증 ─────────────────────────────────────────────────
suite "collar-init: 파일 내용 검증"
assert_contains "CLAUDE.md에 프로젝트명 포함" "$T/my-project/CLAUDE.md" "my-project"
assert_contains "project-facts.md에 포트 항목" "$T/my-project/.collar/project-facts.md" "포트\|PORT\|port\|3000"
assert_contains "settings.json이 JSON 형식" "$T/my-project/.claude/settings.json" '"permissions"\|"hooks"\|{'

# ── 멱등성: 2회 실행해도 기존 파일 덮어쓰지 않음 ──────────────────
suite "collar-init: 멱등성 (중복 실행)"
T2=$(tmpdir)
mkdir -p "$T2/idem-project"
_init_project "$T2/idem-project"

# CLAUDE.md에 수동 마커 추가
echo "# MANUAL_MARKER_DO_NOT_OVERWRITE" >> "$T2/idem-project/CLAUDE.md"

_init_project "$T2/idem-project"

assert_contains "CLAUDE.md 덮어쓰기 안 됨 (마커 보존)" "$T2/idem-project/CLAUDE.md" "MANUAL_MARKER_DO_NOT_OVERWRITE"

# ── 대상 디렉토리 인수 없이 현재 위치 사용 ────────────────────────
suite "collar-init: 인수 없이 현재 디렉토리 대상"
T3=$(tmpdir)
mkdir -p "$T3/cwd-project"
(
  cd "$T3/cwd-project"
  printf '\n\n\n\nn\n1\n1\n3000\ny\n' \
    | COLLAR_HOME="$COLLAR_HOME_DEV" bash "$COLLAR_HOME_DEV/bin/collar-init" \
    > /dev/null 2>&1
)
assert_exists "현재 디렉토리에 CLAUDE.md 생성" "$T3/cwd-project/CLAUDE.md"

# ── 존재하지 않는 경로 처리 ───────────────────────────────────────
suite "collar-init: 엣지케이스"
# 존재하지 않는 경로는 오류여야 함
assert_fail "존재하지 않는 경로 → 오류" \
  bash -c "COLLAR_HOME='$COLLAR_HOME_DEV' bash '$COLLAR_HOME_DEV/bin/collar-init' '/nonexistent/path/xyz' < /dev/null"

# ── DB 스키마명 변환 (camelCase → snake_case) ─────────────────────
suite "collar-init: DB 스키마명 변환"
T4=$(tmpdir)
mkdir -p "$T4/myAwesomeProject"
_init_project "$T4/myAwesomeProject"
assert_contains "camelCase → snake_case 변환됨" "$T4/myAwesomeProject/.collar/project-facts.md" "my_awesome_project\|myawesomeproject\|스키마"

# ── settings.json 유효한 JSON ─────────────────────────────────────
suite "collar-init: settings.json JSON 유효성"
if command -v python3 > /dev/null 2>&1; then
  assert_ok "settings.json 유효한 JSON" \
    python3 -c "import json,sys; json.load(open('$T/my-project/.claude/settings.json'))"
elif command -v node > /dev/null 2>&1; then
  assert_ok "settings.json 유효한 JSON (node)" \
    node -e "JSON.parse(require('fs').readFileSync('$T/my-project/.claude/settings.json','utf8'))"
else
  skip "settings.json JSON 유효성" "python3/node 없음"
fi
