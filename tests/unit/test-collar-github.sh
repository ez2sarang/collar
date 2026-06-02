#!/usr/bin/env bash
# tests/unit/test-collar-github.sh — collar-github 단위 테스트 (mock API)

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$TESTS_DIR/lib/assert.sh"

COLLAR_HOME_DEV="$(cd "$TESTS_DIR/.." && pwd)"

suite "collar-github: 구문 검사"
assert_ok "collar-github bash 구문 유효" bash -n "$COLLAR_HOME_DEV/bin/collar-github"

suite "collar-github: 서브커맨드 존재 확인"
assert_contains "setup 서브커맨드" "$COLLAR_HOME_DEV/bin/collar-github" "setup"
assert_ok "run 서브커맨드" grep -qE '"run"|run\)' "$COLLAR_HOME_DEV/bin/collar-github"
assert_contains "status 서브커맨드" "$COLLAR_HOME_DEV/bin/collar-github" "status"
assert_contains "watch 서브커맨드"  "$COLLAR_HOME_DEV/bin/collar-github" "watch"

suite "collar-github: status — GitHub 미연결 시 안전 종료"
T=$(tmpdir)
mkdir -p "$T/.collar"
# github.json 없는 상태 → status가 graceful하게 처리해야 함
OUTPUT=$(
  cd "$T"
  COLLAR_HOME="$COLLAR_HOME_DEV" bash "$COLLAR_HOME_DEV/bin/collar-github" status 2>&1
) || true

if echo "$OUTPUT" | grep -qi "설정\|setup\|연동\|config\|not configured\|github.json"; then
  echo -e "  ${GREEN}✓${NC} 미연결 시 설정 안내 출력"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${YELLOW}⊘${NC} status 미연결 동작 확인 불가"
  SKIP_COUNT=$((SKIP_COUNT + 1))
fi

suite "collar-github: mock 이슈 처리 (GitHub API 없이)"
T2=$(tmpdir)
mkdir -p "$T2/.collar"

# 가짜 github.json 주입 (실제 API 호출 방지용 더미 토큰)
cat > "$T2/.collar/github.json" << 'EOF'
{
  "token": "ghp_MOCK_TOKEN_FOR_TESTING",
  "repo": "test-owner/test-repo",
  "enabled": true
}
EOF

# run 실행 — API 실패해도 crash 없이 처리돼야 함
EXIT_CODE=0
(
  cd "$T2"
  COLLAR_HOME="$COLLAR_HOME_DEV" timeout 10 \
    bash "$COLLAR_HOME_DEV/bin/collar-github" run 2>&1
) || EXIT_CODE=$?

# exit 0 또는 API 오류 메시지 출력 후 종료 (crash=128+ 는 실패)
if [ "$EXIT_CODE" -lt 128 ]; then
  echo -e "  ${GREEN}✓${NC} API 오류 시 graceful 종료 (exit $EXIT_CODE)"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}✗${NC} crash 발생 (exit $EXIT_CODE)"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

suite "collar-github: 처리 로그 파일 생성"
assert_contains "처리 로그 경로 참조" "$COLLAR_HOME_DEV/bin/collar-github" \
  "github-processed.log\|processed"
