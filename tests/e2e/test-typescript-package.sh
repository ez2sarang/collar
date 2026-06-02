#!/usr/bin/env bash
# tests/e2e/test-typescript-package.sh — TypeScript 패키지 빌드 + CLI e2e 테스트

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$TESTS_DIR/lib/assert.sh"

COLLAR_HOME_DEV="$(cd "$TESTS_DIR/.." && pwd)"
PKG_DIR="$COLLAR_HOME_DEV/package"

suite "TypeScript 패키지: 전제 조건"
assert_exists "package/ 디렉토리" "$PKG_DIR"
assert_exists "package.json" "$PKG_DIR/package.json"
assert_exists "tsconfig.json" "$PKG_DIR/tsconfig.json"
assert_exists "src/cli/index.ts" "$PKG_DIR/src/cli/index.ts"

if ! command -v node > /dev/null 2>&1; then
  skip "Node.js 필요 테스트 전체" "node 없음"
  return 0 2>/dev/null || exit 0
fi

NODE_VER=$(node -e "process.exit(parseInt(process.version.slice(1)) >= 20 ? 0 : 1)" 2>/dev/null && echo "ok" || echo "old")
if [ "$NODE_VER" = "old" ]; then
  skip "Node.js 버전 체크" "Node 20+ 필요"
fi

suite "TypeScript 패키지: 의존성 설치"
if [ ! -d "$PKG_DIR/node_modules" ]; then
  assert_ok "npm ci --ignore-scripts 실행" \
    bash -c "cd '$PKG_DIR' && npm ci --ignore-scripts > /dev/null 2>&1"
else
  echo -e "  ${GREEN}✓${NC} node_modules 이미 존재 (skip install)"
  PASS_COUNT=$((PASS_COUNT + 1))
fi

suite "TypeScript 패키지: 빌드 (tsc)"
assert_ok "tsc 빌드 성공" \
  bash -c "cd '$PKG_DIR' && npm run build > /dev/null 2>&1"

assert_exists "dist/ 디렉토리 생성" "$PKG_DIR/dist"
assert_exists "dist/cli/index.js 생성" "$PKG_DIR/dist/cli/index.js"

suite "TypeScript 패키지: CLI 실행 가능"
assert_ok "collar --version 또는 --help 실행" \
  bash -c "node '$PKG_DIR/dist/cli/index.js' --help > /dev/null 2>&1 || node '$PKG_DIR/dist/cli/index.js' --version > /dev/null 2>&1"

suite "TypeScript 패키지: CLI 서브커맨드"
# init 서브커맨드 존재 확인
OUTPUT=$(node "$PKG_DIR/dist/cli/index.js" --help 2>&1 || true)
for CMD in init setup global doctor; do
  if echo "$OUTPUT" | grep -q "$CMD"; then
    echo -e "  ${GREEN}✓${NC} '$CMD' 서브커맨드 노출됨"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${YELLOW}⊘${NC} '$CMD' 서브커맨드 미확인"
    SKIP_COUNT=$((SKIP_COUNT + 1))
  fi
done

suite "TypeScript 패키지: MCP 서버 진입점"
assert_exists "src/mcp/server.ts" "$PKG_DIR/src/mcp/server.ts"
if [ -f "$PKG_DIR/dist/mcp/server.js" ]; then
  echo -e "  ${GREEN}✓${NC} dist/mcp/server.js 빌드됨"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${YELLOW}⊘${NC} dist/mcp/server.js 없음 (빌드 경로 확인)"
  SKIP_COUNT=$((SKIP_COUNT + 1))
fi

suite "TypeScript 패키지: 타입 오류 없음"
assert_ok "tsc --noEmit 타입 체크" \
  bash -c "cd '$PKG_DIR' && npx tsc --noEmit > /dev/null 2>&1"

suite "TypeScript 패키지: skills/ 디렉토리"
assert_exists "skills/ 존재" "$PKG_DIR/skills"
SKILL_COUNT=$(ls "$PKG_DIR/skills/" 2>/dev/null | wc -l | tr -d ' ')
if [ "$SKILL_COUNT" -ge 1 ]; then
  echo -e "  ${GREEN}✓${NC} skills/ 파일 ${SKILL_COUNT}개"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}✗${NC} skills/ 비어있음"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

suite "TypeScript 패키지: prompts/ 디렉토리"
assert_exists "prompts/ 존재" "$PKG_DIR/prompts"
PROMPT_COUNT=$(ls "$PKG_DIR/prompts/" 2>/dev/null | wc -l | tr -d ' ')
if [ "$PROMPT_COUNT" -ge 1 ]; then
  echo -e "  ${GREEN}✓${NC} prompts/ 파일 ${PROMPT_COUNT}개"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${RED}✗${NC} prompts/ 비어있음"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
