#!/usr/bin/env bash
set -euo pipefail

## Qdrant 스냅샷 백업(HTTP API)
## - 스냅샷 생성 후 가장 최근 스냅샷을 다운로드
##
## 환경변수:
##   QDRANT_HOST (기본: 10.10.21.60)
##   QDRANT_PORT (기본: 6333)
##   COLLECTION (기본: bems_policy_documents)
##   BACKUP_DIR (기본: /backup/qdrant)

: "${QDRANT_HOST:=10.10.21.60}"
: "${QDRANT_PORT:=6333}"
: "${COLLECTION:=bems_policy_documents}"
: "${BACKUP_DIR:=/backup/qdrant}"

mkdir -p "${BACKUP_DIR}"

echo "1) 스냅샷 생성..."
curl -sS -X POST "http://${QDRANT_HOST}:${QDRANT_PORT}/collections/${COLLECTION}/snapshots" >/dev/null

echo "2) 스냅샷 목록 조회..."
json="$(curl -sS "http://${QDRANT_HOST}:${QDRANT_PORT}/collections/${COLLECTION}/snapshots")"

if ! command -v jq >/dev/null 2>&1; then
  echo "❌ jq가 필요합니다. (apt-get install -y jq)" >&2
  exit 1
fi

snapshot="$(echo "${json}" | jq -r '.result[-1].name // empty')"
if [[ -z "${snapshot}" ]]; then
  echo "❌ 스냅샷 이름을 찾지 못했습니다." >&2
  echo "${json}" >&2
  exit 1
fi

date_tag="$(date +%Y%m%d_%H%M%S)"
out="${BACKUP_DIR}/qdrant_${COLLECTION}_${date_tag}.snapshot"

echo "3) 스냅샷 다운로드: ${snapshot}"
curl -sS -o "${out}" "http://${QDRANT_HOST}:${QDRANT_PORT}/collections/${COLLECTION}/snapshots/${snapshot}"

echo "✅ 완료: ${out}"

