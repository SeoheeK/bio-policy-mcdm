#!/usr/bin/env bash
set -euo pipefail

## Redis Cluster 생성(6노드, replicas=1)
## 사용법:
##   REDIS_PASSWORD=... ./cluster_create.sh

: "${REDIS_PASSWORD:?REDIS_PASSWORD 환경변수가 필요합니다}"

redis-cli --cluster create \
  10.10.21.40:6379 \
  10.10.21.41:6379 \
  10.10.21.42:6379 \
  10.10.21.43:6379 \
  10.10.21.44:6379 \
  10.10.21.45:6379 \
  --cluster-replicas 1 \
  -a "${REDIS_PASSWORD}"

echo "✅ Redis Cluster 생성 완료"

