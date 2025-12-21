#!/usr/bin/env bash
set -euo pipefail

## postgres_exporter 설치(systemd)
## 사용법:
##   sudo ./install_postgres_exporter.sh
## 사전:
##   /etc/postgres_exporter/postgres_exporter.env 에 DATA_SOURCE_NAME 설정

if [[ $EUID -ne 0 ]]; then
  echo "root로 실행하세요." >&2
  exit 1
fi

VERSION="${POSTGRES_EXPORTER_VERSION:-0.16.0}"
ARCH="$(uname -m)"
case "${ARCH}" in
  x86_64) ARCH_DL="linux-amd64" ;;
  aarch64) ARCH_DL="linux-arm64" ;;
  *) echo "지원하지 않는 아키텍처: ${ARCH}" >&2; exit 1 ;;
esac

apt-get update
apt-get install -y wget tar

id -u pgexp >/dev/null 2>&1 || useradd -r -s /bin/false pgexp
mkdir -p /etc/postgres_exporter
chmod 750 /etc/postgres_exporter

if [[ ! -f /etc/postgres_exporter/postgres_exporter.env ]]; then
  echo "⚠️ /etc/postgres_exporter/postgres_exporter.env가 없습니다."
  echo "   infra/monitoring/exporters/postgres/conf/postgres_exporter.env.example를 복사해 설정하세요."
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

url="https://github.com/prometheus-community/postgres_exporter/releases/download/v${VERSION}/postgres_exporter-${VERSION}.${ARCH_DL}.tar.gz"
wget -O "${tmp}/postgres_exporter.tgz" "${url}"
tar -xzf "${tmp}/postgres_exporter.tgz" -C "${tmp}"
install -m 0755 "${tmp}/postgres_exporter-${VERSION}.${ARCH_DL}/postgres_exporter" /usr/local/bin/postgres_exporter

install -m 0644 /workspace/infra/monitoring/exporters/postgres/systemd/postgres_exporter.service /etc/systemd/system/postgres_exporter.service
systemctl daemon-reload
systemctl enable postgres_exporter
systemctl restart postgres_exporter
systemctl --no-pager status postgres_exporter

echo "✅ postgres_exporter 설치/기동 완료 (:9187)"

