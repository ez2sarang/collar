#!/usr/bin/env bash
# tests/unit/test-syntax-all.sh — 모든 bin/ 스크립트 구문 + 실행권한 검사

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$TESTS_DIR/lib/assert.sh"

COLLAR_HOME_DEV="$(cd "$TESTS_DIR/.." && pwd)"

suite "bin/ 스크립트: 구문 유효성 (bash -n)"
for script in "$COLLAR_HOME_DEV/bin/"*; do
  name="$(basename "$script")"
  assert_ok "$name: 구문 유효" bash -n "$script"
done

suite "bin/ 스크립트: 실행 권한"
for script in "$COLLAR_HOME_DEV/bin/"*; do
  name="$(basename "$script")"
  assert_executable "$name: 실행 권한 있음" "$script"
done

suite "bin/ 스크립트: shebang 존재"
for script in "$COLLAR_HOME_DEV/bin/"*; do
  name="$(basename "$script")"
  SHEBANG=$(head -1 "$script")
  if echo "$SHEBANG" | grep -q "^#!"; then
    echo -e "  ${GREEN}✓${NC} $name: shebang 있음"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${RED}✗${NC} $name: shebang 없음"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
done

suite "bin/ 스크립트: set -e 또는 set -euo 포함"
for script in "$COLLAR_HOME_DEV/bin/"*; do
  name="$(basename "$script")"
  if grep -q "set -e" "$script"; then
    echo -e "  ${GREEN}✓${NC} $name: set -e 있음"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${YELLOW}⊘${NC} $name: set -e 없음 (경고)"
    SKIP_COUNT=$((SKIP_COUNT + 1))
  fi
done

suite "templates/ 파일: 필수 placeholder 존재"
TEMPLATE_CLAUDE="$COLLAR_HOME_DEV/templates/CLAUDE.md.base"
TEMPLATE_AGENTS="$COLLAR_HOME_DEV/templates/AGENTS.md.base"

assert_exists "CLAUDE.md.base 존재" "$TEMPLATE_CLAUDE"
assert_exists "AGENTS.md.base 존재" "$TEMPLATE_AGENTS"
assert_exists "config.json 존재" "$COLLAR_HOME_DEV/templates/config.json"
assert_exists "collar-dispatcher.sh 존재" "$COLLAR_HOME_DEV/templates/collar-dispatcher.sh"
assert_exists "github-check.sh 존재" "$COLLAR_HOME_DEV/templates/github-check.sh"
assert_exists "session-monitor.sh 존재" "$COLLAR_HOME_DEV/templates/session-monitor.sh"

# CLAUDE.md.base 에 핵심 섹션 존재
assert_contains "CLAUDE.md.base: 세션 프로토콜 섹션" "$TEMPLATE_CLAUDE" "세션\|session"
assert_contains "CLAUDE.md.base: 목표 항목" "$TEMPLATE_CLAUDE" "목표\|goal\|Goal\|PROJECT"

suite "templates/collar-hooks/: 훅 파일 구문 검사"
HOOKS_DIR="$COLLAR_HOME_DEV/templates/collar-hooks"
assert_exists "collar-hooks/ 디렉토리" "$HOOKS_DIR"

for hook in "$HOOKS_DIR/"*.sh; do
  [ -f "$hook" ] || continue
  name="$(basename "$hook")"
  assert_ok "$name: 구문 유효" bash -n "$hook"
done

suite "templates/collar-hooks/: 훅 번호 체계 (10/20/30/50)"
for expected in "10-" "20-" "30-" "50-"; do
  FOUND=$(ls "$HOOKS_DIR/${expected}"* 2>/dev/null | wc -l | tr -d ' ')
  if [ "$FOUND" -ge 1 ]; then
    echo -e "  ${GREEN}✓${NC} ${expected}* 훅 존재 ($FOUND개)"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${RED}✗${NC} ${expected}* 훅 없음"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
done
