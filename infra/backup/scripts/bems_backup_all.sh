#!/usr/bin/env bash
set -euo pipefail

## BEMS 통합 백업 오케스트레이터
## - 정책/보관기간은 환경변수로 제어(backup.env 권장)
##
## 사용법:
##   ./bems_backup_all.sh [/path/to/backup.env]

ENV_FILE="${1:-}"
if [[ -n "${ENV_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
fi

: "${BACKUP_ROOT:=/backup}"

DATE="$(date +%Y%m%d_%H%M%S)"
LOG_DIR="${BACKUP_ROOT}/logs"
LOG_FILE="${LOG_DIR}/backup_${DATE}.log"

mkdir -p "${LOG_DIR}"

log() { echo "[$(date +%F' '%T)] $*" | tee -a "${LOG_FILE}"; }

log "=== BEMS Backup Started: ${DATE} ==="

# ----------------------------------------
# 1) PostgreSQL (30일)
# ----------------------------------------
if [[ -n "${PGPASSWORD:-}" ]]; then
  log "[1] PostgreSQL backup 시작"
  PGPASSWORD="${PGPASSWORD}" \
  PGHOST="${PGHOST:-10.10.21.15}" PGPORT="${PGPORT:-5432}" PGUSER="${PGUSER:-replicator}" \
  BACKUP_DIR="${BACKUP_ROOT}/postgresql/full" RETENTION_DAYS="${PG_RETENTION_DAYS:-30}" \
  /workspace/infra/postgres/scripts/pg_backup.sh >> "${LOG_FILE}" 2>&1
  log "[1] PostgreSQL backup 완료"
else
  log "[1] PostgreSQL backup 스킵(PGPASSWORD 미설정)"
fi

# ----------------------------------------
# 2) MongoDB (30일)
# ----------------------------------------
if [[ -n "${MONGO_ADMIN_PASSWORD:-}" ]]; then
  log "[2] MongoDB backup 시작"
  MONGO_HOST="${MONGO_HOST:-10.10.21.20}" MONGO_PORT="${MONGO_PORT:-27017}" \
  MONGO_ADMIN_USER="${MONGO_ADMIN_USER:-admin}" MONGO_ADMIN_PASSWORD="${MONGO_ADMIN_PASSWORD}" \
  BACKUP_DIR="${BACKUP_ROOT}/mongodb" \
  /workspace/infra/mongodb/scripts/mongo_backup.sh >> "${LOG_FILE}" 2>&1
  find "${BACKUP_ROOT}/mongodb" -type f -name "bems_mongo_*.tar.gz" -mtime "+${MONGO_RETENTION_DAYS:-30}" -delete || true
  log "[2] MongoDB backup 완료"
else
  log "[2] MongoDB backup 스킵(MONGO_ADMIN_PASSWORD 미설정)"
fi

# ----------------------------------------
# 3) Neo4j (30일)
# ----------------------------------------
if command -v neo4j-admin >/dev/null 2>&1; then
  log "[3] Neo4j backup 시작"
  NEO4J_BACKUP_FROM="${NEO4J_BACKUP_FROM:-10.10.21.30:6362}" \
  NEO4J_DATABASE="${NEO4J_DATABASE:-neo4j}" \
  BACKUP_DIR="${BACKUP_ROOT}/neo4j" \
  /workspace/infra/neo4j/scripts/neo4j_backup.sh >> "${LOG_FILE}" 2>&1
  find "${BACKUP_ROOT}/neo4j" -type d -mtime "+${NEO4J_RETENTION_DAYS:-30}" -exec rm -rf {} \; 2>/dev/null || true
  log "[3] Neo4j backup 완료"
else
  log "[3] Neo4j backup 스킵(neo4j-admin 미설치 환경)"
fi

# ----------------------------------------
# 4) OpenSearch Snapshot (30일)
# ----------------------------------------
if [[ -n "${OPENSEARCH_ADMIN_PASSWORD:-}" ]]; then
  log "[4] OpenSearch snapshot 시작"
  repo="${OPENSEARCH_SNAPSHOT_REPO:-bems_minio_repo}"
  snap="bems-os-${DATE}"
  curl -k -u "${OPENSEARCH_ADMIN_USER:-admin}:${OPENSEARCH_ADMIN_PASSWORD}" \
    -X PUT "https://${OPENSEARCH_HOST:-10.10.21.50}:9200/_snapshot/${repo}/${snap}?wait_for_completion=true" \
    -H "Content-Type: application/json" \
    -d "{\"indices\":\"*\",\"include_global_state\":true}" >> "${LOG_FILE}" 2>&1 || true
  log "[4] OpenSearch snapshot 요청 완료(repo=${repo}, snapshot=${snap})"
  log "    (보관기간 정리는 MinIO 버킷 lifecycle 또는 별도 스냅샷 삭제 작업으로 관리 권장)"
else
  log "[4] OpenSearch snapshot 스킵(OPENSEARCH_ADMIN_PASSWORD 미설정)"
fi

# ----------------------------------------
# 5) Redis (7일) - 스냅샷 트리거만(파일 수집은 운영 방식에 따라 추가)
# ----------------------------------------
if [[ -n "${REDIS_PASSWORD:-}" && -n "${REDIS_NODES:-}" ]]; then
  log "[5] Redis BGSAVE 트리거 시작"
  for node in ${REDIS_NODES}; do
    host="${node%:*}"; port="${node#*:}"
    redis-cli -h "${host}" -p "${port}" -a "${REDIS_PASSWORD}" BGSAVE >> "${LOG_FILE}" 2>&1 || true
  done
  log "[5] Redis BGSAVE 트리거 완료"
else
  log "[5] Redis 스킵(REDIS_PASSWORD 또는 REDIS_NODES 미설정)"
fi

# ----------------------------------------
# 6) Qdrant (주 1회/일요일, 90일)
# ----------------------------------------
if [[ "$(date +%u)" == "7" ]]; then
  log "[6] Qdrant snapshot(주간) 시작"
  QDRANT_HOST="${QDRANT_HOST:-10.10.21.60}" QDRANT_PORT="${QDRANT_PORT:-6333}" \
  COLLECTION="${QDRANT_COLLECTION:-bems_policy_documents}" \
  BACKUP_DIR="${BACKUP_ROOT}/qdrant" \
  /workspace/infra/qdrant/scripts/qdrant_snapshot.sh >> "${LOG_FILE}" 2>&1
  find "${BACKUP_ROOT}/qdrant" -type f -name "qdrant_*.snapshot" -mtime "+${QDRANT_RETENTION_DAYS:-90}" -delete || true
  log "[6] Qdrant snapshot 완료"
else
  log "[6] Qdrant snapshot 스킵(일요일만 수행)"
fi

# ----------------------------------------
# 7) MinIO 외부 mirror(선택, 90일)
# ----------------------------------------
if command -v mc >/dev/null 2>&1 && [[ -n "${MINIO_ROOT_PASSWORD:-}" ]]; then
  log "[7] MinIO mirror(선택) 시작"
  alias="${MINIO_ALIAS:-bems-minio}"
  mc alias set "${alias}" "${MINIO_ENDPOINT:-http://10.10.31.10:9000}" "${MINIO_ROOT_USER:-admin}" "${MINIO_ROOT_PASSWORD}" >> "${LOG_FILE}" 2>&1
  mkdir -p "${BACKUP_ROOT}/minio"
  mc mirror --overwrite "${alias}/bems-backups" "${BACKUP_ROOT}/minio/bems-backups" >> "${LOG_FILE}" 2>&1 || true
  find "${BACKUP_ROOT}/minio" -type f -mtime "+${MINIO_RETENTION_DAYS:-90}" -delete || true
  log "[7] MinIO mirror 완료"
else
  log "[7] MinIO mirror 스킵(mc 미설치 또는 MINIO_ROOT_PASSWORD 미설정)"
fi

log "=== BEMS Backup Completed: $(date +%Y%m%d_%H%M%S) ==="

# 로그 보관(30일)
find "${LOG_DIR}" -type f -name "backup_*.log" -mtime +30 -delete || true

