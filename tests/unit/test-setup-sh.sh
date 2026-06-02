#!/usr/bin/env bash
# tests/unit/test-setup-sh.sh — setup.sh 설치/제거 단위 테스트

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$TESTS_DIR/lib/assert.sh"

COLLAR_HOME_DEV="$(cd "$TESTS_DIR/.." && pwd)"

suite "setup.sh: 구문 유효성"
assert_ok "setup.sh bash 구문 유효" bash -n "$COLLAR_HOME_DEV/setup.sh"

suite "setup.sh: 임시 경로에 설치"
T=$(tmpdir)
FAKE_HOME="$T/fake-home"
mkdir -p "$FAKE_HOME"

# INSTALL_DIR을 임시 경로로 오버라이드해서 실제 ~/.collar 건드리지 않음
INSTALL_DIR="$FAKE_HOME/.collar" bash "$COLLAR_HOME_DEV/setup.sh" > /dev/null 2>&1 || true

# bin/ 복사 확인
assert_exists "설치 후 bin/ 디렉토리" "$FAKE_HOME/.collar/bin"
assert_exists "collar-init 설치됨" "$FAKE_HOME/.collar/bin/collar-init"
assert_exists "collar-compact 설치됨" "$FAKE_HOME/.collar/bin/collar-compact"
assert_exists "collar-github 설치됨" "$FAKE_HOME/.collar/bin/collar-github"
assert_exists "collar-remember 설치됨" "$FAKE_HOME/.collar/bin/collar-remember"
assert_exists "collar-watchdog 설치됨" "$FAKE_HOME/.collar/bin/collar-watchdog"
assert_exists "collar-conductor 설치됨" "$FAKE_HOME/.collar/bin/collar-conductor"

# templates/ 복사 확인
assert_exists "설치 후 templates/ 디렉토리" "$FAKE_HOME/.collar/templates"
assert_exists "CLAUDE.md.base 설치됨" "$FAKE_HOME/.collar/templates/CLAUDE.md.base"
assert_exists "config.json 설치됨" "$FAKE_HOME/.collar/templates/config.json"

suite "setup.sh: 설치된 bin/ 실행 권한"
for script in "$FAKE_HOME/.collar/bin/"*; do
  [ -f "$script" ] || continue
  assert_executable "$(basename "$script"): 실행 권한" "$script"
done

suite "setup.sh: --uninstall 실행"
T2=$(tmpdir)
FAKE_HOME2="$T2/fake-home2"
mkdir -p "$FAKE_HOME2"

# 먼저 설치
INSTALL_DIR="$FAKE_HOME2/.collar" bash "$COLLAR_HOME_DEV/setup.sh" > /dev/null 2>&1 || true

# 제거
INSTALL_DIR="$FAKE_HOME2/.collar" bash "$COLLAR_HOME_DEV/setup.sh" --uninstall > /dev/null 2>&1 || true

assert_not_exists "uninstall 후 collar-init 없음" "$FAKE_HOME2/.collar/bin/collar-init"
assert_not_exists "uninstall 후 templates/ 없음" "$FAKE_HOME2/.collar/templates"

suite "setup.sh: bin/ 파일 수 일치 (레포 ↔ 설치본)"
T3=$(tmpdir)
FAKE_HOME3="$T3/fake-home3"
mkdir -p "$FAKE_HOME3"
INSTALL_DIR="$FAKE_HOME3/.collar" bash "$COLLAR_HOME_DEV/setup.sh" > /dev/null 2>&1 || true

REPO_COUNT=$(ls "$COLLAR_HOME_DEV/bin/" | wc -l | tr -d ' ')
INST_COUNT=$(ls "$FAKE_HOME3/.collar/bin/" 2>/dev/null | wc -l | tr -d ' ')
assert_eq "설치된 bin 파일 수 = 레포 bin 파일 수" "$REPO_COUNT" "$INST_COUNT"
