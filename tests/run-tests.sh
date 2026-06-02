#!/usr/bin/env bash
# tests/run-tests.sh — collar 전체 테스트 러너
#
# 사용법:
#   bash tests/run-tests.sh              # 전체 실행
#   bash tests/run-tests.sh --unit       # 단위 테스트만
#   bash tests/run-tests.sh --integration # 통합 테스트만
#   bash tests/run-tests.sh --e2e        # e2e 테스트만
#   bash tests/run-tests.sh --fast       # claude CLI 불필요 테스트만
#   bash tests/run-tests.sh --file <path> # 특정 파일만

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COLLAR_HOME_DEV="$(cd "$TESTS_DIR/.." && pwd)"

# ── 색상 ──────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── 카운터 (서브셸에서 파일로 누적) ───────────────────────────────
COUNTER_FILE="/tmp/collar-test-counters-$$"
echo "0 0 0" > "$COUNTER_FILE"   # PASS FAIL SKIP
trap 'rm -f "$COUNTER_FILE"; rm -rf /tmp/collar-test-$$*' EXIT

add_counts() {
  local p="$1" f="$2" s="$3"
  read -r cur_p cur_f cur_s < "$COUNTER_FILE"
  echo "$((cur_p + p)) $((cur_f + f)) $((cur_s + s))" > "$COUNTER_FILE"
}

# ── 인수 파싱 ─────────────────────────────────────────────────────
RUN_UNIT=true
RUN_INTEGRATION=true
RUN_E2E=true
FAST_MODE=false
SINGLE_FILE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --unit)         RUN_UNIT=true; RUN_INTEGRATION=false; RUN_E2E=false ;;
    --integration)  RUN_UNIT=false; RUN_INTEGRATION=true; RUN_E2E=false ;;
    --e2e)          RUN_UNIT=false; RUN_INTEGRATION=false; RUN_E2E=true ;;
    --fast)         FAST_MODE=true ;;
    --file)         shift; SINGLE_FILE="$1" ;;
    --help|-h)
      echo "사용법: $0 [--unit|--integration|--e2e|--fast|--file <path>]"
      exit 0 ;;
    *) echo "알 수 없는 인수: $1"; exit 1 ;;
  esac
  shift
done

# ── 환경 정보 출력 ────────────────────────────────────────────────
echo -e "${BOLD}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║       collar 전체 테스트 수트                    ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════╝${NC}"
echo -e "${CYAN}레포:${NC}    $COLLAR_HOME_DEV"
echo -e "${CYAN}날짜:${NC}    $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "${CYAN}모드:${NC}    $([ "$FAST_MODE" = "true" ] && echo "FAST (claude CLI 불필요)" || echo "FULL")"
echo -e "${CYAN}claude:${NC}  $(command -v claude 2>/dev/null && claude --version 2>/dev/null | head -1 || echo '미설치')"
echo -e "${CYAN}node:${NC}    $(node --version 2>/dev/null || echo '미설치')"
echo -e "${CYAN}bash:${NC}    $(bash --version | head -1)"
echo ""

# ── 테스트 파일 실행 헬퍼 ────────────────────────────────────────
run_test_file() {
  local file="$1"
  local label="$(basename "$file" .sh)"

  # fast 모드: claude 의존 파일 건너뜀
  if [ "$FAST_MODE" = "true" ]; then
    case "$label" in
      test-collar-compact|test-collar-remember|test-collar-global)
        echo -e "\n${YELLOW}⊘ $label${NC} (fast 모드 skip: claude CLI 필요)"
        add_counts 0 0 1
        return 0 ;;
    esac
  fi

  echo -e "\n${BOLD}── $label ──${NC}"

  # 서브셸에서 실행 → 카운터를 임시 파일로 받아옴
  local sub_counter="/tmp/collar-test-sub-$$-$RANDOM"
  (
    # 서브셸 전용 카운터 초기화
    PASS_COUNT=0; FAIL_COUNT=0; SKIP_COUNT=0
    TMP_ROOT="/tmp/collar-test-$$-$(basename "$file" .sh)"
    export TMP_ROOT PASS_COUNT FAIL_COUNT SKIP_COUNT
    bash "$file" 2>&1
    echo "$PASS_COUNT $FAIL_COUNT $SKIP_COUNT" > "$sub_counter"
  ) || true

  if [ -f "$sub_counter" ]; then
    read -r sp sf ss < "$sub_counter" || { sp=0; sf=0; ss=0; }
    rm -f "$sub_counter"
    add_counts "$sp" "$sf" "$ss"
  fi
}

# ── 테스트 수집 + 실행 ────────────────────────────────────────────
START_TIME=$(date +%s)

if [ -n "$SINGLE_FILE" ]; then
  run_test_file "$SINGLE_FILE"
else
  if [ "$RUN_UNIT" = "true" ]; then
    echo -e "\n${BOLD}${CYAN}━━━ 단위 테스트 (unit/) ━━━${NC}"
    for f in "$TESTS_DIR/unit/"test-*.sh; do
      [ -f "$f" ] && run_test_file "$f"
    done
  fi

  if [ "$RUN_INTEGRATION" = "true" ]; then
    echo -e "\n${BOLD}${CYAN}━━━ 통합 테스트 (integration/) ━━━${NC}"
    for f in "$TESTS_DIR/integration/"test-*.sh; do
      [ -f "$f" ] && run_test_file "$f"
    done
  fi

  if [ "$RUN_E2E" = "true" ]; then
    echo -e "\n${BOLD}${CYAN}━━━ E2E 테스트 (e2e/) ━━━${NC}"
    for f in "$TESTS_DIR/e2e/"test-*.sh; do
      [ -f "$f" ] && run_test_file "$f"
    done
  fi
fi

# ── 최종 요약 ─────────────────────────────────────────────────────
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
read -r TOTAL_PASS TOTAL_FAIL TOTAL_SKIP < "$COUNTER_FILE"
TOTAL=$((TOTAL_PASS + TOTAL_FAIL + TOTAL_SKIP))

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║                  테스트 결과 요약                ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════╝${NC}"
echo ""
printf "  %-12s %s\n" "전체" "$TOTAL 개"
printf "  %-12s ${GREEN}%s${NC}\n" "통과 ✓" "$TOTAL_PASS 개"
printf "  %-12s ${RED}%s${NC}\n" "실패 ✗" "$TOTAL_FAIL 개"
printf "  %-12s ${YELLOW}%s${NC}\n" "건너뜀 ⊘" "$TOTAL_SKIP 개"
printf "  %-12s %s\n" "소요 시간" "${ELAPSED}초"
echo ""

if [ "$TOTAL_FAIL" -eq 0 ]; then
  echo -e "${GREEN}${BOLD}  ✅ 모든 테스트 통과!${NC}"
  EXIT_CODE=0
else
  echo -e "${RED}${BOLD}  ❌ 실패 $TOTAL_FAIL개 — 위 로그를 확인하세요${NC}"
  EXIT_CODE=1
fi

echo ""
exit $EXIT_CODE
