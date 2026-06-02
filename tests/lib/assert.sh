#!/usr/bin/env bash
# tests/lib/assert.sh — 공통 테스트 헬퍼

# ── 색상 ──────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── 전역 카운터 (run-tests.sh에서 공유) ──────────────────────────
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
CURRENT_SUITE=""

# ── 임시 디렉토리 관리 ────────────────────────────────────────────
TMP_ROOT="${TMP_ROOT:-/tmp/collar-test-$$}"
mkdir -p "$TMP_ROOT"
trap 'rm -rf "$TMP_ROOT"' EXIT

tmpdir() {
  local d="$TMP_ROOT/$(date +%s%N 2>/dev/null || date +%s)-$RANDOM"
  mkdir -p "$d"
  echo "$d"
}

# ── Suite/Test 구조 ───────────────────────────────────────────────
suite() {
  CURRENT_SUITE="$1"
  echo -e "\n${BOLD}${CYAN}▶ $CURRENT_SUITE${NC}"
}

# ── 핵심 assert 함수들 ────────────────────────────────────────────

# assert_ok <description> <cmd...>
assert_ok() {
  local desc="$1"; shift
  if "$@" > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} $desc"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${RED}✗${NC} $desc"
    echo -e "    ${YELLOW}cmd:${NC} $*"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# assert_fail <description> <cmd...>  (명령이 실패해야 통과)
assert_fail() {
  local desc="$1"; shift
  if "$@" > /dev/null 2>&1; then
    echo -e "  ${RED}✗${NC} $desc (expected failure, but succeeded)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  else
    echo -e "  ${GREEN}✓${NC} $desc"
    PASS_COUNT=$((PASS_COUNT + 1))
  fi
}

# assert_exists <description> <path>
assert_exists() {
  local desc="$1" path="$2"
  if [ -e "$path" ]; then
    echo -e "  ${GREEN}✓${NC} $desc"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${RED}✗${NC} $desc"
    echo -e "    ${YELLOW}expected:${NC} $path"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# assert_not_exists <description> <path>
assert_not_exists() {
  local desc="$1" path="$2"
  if [ ! -e "$path" ]; then
    echo -e "  ${GREEN}✓${NC} $desc"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${RED}✗${NC} $desc (should not exist: $path)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# assert_contains <description> <file> <pattern>
assert_contains() {
  local desc="$1" file="$2" pattern="$3"
  if grep -q "$pattern" "$file" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} $desc"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${RED}✗${NC} $desc"
    echo -e "    ${YELLOW}pattern '${pattern}' not found in:${NC} $file"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# assert_not_contains <description> <file> <pattern>
assert_not_contains() {
  local desc="$1" file="$2" pattern="$3"
  if ! grep -q "$pattern" "$file" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} $desc"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${RED}✗${NC} $desc"
    echo -e "    ${YELLOW}pattern '${pattern}' found (should not be) in:${NC} $file"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# assert_eq <description> <expected> <actual>
assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo -e "  ${GREEN}✓${NC} $desc"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${RED}✗${NC} $desc"
    echo -e "    ${YELLOW}expected:${NC} '$expected'"
    echo -e "    ${YELLOW}actual:  ${NC} '$actual'"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# assert_exit_code <description> <expected_code> <cmd...>
assert_exit_code() {
  local desc="$1" expected="$2"; shift 2
  "$@" > /dev/null 2>&1; local actual=$?
  if [ "$actual" = "$expected" ]; then
    echo -e "  ${GREEN}✓${NC} $desc"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${RED}✗${NC} $desc"
    echo -e "    ${YELLOW}expected exit $expected, got $actual${NC}"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# assert_executable <description> <path>
assert_executable() {
  local desc="$1" path="$2"
  if [ -x "$path" ]; then
    echo -e "  ${GREEN}✓${NC} $desc"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${RED}✗${NC} $desc (not executable: $path)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# assert_output_contains <description> <pattern> <cmd...>
assert_output_contains() {
  local desc="$1" pattern="$2"; shift 2
  local out
  out=$("$@" 2>&1)
  if echo "$out" | grep -q "$pattern"; then
    echo -e "  ${GREEN}✓${NC} $desc"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${RED}✗${NC} $desc"
    echo -e "    ${YELLOW}pattern '${pattern}' not in output${NC}"
    echo -e "    ${YELLOW}output:${NC} $(echo "$out" | head -5)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# skip <description> <reason>
skip() {
  echo -e "  ${YELLOW}⊘${NC} $1 (skipped: $2)"
  SKIP_COUNT=$((SKIP_COUNT + 1))
}

# ── stdin mock 헬퍼 ───────────────────────────────────────────────
# mock_stdin_run <answers_newline_separated> <cmd...>
mock_stdin_run() {
  local answers="$1"; shift
  echo -e "$answers" | "$@" 2>&1
}

# collar-init 전용 non-interactive 헬퍼
# collar-init에 모든 기본값 자동 입력 (Enter×N)
collar_init_auto() {
  local target="$1"
  # 언어(1), 목표, 프로바이더(1), CI(n), 패키지매니저(1), DB(1), 포트, 확인(y)
  printf '\n\n\n\nn\n1\n1\n3000\ny\n' | COLLAR_HOME="$COLLAR_HOME_DEV" bash "$COLLAR_HOME_DEV/bin/collar-init" "$target" 2>&1
}
