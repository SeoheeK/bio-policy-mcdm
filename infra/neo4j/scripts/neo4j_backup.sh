#!/usr/bin/env bash
set -euo pipefail

## Neo4j Enterprise 온라인 백업(neo4j-admin database backup)
## - Core 중 아무 노드(보통 core1)에서 실행 가능
##
## 환경변수:
##   NEO4J_BACKUP_FROM (기본: 10.10.21.30:6362)
##   NEO4J_DATABASE (기본: neo4j)
##   BACKUP_DIR (기본: /backup/neo4j)

: "${NEO4J_BACKUP_FROM:=10.10.21.30:6362}"
: "${NEO4J_DATABASE:=neo4j}"
: "${BACKUP_DIR:=/backup/neo4j}"

DATE="$(date +%Y%m%d_%H%M%S)"
NAME="bems-neo4j-${NEO4J_DATABASE}-${DATE}"

mkdir -p "${BACKUP_DIR}"

neo4j-admin database backup \
  --from="${NEO4J_BACKUP_FROM}" \
  --database="${NEO4J_DATABASE}" \
  --to-path="${BACKUP_DIR}" \
  --overwrite=false

echo "✅ Neo4j backup 완료: ${BACKUP_DIR} (database=${NEO4J_DATABASE}, from=${NEO4J_BACKUP_FROM})"

