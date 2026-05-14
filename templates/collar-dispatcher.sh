#!/usr/bin/env bash
# collar-dispatcher — Layer 1 native hook (OMX 이중 훅 패턴)
#
# 구조:
#   Layer 1 (Native)  : .claude/settings.json → collar-dispatcher.sh
#   Layer 2 (Collar)  : .collar/hooks/*.sh  (각 기능별 분리)
#
# .claude/settings.json에 이 파일 하나만 등록하면,
# .collar/hooks/ 아래 추가되는 모든 훅이 자동으로 실행된다.

# stdin 캡처 (Claude Code가 hook event JSON을 stdin으로 전달)
HOOK_DATA="$(cat)"

# CWD 추출 (stdin JSON에서) — 없으면 현재 디렉토리 사용
CWD="$(echo "$HOOK_DATA" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get('cwd',''))
except: print('')
" 2>/dev/null)"
[ -z "$CWD" ] && CWD="$(pwd)"

# .collar 디렉토리 탐색 (CWD에서 루트까지 위로 올라가며 탐색)
COLLAR_DIR=""
CHECK="$CWD"
while [ "$CHECK" != "/" ]; do
  if [ -d "$CHECK/.collar/hooks" ]; then
    COLLAR_DIR="$CHECK/.collar"
    break
  fi
  CHECK="$(dirname "$CHECK")"
done

# .collar 없으면 조용히 종료 (collar 미설치 프로젝트는 무시)
[ -z "$COLLAR_DIR" ] && exit 0

# .collar/hooks/*.sh 를 이름 순서대로 실행
# (파일명 앞에 숫자를 붙여 순서 제어 가능: 10-session-monitor.sh, 20-github-check.sh)
for HOOK in $(ls "$COLLAR_DIR/hooks/"*.sh 2>/dev/null | sort); do
  [ -f "$HOOK" ] || continue
  [ -x "$HOOK" ] || continue
  # dispatcher 자기 자신은 건너뜀
  [ "$(basename "$HOOK")" = "collar-dispatcher.sh" ] && continue
  # 각 훅에 같은 stdin 데이터 전달
  echo "$HOOK_DATA" | bash "$HOOK"
done
