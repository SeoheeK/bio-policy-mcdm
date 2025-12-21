#!/usr/bin/env bash
set -euo pipefail

## OpenSearch exporter 설치(systemd) - elasticsearch_exporter 사용
## 사용법:
##   sudo ./install_opensearch_exporter.sh
##
## 사전:
##   /etc/opensearch_exporter/opensearch_exporter.env 생성
##   (conf/opensearch_exporter.env.example 참고)

if [[ $EUID -ne 0 ]]; then
  echo "root로 실행하세요." >&2
  exit 1
fi

VERSION="${ELASTICSEARCH_EXPORTER_VERSION:-1.7.0}"
ARCH="$(uname -m)"
case "${ARCH}" in
  x86_64) ARCH_DL="linux-amd64" ;;
  aarch64) ARCH_DL="linux-arm64" ;;
  *) echo "지원하지 않는 아키텍처: ${ARCH}" >&2; exit 1 ;;
esac

apt-get update
apt-get install -y wget tar

id -u osexp >/dev/null 2>&1 || useradd -r -s /bin/false osexp
mkdir -p /etc/opensearch_exporter
chmod 750 /etc/opensearch_exporter

if [[ ! -f /etc/opensearch_exporter/opensearch_exporter.env ]]; then
  echo "⚠️ /etc/opensearch_exporter/opensearch_exporter.env가 없습니다."
  echo "   infra/monitoring/exporters/opensearch/conf/opensearch_exporter.env.example를 복사해 설정하세요."
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

url="https://github.com/prometheus-community/elasticsearch_exporter/releases/download/v${VERSION}/elasticsearch_exporter-${VERSION}.${ARCH_DL}.tar.gz"
wget -O "${tmp}/es_exporter.tgz" "${url}"
tar -xzf "${tmp}/es_exporter.tgz" -C "${tmp}"
install -m 0755 "${tmp}/elasticsearch_exporter-${VERSION}.${ARCH_DL}/elasticsearch_exporter" /usr/local/bin/elasticsearch_exporter

install -m 0644 /workspace/infra/monitoring/exporters/opensearch/systemd/opensearch_exporter.service /etc/systemd/system/opensearch_exporter.service
systemctl daemon-reload
systemctl enable opensearch_exporter
systemctl restart opensearch_exporter
systemctl --no-pager status opensearch_exporter

echo "✅ opensearch_exporter 설치/기동 완료 (:9114)"

