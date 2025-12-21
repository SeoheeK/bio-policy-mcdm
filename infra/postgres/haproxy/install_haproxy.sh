#!/usr/bin/env bash
set -euo pipefail

## HAProxy 설치/적용(단일 엔드포인트 제공)
## - 5432: Primary(쓰기)
## - 5433: Replica(읽기)

if [[ $EUID -ne 0 ]]; then
  echo "root로 실행하세요." >&2
  exit 1
fi

apt-get update
apt-get install -y haproxy

install -m 0644 /workspace/infra/postgres/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg
install -m 0644 /workspace/infra/postgres/haproxy/haproxy.service /etc/systemd/system/haproxy.service

systemctl daemon-reload
systemctl enable haproxy
systemctl restart haproxy
systemctl --no-pager status haproxy

echo
echo "✅ HAProxy 적용 완료"
echo " - Primary endpoint: <haproxy-ip>:5432"
echo " - Replica endpoint : <haproxy-ip>:5433"

