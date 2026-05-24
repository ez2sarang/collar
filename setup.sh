#!/usr/bin/env bash
# collar setup — $HOME/.collar 에 설치
#
# 사용법:
#   ./setup.sh            # ~/.collar 에 설치 (기본값)
#   ./setup.sh --uninstall

set -euo pipefail

INSTALL_DIR="$HOME/.collar"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 언인스톨 ──────────────────────────────────────────────────────────
if [ "${1:-}" = "--uninstall" ]; then
  echo "🗑️  collar 제거: $INSTALL_DIR/bin"
  rm -f "$INSTALL_DIR/bin/collar-init" \
        "$INSTALL_DIR/bin/collar-interview" \
        "$INSTALL_DIR/bin/collar-watchdog" \
        "$INSTALL_DIR/bin/collar-compact" \
        "$INSTALL_DIR/bin/collar-remember" \
        "$INSTALL_DIR/bin/collar-update" \
        "$INSTALL_DIR/bin/collar-github" \
        "$INSTALL_DIR/bin/collar-global" \
        "$INSTALL_DIR/bin/collar-eval-model" \
        "$INSTALL_DIR/bin/collar-usage" \
        "$INSTALL_DIR/bin/collar-template-sync" \
        "$INSTALL_DIR/bin/collar-conductor"
  rm -rf "$INSTALL_DIR/templates"
  echo "✅ bin/ 및 templates/ 제거 완료."
  echo "   ~/.collar/ 디렉토리 자체는 유지됩니다 (프로젝트 데이터 보호)."
  exit 0
fi

# ── 설치 ─────────────────────────────────────────────────────────────
echo "📦 collar 설치 → $INSTALL_DIR"
echo ""

mkdir -p "$INSTALL_DIR/bin" "$INSTALL_DIR/templates"

# bin/ 복사 + 실행 권한
for f in "$SCRIPT_DIR/bin/"*; do
  cp "$f" "$INSTALL_DIR/bin/"
  chmod +x "$INSTALL_DIR/bin/$(basename "$f")"
done
echo "✅ bin/ 설치 완료 ($(ls "$SCRIPT_DIR/bin/" | wc -l | tr -d ' ')개 도구)"

# templates/ 복사 (서브디렉토리 포함)
cp -r "$SCRIPT_DIR/templates/"* "$INSTALL_DIR/templates/"
echo "✅ templates/ 설치 완료"

# package/prompts/ 복사 (collar-conductor 에이전트 프롬프트)
mkdir -p "$INSTALL_DIR/package/prompts"
cp -r "$SCRIPT_DIR/package/prompts/"* "$INSTALL_DIR/package/prompts/"
echo "✅ package/prompts/ 설치 완료 ($(ls "$SCRIPT_DIR/package/prompts/" | wc -l | tr -d ' ')개 프롬프트)"

# ── PATH 안내 ─────────────────────────────────────────────────────────
echo ""
SHELL_RC=""
if [ -n "${ZSH_VERSION:-}" ] || [ "$(basename "${SHELL:-}")" = "zsh" ]; then
  SHELL_RC="$HOME/.zshrc"
elif [ -n "${BASH_VERSION:-}" ] || [ "$(basename "${SHELL:-}")" = "bash" ]; then
  SHELL_RC="$HOME/.bashrc"
fi

PATH_LINE='export PATH="$HOME/.collar/bin:$PATH"'

if [ -n "$SHELL_RC" ] && grep -q '\.collar/bin' "$SHELL_RC" 2>/dev/null; then
  echo "ℹ️  PATH 이미 등록됨: $SHELL_RC"
else
  echo "PATH에 추가가 필요합니다:"
  echo ""
  echo "  $PATH_LINE"
  echo ""
  if [ -n "$SHELL_RC" ]; then
    echo -n "자동으로 $SHELL_RC 에 추가할까요? [y/N]: "
    read -r add_path
    if [ "${add_path:-N}" = "y" ] || [ "${add_path:-N}" = "Y" ]; then
      echo "" >> "$SHELL_RC"
      echo "# collar" >> "$SHELL_RC"
      echo "$PATH_LINE" >> "$SHELL_RC"
      echo "✅ $SHELL_RC 에 추가 완료. 새 터미널 또는 'source $SHELL_RC' 실행."
    else
      echo "수동으로 위 줄을 shell rc 파일에 추가하세요."
    fi
  fi
fi

echo ""
echo "🎉 collar 설치 완료!"
echo ""
echo "시작하기:"
echo "  cd 내-프로젝트"
echo "  collar-init"
echo "  collar-watchdog"
