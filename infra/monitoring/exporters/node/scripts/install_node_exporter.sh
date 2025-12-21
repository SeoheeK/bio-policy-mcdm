#!/usr/bin/env bash
set -euo pipefail

## node_exporter 설치(systemd)
## 사용법: sudo ./install_node_exporter.sh

if [[ $EUID -ne 0 ]]; then
  echo "root로 실행하세요." >&2
  exit 1
fi

VERSION="${NODE_EXPORTER_VERSION:-1.8.2}"
ARCH="$(uname -m)"
case "${ARCH}" in
  x86_64) ARCH_DL="linux-amd64" ;;
  aarch64) ARCH_DL="linux-arm64" ;;
  *) echo "지원하지 않는 아키텍처: ${ARCH}" >&2; exit 1 ;;
esac

apt-get update
apt-get install -y wget tar

id -u nodeexp >/dev/null 2>&1 || useradd -r -s /bin/false nodeexp

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

url="https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.${ARCH_DL}.tar.gz"
wget -O "${tmp}/node_exporter.tgz" "${url}"
tar -xzf "${tmp}/node_exporter.tgz" -C "${tmp}"
install -m 0755 "${tmp}/node_exporter-${VERSION}.${ARCH_DL}/node_exporter" /usr/local/bin/node_exporter

install -m 0644 /workspace/infra/monitoring/exporters/node/systemd/node_exporter.service /etc/systemd/system/node_exporter.service
systemctl daemon-reload
systemctl enable node_exporter
systemctl restart node_exporter
systemctl --no-pager status node_exporter

echo "✅ node_exporter 설치/기동 완료 (:9100)"

