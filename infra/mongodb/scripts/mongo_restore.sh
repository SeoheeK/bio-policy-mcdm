#!/usr/bin/env bash
set -euo pipefail

## MongoDB 복구 (mongorestore)
## 사용법:
##   ./mongo_restore.sh /backup/mongodb/bems_mongo_YYYYmmdd_HHMMSS.tar.gz

ARCHIVE="${1:-}"
if [[ -z "${ARCHIVE}" ]]; then
  echo "Usage: $0 <backup_tar_gz>" >&2
  exit 1
fi

: "${MONGO_HOST:=10.10.21.20}"
: "${MONGO_PORT:=27017}"
: "${MONGO_ADMIN_USER:=admin}"
: "${MONGO_ADMIN_PASSWORD:?MONGO_ADMIN_PASSWORD 환경변수가 필요합니다}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

tar -xzf "${ARCHIVE}" -C "${tmp}"
dir="$(find "${tmp}" -maxdepth 1 -type d -name "bems_mongo_*" | head -n 1)"
if [[ -z "${dir}" ]]; then
  echo "백업 디렉토리를 찾지 못했습니다." >&2
  exit 1
fi

mongorestore \
  --host "${MONGO_HOST}" --port "${MONGO_PORT}" \
  --username "${MONGO_ADMIN_USER}" --password "${MONGO_ADMIN_PASSWORD}" \
  --authenticationDatabase admin \
  --drop \
  --gzip \
  "${dir}"

echo "✅ MongoDB restore 완료: ${ARCHIVE}"

