#!/usr/bin/env bash
set -euo pipefail

## PgBouncer 설치/적용(옵션)
## - 이 템플릿은 "클라이언트 인증은 PgBouncer에서, 서버로는 동일 사용자로 접속" 형태입니다.
## - auth_file에 SCRAM secret이 필요합니다(아래 스크립트로 생성 가능).

if [[ $EUID -ne 0 ]]; then
  echo "root로 실행하세요." >&2
  exit 1
fi

apt-get update
apt-get install -y pgbouncer

install -m 0644 /workspace/infra/postgres/pgbouncer/pgbouncer.ini /etc/pgbouncer/pgbouncer.ini
install -m 0644 /workspace/infra/postgres/pgbouncer/pgbouncer.service /etc/systemd/system/pgbouncer.service

mkdir -p /etc/pgbouncer
touch /etc/pgbouncer/userlist.txt
chown postgres:postgres /etc/pgbouncer/userlist.txt
chmod 640 /etc/pgbouncer/userlist.txt

systemctl daemon-reload
systemctl enable pgbouncer
systemctl restart pgbouncer
systemctl --no-pager status pgbouncer

echo
echo "✅ PgBouncer 적용 완료"
echo " - Endpoint: <pgbouncer-ip>:6432 (DB: bems)"
echo " - 다음 단계: /etc/pgbouncer/userlist.txt에 사용자/SCRAM secret 등록"

