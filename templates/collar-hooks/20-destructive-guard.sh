#!/usr/bin/env bash
# collar destructive-guard hook — PreToolUse: Bash 실행 전 파괴적 명령어 차단
#
# 목적: LLM이 DB 초기화, 테이블 삭제, 대량 파일 삭제 등
#       복구 불가능한 명령을 실행하는 것을 원천 차단
#
# 동작:
#   1. PreToolUse + Bash 이벤트만 처리
#   2. 명령어를 파괴적 패턴과 대조
#   3. 매칭 시 exit 2 (hard block) + 차단 사유 출력

HOOK_DATA="$(cat)"

# PreToolUse + Bash 이벤트만 처리
EVENT="$(echo "$HOOK_DATA" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get('hook_event_name',''))
except: print('')
" 2>/dev/null)"
[ "$EVENT" = "PreToolUse" ] || exit 0

TOOL="$(echo "$HOOK_DATA" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get('tool_name',''))
except: print('')
" 2>/dev/null)"
[ "$TOOL" = "Bash" ] || exit 0

CMD="$(echo "$HOOK_DATA" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get('tool_input',{}).get('command',''))
except: print('')
" 2>/dev/null)"

[ -z "$CMD" ] && exit 0

# 텍스트/읽기 전용 명령은 검사 제외 (echo 안의 키워드 오탐지 방지)
echo "$CMD" | grep -qE '^\s*(git|echo|cat|printf|head|tail|grep|sed|awk|less|more|wc|diff)\s' && exit 0

TS="$(date '+%Y-%m-%d %H:%M')"
CMD_LOWER="$(echo "$CMD" | tr '[:upper:]' '[:lower:]')"

# ── 차단 패턴 검사 (Python으로 처리 — bash grep 패턴 이슈 회피) ────
BLOCKED_REASON="$(python3 - "$CMD_LOWER" << 'PYEOF'
import sys, re

cmd = sys.argv[1]

rules = [
    # 1. ORM DB 초기화/삭제
    (r'db:reset|db:drop|db:purge|db:wipe|db:nuke', 'DB 초기화/삭제 (ORM)'),
    (r'migrate:fresh', 'DB 완전 초기화 (migrate:fresh)'),
    (r'prisma migrate reset', 'Prisma DB 초기화'),
    (r'prisma db push.*--force-reset', 'Prisma 강제 스키마 초기화'),
    (r'knex migrate:rollback.*--all', 'Knex 전체 롤백'),
    (r'sequelize.*db:drop', 'Sequelize DB 삭제'),
    (r'typeorm.*schema:drop', 'TypeORM 스키마 삭제'),
    (r'mongoose.*dropdatabase|mongoose.*dropcollection', 'Mongoose DB/컬렉션 삭제'),
    (r'rails\s+db:reset|rake\s+db:reset', 'Rails DB 완전 초기화'),
    (r'php\s+artisan\s+migrate:fresh', 'Laravel DB 완전 초기화'),
    (r'flask\s+db\s+downgrade\s+base|alembic\s+downgrade\s+base', 'Flask/Alembic DB 다운그레이드'),
    # 2. 원시 SQL
    (r'drop\s+(database|schema|table|tablespace)\s+', 'SQL DROP 명령'),
    (r'truncate\s+(table\s+)?\w', 'SQL TRUNCATE 명령'),
    (r'delete\s+from\s+\w+\s*(;|$)', '조건 없는 DELETE 전체 삭제'),
    # 3. 위험한 파일/디렉토리 삭제
    (r'rm\s+-[rf]+\s+.*/(data|storage|uploads|backup|dump|db|database|volumes)\b', '데이터 디렉토리 강제 삭제'),
    (r'rm\s+-[rf]+\s+/', '루트 경로 강제 삭제'),
    (r'find\s+.*-exec\s+rm', 'find + rm 대량 삭제'),
    # 4. Docker/K8s 볼륨 삭제
    (r'docker.*prune.*--volumes|docker.*volume\s+rm|docker\s+system\s+prune', 'Docker 볼륨/시스템 삭제'),
    (r'kubectl\s+delete\s+(namespace|ns)\b', 'Kubernetes 네임스페이스 삭제'),
    (r'docker-compose\s+(down.*-v|.*--volumes)', 'Docker Compose 볼륨 삭제'),
]

for pattern, reason in rules:
    if re.search(pattern, cmd):
        print(reason)
        sys.exit(0)
PYEOF
)"

# ── 매칭 없으면 통과 ────────────────────────────────────────────────
[ -z "$BLOCKED_REASON" ] && exit 0

# ── 차단: exit 2 (hard block) ───────────────────────────────────────
echo "COLLAR_DESTRUCTIVE_GUARD: [$TS] 파괴적 명령 차단"
echo ""
echo "  사유: $BLOCKED_REASON"
echo "  명령: $(echo "$CMD" | head -1 | cut -c1-120)"
echo ""
echo "  이 명령은 복구 불가능한 데이터 손실을 유발할 수 있어 자동 차단됩니다."
echo "  실행이 필요하면 터미널에서 직접 실행하세요:"
echo ""
echo "    ! $(echo "$CMD" | head -1)"
echo ""
echo "  또는 CLAUDE.md에 명시적 허용 패턴을 추가하세요."

exit 2
