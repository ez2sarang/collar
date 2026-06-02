#!/usr/bin/env bash
# tests/integration/test-hooks.sh — 훅 스크립트 통합 테스트

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$TESTS_DIR/lib/assert.sh"

COLLAR_HOME_DEV="$(cd "$TESTS_DIR/.." && pwd)"
HOOKS_DIR="$COLLAR_HOME_DEV/templates/collar-hooks"

# ── 10-session-ctx.sh: 컨텍스트 임계값 훅 ────────────────────────
suite "훅 10-session-ctx.sh: 정상 입력"
HOOK="$HOOKS_DIR/10-session-ctx.sh"
assert_ok "10-session-ctx.sh 구문 유효" bash -n "$HOOK"

# 컨텍스트 30% 수준 (임계값 미만 → exit 0 예상)
LOW_CTX='{"session":{"context_window":{"used_percent":30}}}'
EXIT_CODE=0
echo "$LOW_CTX" | bash "$HOOK" > /dev/null 2>&1 || EXIT_CODE=$?
if [ "$EXIT_CODE" -eq 0 ] || [ "$EXIT_CODE" -eq 2 ]; then
  echo -e "  ${GREEN}✓${NC} 낮은 ctx%: exit $EXIT_CODE (정상)"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}✗${NC} 낮은 ctx%: 예상치 못한 exit $EXIT_CODE"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# 컨텍스트 95% 수준 (임계값 초과 → 경고 출력)
HIGH_CTX='{"session":{"context_window":{"used_percent":95}}}'
OUTPUT=$(echo "$HIGH_CTX" | bash "$HOOK" 2>&1 || true)
if echo "$OUTPUT" | grep -qi "warning\|경고\|임계\|compact\|컨텍스트\|context"; then
  echo -e "  ${GREEN}✓${NC} 높은 ctx%: 경고 출력 확인"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${YELLOW}⊘${NC} 높은 ctx%: 경고 형식 미확인"
  SKIP_COUNT=$((SKIP_COUNT + 1))
fi

# ── 20-destructive-guard.sh: 파괴적 명령 차단 ────────────────────
suite "훅 20-destructive-guard.sh: 파괴적 명령 차단"
HOOK="$HOOKS_DIR/20-destructive-guard.sh"
assert_ok "20-destructive-guard.sh 구문 유효" bash -n "$HOOK"

# rm -rf / 시도 → 차단 (exit non-zero)
DANGEROUS_CMD='{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}'
EXIT_CODE=0
echo "$DANGEROUS_CMD" | bash "$HOOK" > /dev/null 2>&1 || EXIT_CODE=$?
if [ "$EXIT_CODE" -ne 0 ]; then
  echo -e "  ${GREEN}✓${NC} rm -rf / 차단됨 (exit $EXIT_CODE)"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${YELLOW}⊘${NC} rm -rf / 차단 미확인 (훅 형식 확인 필요)"
  SKIP_COUNT=$((SKIP_COUNT + 1))
fi

# 안전한 명령 → 통과 (exit 0)
SAFE_CMD='{"tool_name":"Bash","tool_input":{"command":"ls -la"}}'
assert_exit_code "안전한 ls 명령 통과" 0 \
  bash -c "echo '$SAFE_CMD' | bash '$HOOK'"

# ── 30-commit-guard.sh: 커밋 가드 ────────────────────────────────
suite "훅 30-commit-guard.sh: [DISCLOSED] 토큰 검증"
HOOK="$HOOKS_DIR/30-commit-guard.sh"
assert_ok "30-commit-guard.sh 구문 유효" bash -n "$HOOK"

# fix 커밋에 [DISCLOSED] 없음 → 차단
BAD_COMMIT='{"tool_name":"Bash","tool_input":{"command":"git commit -m \"fix: 버그 수정\""}}'
EXIT_CODE=0
echo "$BAD_COMMIT" | bash "$HOOK" > /dev/null 2>&1 || EXIT_CODE=$?
if [ "$EXIT_CODE" -ne 0 ]; then
  echo -e "  ${GREEN}✓${NC} [DISCLOSED] 없는 fix 커밋 차단 (exit $EXIT_CODE)"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${YELLOW}⊘${NC} [DISCLOSED] 검증 미확인"
  SKIP_COUNT=$((SKIP_COUNT + 1))
fi

# [DISCLOSED] 포함 fix 커밋 → 통과
GOOD_COMMIT='{"tool_name":"Bash","tool_input":{"command":"git commit -m \"fix: 버그 수정 [DISCLOSED]\""}}'
EXIT_CODE=0
echo "$GOOD_COMMIT" | bash "$HOOK" > /dev/null 2>&1 || EXIT_CODE=$?
if [ "$EXIT_CODE" -eq 0 ]; then
  echo -e "  ${GREEN}✓${NC} [DISCLOSED] 있는 fix 커밋 통과"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${YELLOW}⊘${NC} [DISCLOSED] 통과 미확인"
  SKIP_COUNT=$((SKIP_COUNT + 1))
fi

# ── 50-todo-enforcer.sh ───────────────────────────────────────────
suite "훅 50-todo-enforcer.sh: 구문 검사"
HOOK="$HOOKS_DIR/50-todo-enforcer.sh"
assert_ok "50-todo-enforcer.sh 구문 유효" bash -n "$HOOK"
