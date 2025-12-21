#!/usr/bin/env bash
set -euo pipefail

## MinIO(S3) Snapshot Repository 등록(초기 1회)
## - 전제: repository-s3 플러그인 사용 가능(대부분 번들/설치 필요)
## - 전제: MinIO access/secret은 keystore에 저장됨(configure_minio_keystore.sh)
##
## 환경변수(필수):
##   OPENSEARCH_ADMIN_USER (기본: admin)
##   OPENSEARCH_ADMIN_PASSWORD
##   MINIO_ENDPOINT (예: 10.10.31.10:9000)
##   MINIO_BUCKET (예: bems-backups)
##
## 환경변수(선택):
##   OPENSEARCH_HOST (기본: 10.10.21.50)
##   REPO_NAME (기본: bems_minio_repo)
##   BASE_PATH (기본: opensearch)
##   S3_CLIENT_NAME (기본: default)
##   MINIO_PROTOCOL (기본: http)

: "${OPENSEARCH_ADMIN_PASSWORD:?OPENSEARCH_ADMIN_PASSWORD 필요}"
: "${MINIO_ENDPOINT:?MINIO_ENDPOINT 필요}"
: "${MINIO_BUCKET:?MINIO_BUCKET 필요}"

: "${OPENSEARCH_HOST:=10.10.21.50}"
: "${OPENSEARCH_ADMIN_USER:=admin}"
: "${REPO_NAME:=bems_minio_repo}"
: "${BASE_PATH:=opensearch}"
: "${S3_CLIENT_NAME:=default}"
: "${MINIO_PROTOCOL:=http}"

curl -k -u "${OPENSEARCH_ADMIN_USER}:${OPENSEARCH_ADMIN_PASSWORD}" \
  -H "Content-Type: application/json" \
  -X PUT "https://${OPENSEARCH_HOST}:9200/_snapshot/${REPO_NAME}" \
  -d @- <<EOF
{
  "type": "s3",
  "settings": {
    "bucket": "${MINIO_BUCKET}",
    "base_path": "${BASE_PATH}",
    "endpoint": "${MINIO_ENDPOINT}",
    "protocol": "${MINIO_PROTOCOL}",
    "path_style_access": true,
    "client": "${S3_CLIENT_NAME}",
    "compress": true
  }
}
EOF

echo
echo "✅ Snapshot repository 등록 완료: ${REPO_NAME}"
echo "   확인: GET https://${OPENSEARCH_HOST}:9200/_snapshot/${REPO_NAME}"

