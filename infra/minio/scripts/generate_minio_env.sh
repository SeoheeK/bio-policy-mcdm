#!/usr/bin/env bash
set -euo pipefail

## MinIO env 파일 생성 (systemd brace-expansion 없이 MINIO_VOLUMES를 명시적으로 생성)
## 사용법:
##   sudo MINIO_ROOT_USER=admin MINIO_ROOT_PASSWORD=... \
##     ./generate_minio_env.sh /etc/minio/minio.env 10.10.31.10,10.10.31.11,10.10.31.12,10.10.31.13 8
##
## 인자:
##   1) 출력 경로 (기본: /etc/minio/minio.env)
##   2) 노드 IP 목록(콤마 구분)
##   3) 노드당 디스크 개수(기본: 8)

OUT="${1:-/etc/minio/minio.env}"
NODES_CSV="${2:-10.10.31.10,10.10.31.11,10.10.31.12,10.10.31.13}"
DISKS_PER_NODE="${3:-8}"

if [[ $EUID -ne 0 ]]; then
  echo "root로 실행하세요." >&2
  exit 1
fi

: "${MINIO_ROOT_USER:?MINIO_ROOT_USER 필요}"
: "${MINIO_ROOT_PASSWORD:?MINIO_ROOT_PASSWORD 필요}"

IFS=',' read -r -a NODES <<< "${NODES_CSV}"

vols=()
for ip in "${NODES[@]}"; do
  for d in $(seq 1 "${DISKS_PER_NODE}"); do
    vols+=("http://${ip}/data/minio/disk${d}")
  done
done

mkdir -p "$(dirname "${OUT}")"

cat > "${OUT}" <<EOF
MINIO_ROOT_USER=${MINIO_ROOT_USER}
MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}
MINIO_OPTS=--console-address :9001
MINIO_VOLUMES=${vols[*]}
EOF

chmod 600 "${OUT}"
echo "✅ 생성 완료: ${OUT}"

