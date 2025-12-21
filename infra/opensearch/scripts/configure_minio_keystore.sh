#!/usr/bin/env bash
set -euo pipefail

## OpenSearch keystore에 MinIO(S3) 자격증명 저장
## - repository 등록 전에 모든 OpenSearch 노드에서 실행 권장
##
## 환경변수(필수):
##   MINIO_ACCESS_KEY
##   MINIO_SECRET_KEY
## 환경변수(선택):
##   S3_CLIENT_NAME (기본: default)

: "${MINIO_ACCESS_KEY:?MINIO_ACCESS_KEY 필요}"
: "${MINIO_SECRET_KEY:?MINIO_SECRET_KEY 필요}"
: "${S3_CLIENT_NAME:=default}"

OS_HOME="${OS_HOME:-/opt/opensearch}"
CONF_DIR="${CONF_DIR:-${OS_HOME}/config}"

cd "${OS_HOME}"

if [[ ! -x "${OS_HOME}/bin/opensearch-keystore" ]]; then
  echo "❌ opensearch-keystore를 찾을 수 없습니다: ${OS_HOME}/bin/opensearch-keystore" >&2
  exit 1
fi

# keystore 생성(없으면)
if [[ ! -f "${CONF_DIR}/opensearch.keystore" ]]; then
  "${OS_HOME}/bin/opensearch-keystore" create
fi

echo -n "${MINIO_ACCESS_KEY}" | "${OS_HOME}/bin/opensearch-keystore" add -f "s3.client.${S3_CLIENT_NAME}.access_key" --stdin
echo -n "${MINIO_SECRET_KEY}" | "${OS_HOME}/bin/opensearch-keystore" add -f "s3.client.${S3_CLIENT_NAME}.secret_key" --stdin

echo "✅ keystore 저장 완료: s3.client.${S3_CLIENT_NAME}.access_key / secret_key"
echo "   (변경 후 모든 노드에서 OpenSearch 재시작 권장)"

