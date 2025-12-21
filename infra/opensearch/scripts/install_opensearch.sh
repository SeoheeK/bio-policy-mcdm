#!/usr/bin/env bash
set -euo pipefail

## OpenSearch 2.11 설치/설정/기동 (노드 단위)
## 사용법:
##   sudo ./install_opensearch.sh master master-node-1 10.10.21.50
##   sudo ./install_opensearch.sh data   data-node-1   10.10.21.55
##
## 환경변수(권장):
##   OPENSEARCH_TARBALL_URL=https://artifacts.opensearch.org/releases/bundle/opensearch/2.11.0/opensearch-2.11.0-linux-x64.tar.gz

ROLE="${1:-}"
NODE_NAME="${2:-}"
NODE_IP="${3:-}"

if [[ "${ROLE}" != "master" && "${ROLE}" != "data" ]]; then
  echo "Usage: $0 master|data <node_name> <node_ip>" >&2
  exit 1
fi
if [[ -z "${NODE_NAME}" || -z "${NODE_IP}" ]]; then
  echo "Usage: $0 master|data <node_name> <node_ip>" >&2
  exit 1
fi
if [[ $EUID -ne 0 ]]; then
  echo "root로 실행하세요." >&2
  exit 1
fi

URL="${OPENSEARCH_TARBALL_URL:-https://artifacts.opensearch.org/releases/bundle/opensearch/2.11.0/opensearch-2.11.0-linux-x64.tar.gz}"

apt-get update
apt-get install -y wget tar curl

id -u opensearch >/dev/null 2>&1 || useradd -r -s /bin/false opensearch

mkdir -p /opt
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

wget -O "${tmp}/opensearch.tgz" "${URL}"
tar -xzf "${tmp}/opensearch.tgz" -C "${tmp}"
rm -rf /opt/opensearch
mv "${tmp}"/opensearch-* /opt/opensearch

mkdir -p /data/opensearch /var/log/opensearch /opt/opensearch/config/certs
chown -R opensearch:opensearch /data/opensearch /var/log/opensearch /opt/opensearch

# config 배치
if [[ "${ROLE}" == "master" ]]; then
  cp /workspace/infra/opensearch/conf/opensearch.master.yml.template /opt/opensearch/config/opensearch.yml
  cp /workspace/infra/opensearch/conf/jvm.options.master /opt/opensearch/config/jvm.options
else
  cp /workspace/infra/opensearch/conf/opensearch.data.yml.template /opt/opensearch/config/opensearch.yml
  cp /workspace/infra/opensearch/conf/jvm.options.data /opt/opensearch/config/jvm.options
fi

sed -i \
  -e "s/__NODE_NAME__/${NODE_NAME}/g" \
  -e "s/__NODE_IP__/${NODE_IP}/g" \
  /opt/opensearch/config/opensearch.yml

# systemd 등록
install -m 0644 /workspace/infra/opensearch/systemd/opensearch.service /etc/systemd/system/opensearch.service
systemctl daemon-reload
systemctl enable opensearch

echo "⚠️ 인증서 파일을 /opt/opensearch/config/certs/ 에 배치한 뒤 opensearch를 시작하세요."
echo "   - root-ca.pem, node.pem, node-key.pem (필수)"
echo
echo "다음 명령으로 기동:"
echo "  sudo systemctl start opensearch"

