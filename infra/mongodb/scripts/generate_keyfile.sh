#!/usr/bin/env bash
set -euo pipefail

## MongoDB Replica Set keyFile 생성
## - 모든 MongoDB 노드에 동일 파일 배포 필요
## - 권한: 400, 소유: mongodb:mongodb

OUT="${1:-/etc/mongodb-keyfile}"

if [[ $EUID -ne 0 ]]; then
  echo "root로 실행하세요." >&2
  exit 1
fi

umask 077
openssl rand -base64 756 > "${OUT}"
chmod 400 "${OUT}"
chown mongodb:mongodb "${OUT}" || true

echo "✅ 생성 완료: ${OUT}"
echo "   (이 파일을 모든 MongoDB 노드에 동일하게 배포하세요)"

