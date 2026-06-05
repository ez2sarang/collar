#!/usr/bin/env bash
# collar 10-session-ctx — SessionStart: 프로젝트 컨텍스트 자동 주입
#
# 목적: 세션 시작 시 session-compact.md + memory.md + project-facts.md 내용을
#       system-reminder로 직접 주입 → AI가 파일을 수동으로 읽을 필요 없음
#       (2026-06-05 개선 — "힌트만 주는" 방식에서 "내용 직접 주입"으로 전환)

HOOK_DATA="$(cat)"

EVENT=$(printf '%s' "$HOOK_DATA" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get('hook_event_name',''))
except: print('')
" 2>/dev/null)

[ "$EVENT" = "SessionStart" ] || exit 0

# .collar 위치 탐지
COLLAR_DIR="$(pwd)/.collar"
[ -d "$COLLAR_DIR" ] || exit 0

COMPACT_FILE="$COLLAR_DIR/session-compact.md"
MEMORY_FILE="$COLLAR_DIR/memory.md"
FACTS_FILE="$COLLAR_DIR/project-facts.md"

echo "=== COLLAR AUTO-CONTEXT (세션 시작 자동 주입) ==="
echo ""

# ── project-facts.md (운영 사실 — 포트, DB, 명령어) ──────────────────
if [ -f "$FACTS_FILE" ]; then
  echo "## [project-facts.md]"
  cat "$FACTS_FILE"
  echo ""
fi

# ── session-compact.md (이전 세션 핵심 요약) ────────────────────────
if [ -f "$COMPACT_FILE" ]; then
  # Hashline 검증
  STORED_HASH=$(grep -o 'COLLAR_HASH: [a-f0-9]*' "$COMPACT_FILE" 2>/dev/null | awk '{print $2}')
  if [ -n "$STORED_HASH" ]; then
    CONTENT=$(grep -v "COLLAR_HASH:" "$COMPACT_FILE")
    ACTUAL=$(printf '%s' "$CONTENT" | sha256sum 2>/dev/null | cut -c1-8 || printf '%s' "$CONTENT" | md5sum | cut -c1-8)
    if [ "$STORED_HASH" != "$ACTUAL" ]; then
      echo "⚠️  session-compact.md Hashline 불일치 — 외부 수정 가능성. memory.md를 우선 신뢰."
      echo ""
    fi
  fi

  echo "## [session-compact.md — 이전 세션 요약]"
  # 최대 150줄 (너무 크면 컨텍스트 낭비)
  head -150 "$COMPACT_FILE"
  echo ""
fi

# ── memory.md (프로젝트 학습 패턴) ───────────────────────────────────
if [ -f "$MEMORY_FILE" ]; then
  echo "## [memory.md — 축적된 패턴]"
  head -80 "$MEMORY_FILE"
  echo ""
fi

echo "=== /COLLAR AUTO-CONTEXT ==="
