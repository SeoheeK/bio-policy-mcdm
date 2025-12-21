#!/usr/bin/env bash
set -euo pipefail

## Ubuntu 22.04 기준 etcd 설치/기동 스크립트(예시)
## - 실제 운영에서는 패키지 레포/버전 고정, TLS 적용을 권장합니다.

if [[ $EUID -ne 0 ]]; then
  echo "root로 실행하세요." >&2
  exit 1
fi

apt-get update
apt-get install -y etcd

id -u etcd >/dev/null 2>&1 || useradd -r -s /bin/false etcd

mkdir -p /etc/etcd /var/lib/etcd
chown -R etcd:etcd /var/lib/etcd

if [[ ! -f /etc/etcd/etcd.env ]]; then
  echo "⚠️ /etc/etcd/etcd.env가 없습니다. infra/postgres/etcd/etcd.env.example를 복사해 노드별로 수정하세요."
fi

install -m 0644 /workspace/infra/postgres/etcd/etcd.service /etc/systemd/system/etcd.service
systemctl daemon-reload
systemctl enable etcd
systemctl restart etcd
systemctl --no-pager status etcd

