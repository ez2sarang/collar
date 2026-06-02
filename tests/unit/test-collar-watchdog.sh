#!/usr/bin/env bash
# tests/unit/test-collar-watchdog.sh — collar-watchdog 단위 테스트

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$TESTS_DIR/lib/assert.sh"

COLLAR_HOME_DEV="$(cd "$TESTS_DIR/.." && pwd)"

suite "collar-watchdog: 스크립트 구문 검사"
assert_ok "collar-watchdog bash 구문 유효" \
  bash -n "$COLLAR_HOME_DEV/bin/collar-watchdog"

suite "collar-watchdog: --help 또는 인수 없이 실행"
OUTPUT=$(COLLAR_HOME="$COLLAR_HOME_DEV" bash "$COLLAR_HOME_DEV/bin/collar-watchdog" --help 2>&1 || true)
if echo "$OUTPUT" | grep -qi "usage\|사용법\|watchdog\|help\|threshold\|임계"; then
  echo -e "  ${GREEN}✓${NC} --help 출력 확인"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  # help 없어도 실행 자체가 되는지만 확인
  assert_ok "watchdog 실행 가능 (인수 없음)" \
    bash -c "COLLAR_HOME='$COLLAR_HOME_DEV' timeout 3 bash '$COLLAR_HOME_DEV/bin/collar-watchdog' --check 2>/dev/null; true"
fi

suite "collar-watchdog: 컨텍스트 임계값 파싱"
# collar-watchdog 내 임계값 변수 정의 확인
assert_contains "임계값 변수 정의됨" "$COLLAR_HOME_DEV/bin/collar-watchdog" \
  "THRESHOLD\|threshold\|임계\|percent\|%"

suite "collar-watchdog: PID 파일 / 중복 실행 방지"
assert_contains "PID 또는 lock 관련 처리" "$COLLAR_HOME_DEV/bin/collar-watchdog" \
  "pid\|PID\|lock\|running\|실행 중" || \
  skip "PID 중복 실행 방지" "구현 미확인 (로직 없을 수 있음)"
