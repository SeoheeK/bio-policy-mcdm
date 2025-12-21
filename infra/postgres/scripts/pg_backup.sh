#!/usr/bin/env bash
set -euo pipefail

## PostgreSQL Full Backup (pg_basebackup)
## - Patroni/HAProxy 환경에서 Primary endpoint(5432)로 수행 권장
##
## 환경변수:
##   PGHOST (기본: 10.10.21.15 또는 HAProxy IP)
##   PGPORT (기본: 5432)
##   PGUSER (기본: replicator 또는 backup_user)
##   PGPASSWORD (필수)
##   BACKUP_DIR (기본: /backup/postgresql/full)
##   RETENTION_DAYS (기본: 30)

: "${PGHOST:=10.10.21.15}"
: "${PGPORT:=5432}"
: "${PGUSER:=replicator}"
: "${PGPASSWORD:?PGPASSWORD 필요}"

: "${BACKUP_DIR:=/backup/postgresql/full}"
: "${RETENTION_DAYS:=30}"

DATE="$(date +%Y%m%d_%H%M%S)"
NAME="bems_pg_full_${DATE}.tar.gz"

mkdir -p "${BACKUP_DIR}"

export PGHOST PGPORT PGUSER PGPASSWORD

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

pg_basebackup \
  -Ft -z \
  -D "${tmpdir}" \
  -X stream \
  -P

# pg_basebackup -Ft -z 는 tar 파일을 생성(디렉토리 내 *.tar.gz)
tarball="$(find "${tmpdir}" -maxdepth 1 -type f -name "*.tar.gz" | head -n 1)"
if [[ -z "${tarball}" ]]; then
  echo "❌ tar 백업 파일을 찾지 못했습니다." >&2
  exit 1
fi

mv "${tarball}" "${BACKUP_DIR}/${NAME}"

# 보관기간 정리
find "${BACKUP_DIR}" -type f -name "bems_pg_full_*.tar.gz" -mtime "+${RETENTION_DAYS}" -delete

echo "✅ PostgreSQL backup 완료: ${BACKUP_DIR}/${NAME}"

