#!/usr/bin/env bash
set -euo pipefail

## MinIO 초기 버킷 생성 및 정책 예시
## 사용법:
##   MINIO_ROOT_USER=admin MINIO_ROOT_PASSWORD=... ./bootstrap_buckets.sh
##
## 환경변수(선택):
##   MINIO_ENDPOINT (기본: http://10.10.31.10:9000)
##   MINIO_ALIAS (기본: bems-minio)

: "${MINIO_ROOT_USER:?MINIO_ROOT_USER 필요}"
: "${MINIO_ROOT_PASSWORD:?MINIO_ROOT_PASSWORD 필요}"

: "${MINIO_ENDPOINT:=http://10.10.31.10:9000}"
: "${MINIO_ALIAS:=bems-minio}"

if ! command -v mc >/dev/null 2>&1; then
  echo "❌ mc가 필요합니다. infra/minio/scripts/install_mc.sh로 설치하세요." >&2
  exit 1
fi

mc alias set "${MINIO_ALIAS}" "${MINIO_ENDPOINT}" "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}"

# 버킷 생성
mc mb --ignore-existing "${MINIO_ALIAS}/bems-documents"
mc mb --ignore-existing "${MINIO_ALIAS}/bems-attachments"
mc mb --ignore-existing "${MINIO_ALIAS}/bems-models"
mc mb --ignore-existing "${MINIO_ALIAS}/bems-backups"

# 기본: 비공개
mc anonymous set none "${MINIO_ALIAS}/bems-documents"
mc anonymous set none "${MINIO_ALIAS}/bems-attachments"
mc anonymous set none "${MINIO_ALIAS}/bems-models"
mc anonymous set none "${MINIO_ALIAS}/bems-backups"

echo "✅ 버킷 생성/기본 정책 적용 완료"
mc ls "${MINIO_ALIAS}"

