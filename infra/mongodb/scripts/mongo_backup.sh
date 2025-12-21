#!/usr/bin/env bash
set -euo pipefail

## MongoDB 백업 (mongodump + --oplog)
## - Replica Set 환경에서 일관성 확보를 위해 --oplog 권장
## - 보관 정책은 상위 통합 백업 스크립트에서 관리하는 것을 권장

BACKUP_DIR="${BACKUP_DIR:-/backup/mongodb}"
DATE="$(date +%Y%m%d_%H%M%S)"
NAME="bems_mongo_${DATE}"

: "${MONGO_HOST:=10.10.21.20}"
: "${MONGO_PORT:=27017}"
: "${MONGO_ADMIN_USER:=admin}"
: "${MONGO_ADMIN_PASSWORD:?MONGO_ADMIN_PASSWORD 환경변수가 필요합니다}"

mkdir -p "${BACKUP_DIR}"

mongodump \
  --host "${MONGO_HOST}" --port "${MONGO_PORT}" \
  --username "${MONGO_ADMIN_USER}" --password "${MONGO_ADMIN_PASSWORD}" \
  --authenticationDatabase admin \
  --oplog \
  --out "${BACKUP_DIR}/${NAME}" \
  --gzip

tar -C "${BACKUP_DIR}" -czf "${BACKUP_DIR}/${NAME}.tar.gz" "${NAME}"
rm -rf "${BACKUP_DIR:?}/${NAME}"

echo "✅ MongoDB backup 완료: ${BACKUP_DIR}/${NAME}.tar.gz"

