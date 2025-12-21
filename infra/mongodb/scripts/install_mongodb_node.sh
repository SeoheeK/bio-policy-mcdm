#!/usr/bin/env bash
set -euo pipefail

## MongoDB 7 노드 설치/설정(Primary/Secondary 공통)
## 사용법:
##  - sudo ./install_mongodb_node.sh primary|secondary1|secondary2
##
## 사전조건:
##  - /etc/mongodb-keyfile 존재(모든 노드 동일), 권한 400, 소유 mongodb:mongodb
##  - /data/mongodb 디스크 마운트

ROLE="${1:-}"
if [[ "${ROLE}" != "primary" && "${ROLE}" != "secondary1" && "${ROLE}" != "secondary2" ]]; then
  echo "Usage: $0 primary|secondary1|secondary2" >&2
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
  echo "root로 실행하세요." >&2
  exit 1
fi

apt-get update
apt-get install -y wget gnupg

if [[ ! -f /usr/share/keyrings/mongodb-server-7.0.gpg ]]; then
  wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor | tee /usr/share/keyrings/mongodb-server-7.0.gpg >/dev/null
fi

cat >/etc/apt/sources.list.d/mongodb-org-7.0.list <<'EOF'
deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse
EOF

apt-get update
apt-get install -y mongodb-org

mkdir -p /data/mongodb
chown -R mongodb:mongodb /data/mongodb

if [[ ! -f /etc/mongodb-keyfile ]]; then
  echo "❌ /etc/mongodb-keyfile 이 없습니다. 먼저 keyfile을 생성/배포하세요." >&2
  exit 1
fi
chmod 400 /etc/mongodb-keyfile
chown mongodb:mongodb /etc/mongodb-keyfile

case "${ROLE}" in
  primary)
    install -m 0644 /workspace/infra/mongodb/conf/mongod.primary.yml /etc/mongod.conf
    ;;
  secondary1)
    install -m 0644 /workspace/infra/mongodb/conf/mongod.secondary1.yml /etc/mongod.conf
    ;;
  secondary2)
    install -m 0644 /workspace/infra/mongodb/conf/mongod.secondary2.yml /etc/mongod.conf
    ;;
esac

systemctl daemon-reload
systemctl enable mongod
systemctl restart mongod
systemctl --no-pager status mongod

echo "✅ MongoDB 노드 설치/기동 완료: ${ROLE}"

