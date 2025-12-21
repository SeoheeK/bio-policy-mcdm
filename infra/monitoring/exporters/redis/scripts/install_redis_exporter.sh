#!/usr/bin/env bash
set -euo pipefail

## redis_exporter 설치(systemd)
## 사용법:
##   sudo ./install_redis_exporter.sh
## 사전:
##   /etc/redis_exporter/redis_exporter.env 에 REDIS_ADDR/REDIS_PASSWORD 설정

if [[ $EUID -ne 0 ]]; then
  echo "root로 실행하세요." >&2
  exit 1
fi

VERSION="${REDIS_EXPORTER_VERSION:-1.63.0}"
ARCH="$(uname -m)"
case "${ARCH}" in
  x86_64) ARCH_DL="linux-amd64" ;;
  aarch64) ARCH_DL="linux-arm64" ;;
  *) echo "지원하지 않는 아키텍처: ${ARCH}" >&2; exit 1 ;;
esac

apt-get update
apt-get install -y wget tar

id -u redisexp >/dev/null 2>&1 || useradd -r -s /bin/false redisexp
mkdir -p /etc/redis_exporter
chmod 750 /etc/redis_exporter

if [[ ! -f /etc/redis_exporter/redis_exporter.env ]]; then
  echo "⚠️ /etc/redis_exporter/redis_exporter.env가 없습니다."
  echo "   infra/monitoring/exporters/redis/conf/redis_exporter.env.example를 복사해 설정하세요."
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

url="https://github.com/oliver006/redis_exporter/releases/download/v${VERSION}/redis_exporter-v${VERSION}.${ARCH_DL}.tar.gz"
wget -O "${tmp}/redis_exporter.tgz" "${url}"
tar -xzf "${tmp}/redis_exporter.tgz" -C "${tmp}"
install -m 0755 "${tmp}/redis_exporter-v${VERSION}.${ARCH_DL}/redis_exporter" /usr/local/bin/redis_exporter

install -m 0644 /workspace/infra/monitoring/exporters/redis/systemd/redis_exporter.service /etc/systemd/system/redis_exporter.service
systemctl daemon-reload
systemctl enable redis_exporter
systemctl restart redis_exporter
systemctl --no-pager status redis_exporter

echo "✅ redis_exporter 설치/기동 완료 (:9121)"

