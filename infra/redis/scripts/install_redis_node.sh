#!/usr/bin/env bash
set -euo pipefail

## Redis 7.2 소스 설치 + 노드 설정 생성 + systemd 등록
## 사용법:
##   sudo REDIS_PASSWORD=... ./install_redis_node.sh <bind_ip>
## 예:
##   sudo REDIS_PASSWORD=... ./install_redis_node.sh 10.10.21.40

BIND_IP="${1:-}"
if [[ -z "${BIND_IP}" ]]; then
  echo "Usage: REDIS_PASSWORD=... $0 <bind_ip>" >&2
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
  echo "root로 실행하세요." >&2
  exit 1
fi

: "${REDIS_PASSWORD:?REDIS_PASSWORD 환경변수가 필요합니다}"

apt-get update
apt-get install -y build-essential tcl wget

cd /tmp
wget -O redis-stable.tar.gz https://download.redis.io/redis-stable.tar.gz
tar -xzf redis-stable.tar.gz
cd redis-stable
make -j"$(nproc)"
make install

id -u redis >/dev/null 2>&1 || useradd -r -s /bin/false redis
mkdir -p /etc/redis /data/redis/6379 /var/log/redis /var/run/redis
chown -R redis:redis /data/redis /var/log/redis /var/run/redis

# 설정 파일 생성(템플릿 치환)
conf="/etc/redis/redis-6379.conf"
sed \
  -e "s/__BIND_IP__/${BIND_IP}/g" \
  -e "s#__DATA_DIR__#/data/redis/6379#g" \
  -e "s/__REDIS_PASSWORD__/${REDIS_PASSWORD}/g" \
  /workspace/infra/redis/conf/redis.conf.template > "${conf}"
chown redis:redis "${conf}"
chmod 640 "${conf}"

# systemd 템플릿 배치
install -m 0644 /workspace/infra/redis/systemd/redis@.service /etc/systemd/system/redis@.service

systemctl daemon-reload
systemctl enable redis@6379
systemctl restart redis@6379
systemctl --no-pager status redis@6379

echo "✅ Redis 노드 설치/기동 완료: ${BIND_IP}:6379"

