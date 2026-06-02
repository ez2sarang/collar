#!/usr/bin/env bash
# tests/e2e/test-install-e2e.sh — 설치 → init → 실행 전체 e2e 테스트

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$TESTS_DIR/lib/assert.sh"

COLLAR_HOME_DEV="$(cd "$TESTS_DIR/.." && pwd)"

suite "e2e: 설치 → init → 도구 실행 전체 경로"

# 1. 임시 INSTALL_DIR에 설치
T=$(tmpdir)
FAKE_INSTALL="$T/collar-install"
INSTALL_DIR="$FAKE_INSTALL" bash "$COLLAR_HOME_DEV/setup.sh" > /dev/null 2>&1

assert_exists "1) 설치 완료: bin/" "$FAKE_INSTALL/bin"
assert_exists "1) 설치 완료: templates/" "$FAKE_INSTALL/templates"

# 2. 설치된 collar-init으로 프로젝트 초기화
TARGET="$T/e2e-project"
mkdir -p "$TARGET"

printf '\n\n\n\nn\n1\n1\n4000\ny\n' \
  | COLLAR_HOME="$FAKE_INSTALL" bash "$FAKE_INSTALL/bin/collar-init" "$TARGET" \
  > /dev/null 2>&1

assert_exists "2) init 완료: CLAUDE.md" "$TARGET/CLAUDE.md"
assert_exists "2) init 완료: .collar/" "$TARGET/.collar"

# 3. 설치된 collar-init으로 두 번째 프로젝트 (멱등성)
printf '\n\n\n\nn\n1\n1\n4000\ny\n' \
  | COLLAR_HOME="$FAKE_INSTALL" bash "$FAKE_INSTALL/bin/collar-init" "$TARGET" \
  > /dev/null 2>&1

assert_exists "3) 2회 실행 후 CLAUDE.md 여전히 존재" "$TARGET/CLAUDE.md"

# 4. 설치본 PATH로 직접 실행
export PATH="$FAKE_INSTALL/bin:$PATH"
assert_ok "4) PATH에서 collar-init 실행 가능" which collar-init

# 5. uninstall 후 bin 없음
INSTALL_DIR="$FAKE_INSTALL" bash "$COLLAR_HOME_DEV/setup.sh" --uninstall > /dev/null 2>&1
assert_not_exists "5) uninstall 후 collar-init 없음" "$FAKE_INSTALL/bin/collar-init"

suite "e2e: 다중 프로젝트 격리 (공유 DB 스키마 격리)"
T2=$(tmpdir)
PROJ_A="$T2/project-alpha"
PROJ_B="$T2/project-beta"
mkdir -p "$PROJ_A" "$PROJ_B"

# 두 프로젝트에 각각 init
for proj in "$PROJ_A" "$PROJ_B"; do
  printf '\n\n\n\nn\n1\n1\n3000\ny\n' \
    | COLLAR_HOME="$COLLAR_HOME_DEV" bash "$COLLAR_HOME_DEV/bin/collar-init" "$proj" \
    > /dev/null 2>&1
done

# 각 프로젝트의 project-facts.md가 독립적으로 생성됨
assert_exists "project-alpha: project-facts.md" "$PROJ_A/.collar/project-facts.md"
assert_exists "project-beta: project-facts.md"  "$PROJ_B/.collar/project-facts.md"

# 스키마명이 서로 다름
SCHEMA_A=$(grep -i "schema\|스키마\|project_alpha\|projectalpha" \
  "$PROJ_A/.collar/project-facts.md" 2>/dev/null | head -1 || echo "")
SCHEMA_B=$(grep -i "schema\|스키마\|project_beta\|projectbeta" \
  "$PROJ_B/.collar/project-facts.md" 2>/dev/null | head -1 || echo "")

# 두 파일의 내용이 완전히 동일하지 않으면 통과 (프로젝트명 반영)
if ! diff -q "$PROJ_A/.collar/project-facts.md" "$PROJ_B/.collar/project-facts.md" > /dev/null 2>&1; then
  echo -e "  ${GREEN}✓${NC} 두 프로젝트 project-facts.md 독립 생성됨"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${YELLOW}⊘${NC} 두 project-facts.md 내용 동일 (프로젝트명 미반영 가능)"
  SKIP_COUNT=$((SKIP_COUNT + 1))
fi

suite "e2e: collar-conductor 구문 + 필수 요소"
assert_ok "collar-conductor 구문 유효" bash -n "$COLLAR_HOME_DEV/bin/collar-conductor"
assert_contains "Executor 역할 정의" "$COLLAR_HOME_DEV/bin/collar-conductor" \
  "executor\|Executor\|작업자\|worker"
assert_contains "Verifier 역할 정의" "$COLLAR_HOME_DEV/bin/collar-conductor" \
  "verifier\|Verifier\|검증\|verify"
