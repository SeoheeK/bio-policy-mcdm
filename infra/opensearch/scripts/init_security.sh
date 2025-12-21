#!/usr/bin/env bash
set -euo pipefail

## OpenSearch Security 초기화(초기 1회)
## - master-node-1 등 한 곳에서 실행
## - admin 인증서/키 필요
##
## 환경변수:
##   OPENSEARCH_ADMIN_PASSWORD (선택: 내부 user DB 초기 암호 세팅에 사용)
##   OPENSEARCH_HOST (기본: 10.10.21.50)

: "${OPENSEARCH_HOST:=10.10.21.50}"

OS_HOME="${OS_HOME:-/opt/opensearch}"
CONF_DIR="${CONF_DIR:-${OS_HOME}/config}"
TOOLS_DIR="${OS_HOME}/plugins/opensearch-security/tools"

if [[ ! -x "${TOOLS_DIR}/securityadmin.sh" ]]; then
  echo "❌ securityadmin.sh를 찾을 수 없습니다: ${TOOLS_DIR}/securityadmin.sh" >&2
  exit 1
fi

if [[ ! -f "${CONF_DIR}/certs/admin.pem" || ! -f "${CONF_DIR}/certs/admin-key.pem" || ! -f "${CONF_DIR}/certs/root-ca.pem" ]]; then
  echo "❌ admin/root-ca 인증서가 필요합니다. ${CONF_DIR}/certs/ 확인" >&2
  exit 1
fi

echo "OpenSearch가 기동 중인지 확인하세요(HTTPS 9200)."
echo "대상: https://${OPENSEARCH_HOST}:9200"
echo

${TOOLS_DIR}/securityadmin.sh \
  -cd "${CONF_DIR}/opensearch-security" \
  -icl \
  -nhnv \
  -cacert "${CONF_DIR}/certs/root-ca.pem" \
  -cert "${CONF_DIR}/certs/admin.pem" \
  -key "${CONF_DIR}/certs/admin-key.pem" \
  -h "${OPENSEARCH_HOST}"

echo "✅ Security 초기화 완료"

