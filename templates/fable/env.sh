# fable 오케스트레이션 스위치 — collar-fable 이 배포/관리
# 스위치가 on일 때만 claude 실행 시점에 Sonnet→Opus 4.8 리매핑을 주입한다.
# bashrc/zshrc 에 export 를 박아두면 스위치를 꺼도 계속 적용되므로,
# 실행 시점마다 상태 파일을 읽는 래퍼 함수로 만든다.

_fable_on() { [ "$(cat "$HOME/.claude/fable/fable-state" 2>/dev/null)" = "on" ]; }

_fable_run() {
  if _fable_on; then
    ANTHROPIC_DEFAULT_SONNET_MODEL="claude-opus-4-8" "$@"
  else
    "$@"
  fi
}

claude() { _fable_run command claude "$@"; }
