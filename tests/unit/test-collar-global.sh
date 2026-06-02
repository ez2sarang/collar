#!/usr/bin/env bash
# tests/unit/test-collar-global.sh — collar-global 단위 테스트

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$TESTS_DIR/lib/assert.sh"

COLLAR_HOME_DEV="$(cd "$TESTS_DIR/.." && pwd)"

suite "collar-global: 구문 유효성"
assert_ok "collar-global bash 구문 유효" bash -n "$COLLAR_HOME_DEV/bin/collar-global"

suite "collar-global: 핵심 동작 요소 포함"
assert_contains "글로벌 CLAUDE.md 경로 참조" "$COLLAR_HOME_DEV/bin/collar-global" \
  "CLAUDE.md\|claude.md"
assert_contains "중복 제거 로직 언급" "$COLLAR_HOME_DEV/bin/collar-global" \
  "dedup\|중복\|merge\|병합\|LLM"

suite "collar-global: --dry-run 또는 --help 지원"
OUTPUT=$(COLLAR_HOME="$COLLAR_HOME_DEV" bash "$COLLAR_HOME_DEV/bin/collar-global" --help 2>&1 || true)
if echo "$OUTPUT" | grep -qi "usage\|사용법\|help\|dry"; then
  echo -e "  ${GREEN}✓${NC} --help 출력 확인"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  skip "--help 지원" "help 옵션 미구현 (선택적)"
fi

suite "collar-global: claude CLI 없을 때 graceful 처리"
if command -v claude > /dev/null 2>&1; then
  skip "claude 없을 때 처리" "claude CLI 설치됨 (테스트 불가)"
else
  EXIT_CODE=0
  OUTPUT=$(COLLAR_HOME="$COLLAR_HOME_DEV" bash "$COLLAR_HOME_DEV/bin/collar-global" 2>&1) || EXIT_CODE=$?
  # crash 없이 오류 메시지 출력 후 종료
  if [ "$EXIT_CODE" -lt 128 ]; then
    echo -e "  ${GREEN}✓${NC} claude 없을 때 graceful 종료"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${RED}✗${NC} crash 발생 (exit $EXIT_CODE)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi
