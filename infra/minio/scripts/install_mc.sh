#!/usr/bin/env bash
set -euo pipefail

## MinIO Client(mc) 설치
## 사용법: sudo ./install_mc.sh

if [[ $EUID -ne 0 ]]; then
  echo "root로 실행하세요." >&2
  exit 1
fi

apt-get update
apt-get install -y wget

wget -O /usr/local/bin/mc https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x /usr/local/bin/mc

echo "✅ mc 설치 완료: /usr/local/bin/mc"

