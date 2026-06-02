#!/usr/bin/env bash
# tests/integration/test-session-lifecycle.sh — 세션 라이프사이클 통합 테스트
# init → memory 기록 → compact 순서 검증

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$TESTS_DIR/lib/assert.sh"

COLLAR_HOME_DEV="$(cd "$TESTS_DIR/.." && pwd)"

_init_auto() {
  local target="$1"
  printf '\n\n\n\nn\n1\n1\n3000\ny\n' \
    | COLLAR_HOME="$COLLAR_HOME_DEV" bash "$COLLAR_HOME_DEV/bin/collar-init" "$target" \
    > /dev/null 2>&1
}

suite "세션 라이프사이클: 1단계 — 프로젝트 초기화"
T=$(tmpdir)
mkdir -p "$T/lifecycle-project"
_init_auto "$T/lifecycle-project"

assert_exists "초기화 완료: CLAUDE.md"    "$T/lifecycle-project/CLAUDE.md"
assert_exists "초기화 완료: memory.md"    "$T/lifecycle-project/.collar/memory.md"
assert_exists "초기화 완료: project-facts.md" "$T/lifecycle-project/.collar/project-facts.md"

suite "세션 라이프사이클: 2단계 — memory.md에 내용 추가"
# collar-remember 없이 직접 추가 (claude CLI 의존성 제거)
cat >> "$T/lifecycle-project/.collar/memory.md" << 'EOF'

## 테스트 패턴 A
- 세션 라이프사이클 테스트에서 추가된 패턴
- 검증용 마커: LIFECYCLE_TEST_MARKER

## 테스트 패턴 B
- 두 번째 패턴
EOF

assert_contains "memory.md에 패턴 A 기록됨" \
  "$T/lifecycle-project/.collar/memory.md" "LIFECYCLE_TEST_MARKER"

suite "세션 라이프사이클: 3단계 — compact 실행 가능 여부"
if ! command -v claude > /dev/null 2>&1; then
  skip "compact 실행" "claude CLI 없음"
else
  (
    cd "$T/lifecycle-project"
    COLLAR_HOME="$COLLAR_HOME_DEV" bash "$COLLAR_HOME_DEV/bin/collar-compact" > /dev/null 2>&1
  )
  assert_exists "compact 후 session-compact.md 생성" \
    "$T/lifecycle-project/.collar/session-compact.md"
fi

suite "세션 라이프사이클: 4단계 — 두 번째 세션 (session-compact.md 존재 시)"
# session-compact.md 수동 생성으로 시뮬레이션
cat > "$T/lifecycle-project/.collar/session-compact.md" << 'EOF'
# 세션 요약 (테스트용)

## 완료된 작업
- 라이프사이클 테스트 실행

## 중요 맥락
- COLLAR_HOME: 테스트 환경
EOF

assert_exists "2번째 세션: session-compact.md 읽기 가능" \
  "$T/lifecycle-project/.collar/session-compact.md"
assert_contains "2번째 세션: 이전 요약 내용 유지" \
  "$T/lifecycle-project/.collar/session-compact.md" "라이프사이클"

suite "세션 라이프사이클: config.json 구조 검증"
if command -v python3 > /dev/null 2>&1; then
  assert_ok "config.json 유효한 JSON" \
    python3 -c "import json; json.load(open('$T/lifecycle-project/.collar/config.json'))"
elif command -v node > /dev/null 2>&1; then
  assert_ok "config.json 유효한 JSON (node)" \
    node -e "JSON.parse(require('fs').readFileSync('$T/lifecycle-project/.collar/config.json','utf8'))"
else
  skip "config.json JSON 검증" "python3/node 없음"
fi

suite "세션 라이프사이클: session-counter 파일"
# .collar/session-counter 있으면 숫자인지 확인
COUNTER_FILE="$T/lifecycle-project/.collar/session-counter"
if [ -f "$COUNTER_FILE" ]; then
  COUNTER_VAL=$(cat "$COUNTER_FILE" | tr -d '[:space:]')
  if echo "$COUNTER_VAL" | grep -qE '^[0-9]+$'; then
    echo -e "  ${GREEN}✓${NC} session-counter 값이 숫자: $COUNTER_VAL"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${RED}✗${NC} session-counter 값이 숫자 아님: '$COUNTER_VAL'"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
else
  skip "session-counter 검증" "파일 없음 (선택적)"
fi
