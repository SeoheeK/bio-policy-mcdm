#!/usr/bin/env bash
set -euo pipefail

## MinIO 설치/기동(노드 단위)
## 사용법:
##   sudo ./install_minio_node.sh
##
## 전제:
## - /data/minio/disk1..disk8 디렉토리(또는 마운트) 준비
## - /etc/minio/minio.env 생성(generate_minio_env.sh로 생성 권장)

if [[ $EUID -ne 0 ]]; then
  echo "root로 실행하세요." >&2
  exit 1
fi

apt-get update
apt-get install -y wget

# minio 바이너리 설치
wget -O /usr/local/bin/minio https://dl.min.io/server/minio/release/linux-amd64/minio
chmod +x /usr/local/bin/minio

# 사용자/디렉토리
id -u minio >/dev/null 2>&1 || useradd -r -s /bin/false minio
mkdir -p /etc/minio /data/minio
chown -R minio:minio /data/minio

# systemd 등록
install -m 0644 /workspace/infra/minio/systemd/minio.service /etc/systemd/system/minio.service
systemctl daemon-reload
systemctl enable minio

if [[ ! -f /etc/minio/minio.env ]]; then
  echo "⚠️ /etc/minio/minio.env가 없습니다. 먼저 generate_minio_env.sh로 생성하세요."
  echo "   예: sudo MINIO_ROOT_USER=admin MINIO_ROOT_PASSWORD=... ./generate_minio_env.sh"
  exit 1
fi

systemctl restart minio
systemctl --no-pager status minio

echo "✅ MinIO 기동 완료"

