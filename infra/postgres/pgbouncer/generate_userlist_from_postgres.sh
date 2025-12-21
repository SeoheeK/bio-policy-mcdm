#!/usr/bin/env bash
set -euo pipefail

## PgBouncer userlist.txt 생성(서버에서 rolpassword(SCRAM)를 읽어오는 방식)
## - 주의: superuser 권한이 필요합니다(pg_authid 접근).
## - 실행 위치: PgBouncer 서버
##
## 사용 예:
##   export PGHOST=<haproxy-ip>
##   export PGPORT=5432
##   export PGUSER=postgres
##   export PGPASSWORD=...
##   export PGDATABASE=postgres
##   ./generate_userlist_from_postgres.sh bems_app replicator

OUT="/etc/pgbouncer/userlist.txt"
USERS=("$@")

if [[ ${#USERS[@]} -eq 0 ]]; then
  echo "사용자명을 1개 이상 전달하세요." >&2
  exit 1
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

for u in "${USERS[@]}"; do
  psql -Atc "SELECT '\"' || rolname || '\" ' || rolpassword FROM pg_authid WHERE rolname='${u}' AND rolpassword IS NOT NULL;" >> "$tmp"
done

install -m 0640 -o postgres -g postgres "$tmp" "$OUT"
echo "✅ 생성 완료: ${OUT}"

