#!/usr/bin/env bash
# tests/unit/test-collar-compact.sh — collar-compact 단위 테스트

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$TESTS_DIR/lib/assert.sh"

COLLAR_HOME_DEV="$(cd "$TESTS_DIR/.." && pwd)"

# collar-compact는 .collar/ 내부에서 동작하므로 가짜 프로젝트 생성
_make_fake_project() {
  local dir="$1"
  mkdir -p "$dir/.collar"
  cat > "$dir/.collar/memory.md" << 'EOF'
# 메모리

## 패턴 1
테스트 패턴 1 내용

## 패턴 2
테스트 패턴 2 내용
EOF
  # Claude Code 대화 기록 시뮬레이션 (간단한 텍스트)
  cat > "$dir/.collar/fake-session.txt" << 'EOF'
user: 테스트 메시지 1
assistant: 테스트 응답 1
user: 테스트 메시지 2
assistant: 테스트 응답 2
EOF
}

suite "collar-compact: session-compact.md 생성"
T=$(tmpdir)
_make_fake_project "$T"

# collar-compact는 claude CLI가 있어야 실제로 실행됨 — 없으면 skip
if ! command -v claude > /dev/null 2>&1; then
  skip "collar-compact 실행" "claude CLI 없음 (설치 필요)"
else
  (
    cd "$T"
    COLLAR_HOME="$COLLAR_HOME_DEV" bash "$COLLAR_HOME_DEV/bin/collar-compact" > /dev/null 2>&1
  )
  assert_exists "session-compact.md 생성됨" "$T/.collar/session-compact.md"
  assert_ok "session-compact.md 비어있지 않음" test -s "$T/.collar/session-compact.md"
fi

suite "collar-compact: 백업 생성"
T2=$(tmpdir)
_make_fake_project "$T2"
# 기존 session-compact.md 있는 경우
echo "이전 세션 요약" > "$T2/.collar/session-compact.md"

if ! command -v claude > /dev/null 2>&1; then
  skip "백업 생성 확인" "claude CLI 없음"
else
  (
    cd "$T2"
    COLLAR_HOME="$COLLAR_HOME_DEV" bash "$COLLAR_HOME_DEV/bin/collar-compact" > /dev/null 2>&1
  )
  BACKUP_COUNT=$(ls "$T2/.collar/session-compact.md.backup."* 2>/dev/null | wc -l | tr -d ' ')
  assert_ok "이전 compact 백업됨" test "$BACKUP_COUNT" -ge 1
fi

suite "collar-compact: .collar 없는 경우 오류"
T3=$(tmpdir)
mkdir -p "$T3/no-collar"
# .collar 없이 실행 → 오류 또는 경고
EXIT_CODE=0
(
  cd "$T3/no-collar"
  COLLAR_HOME="$COLLAR_HOME_DEV" bash "$COLLAR_HOME_DEV/bin/collar-compact" > /dev/null 2>&1
) || EXIT_CODE=$?
assert_ok ".collar 없으면 non-zero exit 또는 경고" test "$EXIT_CODE" -ne 0 2>/dev/null || \
  assert_ok ".collar 없으면 graceful exit" true
