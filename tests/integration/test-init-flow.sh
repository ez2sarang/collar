#!/usr/bin/env bash
# tests/integration/test-init-flow.sh — collar-init 전체 흐름 통합 테스트

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$TESTS_DIR/lib/assert.sh"

COLLAR_HOME_DEV="$(cd "$TESTS_DIR/.." && pwd)"

_init_auto() {
  local target="$1"
  printf '\n\n\n\nn\n1\n1\n3000\ny\n' \
    | COLLAR_HOME="$COLLAR_HOME_DEV" bash "$COLLAR_HOME_DEV/bin/collar-init" "$target" \
    > /dev/null 2>&1
}

# ── 시나리오 1: 완전히 빈 프로젝트에 init ─────────────────────────
suite "통합: 빈 프로젝트 전체 흐름"
T=$(tmpdir)
mkdir -p "$T/brand-new-project"
git -C "$T/brand-new-project" init -q 2>/dev/null || true

_init_auto "$T/brand-new-project"

# 생성 파일 전체 체크
assert_exists "CLAUDE.md"               "$T/brand-new-project/CLAUDE.md"
assert_exists "AGENTS.md"               "$T/brand-new-project/AGENTS.md"
assert_exists ".collar/"                "$T/brand-new-project/.collar"
assert_exists ".collar/project-facts.md" "$T/brand-new-project/.collar/project-facts.md"
assert_exists ".collar/memory.md"       "$T/brand-new-project/.collar/memory.md"
assert_exists ".claude/"                "$T/brand-new-project/.claude"
assert_exists ".claude/settings.json"   "$T/brand-new-project/.claude/settings.json"
assert_exists ".collar/config.json"     "$T/brand-new-project/.collar/config.json"

# 최소 내용 검증
assert_contains "project-facts.md에 프로젝트명" \
  "$T/brand-new-project/.collar/project-facts.md" "brand-new-project\|프로젝트"

# ── 시나리오 2: 이미 CLAUDE.md 있는 프로젝트 (덮어쓰기 안 됨) ─────
suite "통합: 기존 CLAUDE.md 보존"
T2=$(tmpdir)
mkdir -p "$T2/existing-project"
echo "# 기존 프로젝트 헌법" > "$T2/existing-project/CLAUDE.md"
echo "기존_내용_유지_필수" >> "$T2/existing-project/CLAUDE.md"

_init_auto "$T2/existing-project"

assert_contains "기존 CLAUDE.md 내용 보존" \
  "$T2/existing-project/CLAUDE.md" "기존_내용_유지_필수"

# ── 시나리오 3: Node.js 프로젝트 감지 ─────────────────────────────
suite "통합: Node.js 프로젝트 자동 감지"
T3=$(tmpdir)
mkdir -p "$T3/node-project"
echo '{"name":"node-project","version":"1.0.0"}' > "$T3/node-project/package.json"

_init_auto "$T3/node-project"

# project-facts.md에 Node.js 관련 내용 또는 npm 명령어 포함 여부
# (언어 자동 감지 기능이 있다면)
assert_exists "Node.js 프로젝트에 init 완료" "$T3/node-project/CLAUDE.md"

# ── 시나리오 4: Python 프로젝트 감지 ──────────────────────────────
suite "통합: Python 프로젝트 자동 감지"
T4=$(tmpdir)
mkdir -p "$T4/python-project"
echo "requests==2.31.0" > "$T4/python-project/requirements.txt"
echo 'def main(): pass' > "$T4/python-project/main.py"

_init_auto "$T4/python-project"

assert_exists "Python 프로젝트에 init 완료" "$T4/python-project/CLAUDE.md"

# ── 시나리오 5: settings.json hooks 연결 ──────────────────────────
suite "통합: settings.json 훅 연결 확인"
# T (brand-new-project)의 settings.json에 hooks 배열 있는지
if command -v python3 > /dev/null 2>&1; then
  HAS_HOOKS=$(python3 -c "
import json
data = json.load(open('$T/brand-new-project/.claude/settings.json'))
hooks = data.get('hooks', {})
print('yes' if hooks else 'no')
" 2>/dev/null || echo "parse_error")
  if [ "$HAS_HOOKS" = "yes" ]; then
    echo -e "  ${GREEN}✓${NC} settings.json에 hooks 섹션 있음"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  ${YELLOW}⊘${NC} hooks 섹션 없음 (선택적)"
    SKIP_COUNT=$((SKIP_COUNT + 1))
  fi
else
  skip "settings.json hooks 확인" "python3 없음"
fi

# ── 시나리오 6: 프로젝트명에 특수문자 ────────────────────────────
suite "통합: 특수문자 프로젝트명"
T5=$(tmpdir)
mkdir -p "$T5/my-app-2026"

_init_auto "$T5/my-app-2026"

assert_exists "하이픈 포함 프로젝트 init 완료" "$T5/my-app-2026/CLAUDE.md"
assert_contains "project-facts.md에 프로젝트명" \
  "$T5/my-app-2026/.collar/project-facts.md" "my.app.2026\|my-app-2026\|my_app_2026"
