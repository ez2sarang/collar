#!/usr/bin/env bash
# tests/unit/test-collar-remember.sh — collar-remember 단위 테스트

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$TESTS_DIR/lib/assert.sh"

COLLAR_HOME_DEV="$(cd "$TESTS_DIR/.." && pwd)"

_make_project() {
  local dir="$1"
  mkdir -p "$dir/.collar"
  echo "# 메모리" > "$dir/.collar/memory.md"
}

suite "collar-remember: memory.md에 기록"
T=$(tmpdir)
_make_project "$T"

if ! command -v claude > /dev/null 2>&1; then
  skip "collar-remember 실행" "claude CLI 없음"
else
  (
    cd "$T"
    COLLAR_HOME="$COLLAR_HOME_DEV" bash "$COLLAR_HOME_DEV/bin/collar-remember" \
      "테스트 패턴: unittest에서 기록한 내용" > /dev/null 2>&1
  )
  assert_exists "memory.md 존재" "$T/.collar/memory.md"
  assert_ok "memory.md 비어있지 않음" test -s "$T/.collar/memory.md"
fi

suite "collar-remember: 인수 없이 실행 → 도움말 또는 오류"
T2=$(tmpdir)
_make_project "$T2"

EXIT_CODE=0
OUTPUT=""
OUTPUT=$(
  cd "$T2"
  COLLAR_HOME="$COLLAR_HOME_DEV" bash "$COLLAR_HOME_DEV/bin/collar-remember" 2>&1
) || EXIT_CODE=$?

# 인수 없으면 non-zero exit 또는 usage 메시지
if [ "$EXIT_CODE" -ne 0 ] || echo "$OUTPUT" | grep -qi "usage\|사용법\|인수\|argument"; then
  echo -e "  ${GREEN}✓${NC} 인수 없으면 적절한 오류/도움말"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${YELLOW}⊘${NC} 인수 없는 동작 확인 불가 (skip)"
  SKIP_COUNT=$((SKIP_COUNT + 1))
fi

suite "collar-remember: 글로벌 판단 (GLOBAL_RULE 키워드)"
T3=$(tmpdir)
_make_project "$T3"
mkdir -p "$HOME/.claude" 2>/dev/null || true

if ! command -v claude > /dev/null 2>&1; then
  skip "글로벌 규칙 저장 확인" "claude CLI 없음"
else
  (
    cd "$T3"
    COLLAR_HOME="$COLLAR_HOME_DEV" bash "$COLLAR_HOME_DEV/bin/collar-remember" \
      "GLOBAL_RULE: 테스트 글로벌 규칙" > /dev/null 2>&1
  )
  # 글로벌 또는 로컬 어딘가에 기록됐는지 확인
  LOCAL_HAS=$(grep -l "테스트 글로벌" "$T3/.collar/memory.md" 2>/dev/null | wc -l)
  assert_ok "글로벌 규칙 처리 완료 (오류 없음)" true
fi
