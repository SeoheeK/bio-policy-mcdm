#!/usr/bin/env bash
set -euo pipefail

## mongodb_exporter 설치(systemd)
## 사용법:
##   sudo ./install_mongodb_exporter.sh
## 사전:
##   /etc/mongodb_exporter/mongodb_exporter.env 에 MONGODB_URI 설정

if [[ $EUID -ne 0 ]]; then
  echo "root로 실행하세요." >&2
  exit 1
fi

# percona/mongodb_exporter 기준(널리 사용)
VERSION="${MONGODB_EXPORTER_VERSION:-0.40.0}"
ARCH="$(uname -m)"
case "${ARCH}" in
  x86_64) ARCH_DL="amd64" ;;
  aarch64) ARCH_DL="arm64" ;;
  *) echo "지원하지 않는 아키텍처: ${ARCH}" >&2; exit 1 ;;
esac

apt-get update
apt-get install -y wget tar

id -u mongoexp >/dev/null 2>&1 || useradd -r -s /bin/false mongoexp
mkdir -p /etc/mongodb_exporter
chmod 750 /etc/mongodb_exporter

if [[ ! -f /etc/mongodb_exporter/mongodb_exporter.env ]]; then
  echo "⚠️ /etc/mongodb_exporter/mongodb_exporter.env가 없습니다."
  echo "   infra/monitoring/exporters/mongodb/conf/mongodb_exporter.env.example를 복사해 설정하세요."
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

url="https://github.com/percona/mongodb_exporter/releases/download/v${VERSION}/mongodb_exporter-${VERSION}.linux-${ARCH_DL}.tar.gz"
wget -O "${tmp}/mongodb_exporter.tgz" "${url}"
tar -xzf "${tmp}/mongodb_exporter.tgz" -C "${tmp}"

bin="$(find "${tmp}" -type f -name mongodb_exporter | head -n 1)"
install -m 0755 "${bin}" /usr/local/bin/mongodb_exporter

install -m 0644 /workspace/infra/monitoring/exporters/mongodb/systemd/mongodb_exporter.service /etc/systemd/system/mongodb_exporter.service
systemctl daemon-reload
systemctl enable mongodb_exporter
systemctl restart mongodb_exporter
systemctl --no-pager status mongodb_exporter

echo "✅ mongodb_exporter 설치/기동 완료 (:9216)"

