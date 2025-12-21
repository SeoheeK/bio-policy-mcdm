#!/usr/bin/env bash
set -euo pipefail

## PostgreSQL 15 + Patroni 설치/기동(노드 단위)
## 사용법:
##  - node1(10.10.21.10): sudo ./install_patroni_node.sh node1
##  - node2(10.10.21.11): sudo ./install_patroni_node.sh node2
##
## 사전조건:
##  - /etc/etcd/etcd.env 구성 및 etcd 3노드 정상 기동
##  - /etc/patroni/patroni.env 생성(비밀번호 포함, 권한 제한)

ROLE="${1:-}"
if [[ "${ROLE}" != "node1" && "${ROLE}" != "node2" ]]; then
  echo "Usage: $0 node1|node2" >&2
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
  echo "root로 실행하세요." >&2
  exit 1
fi

# 1) 패키지 설치
apt-get update
apt-get install -y postgresql-15 postgresql-contrib-15 python3-pip python3-venv

# 2) 데이터 디렉토리 준비(NVMe 마운트 가정)
mkdir -p /data/postgresql
chown -R postgres:postgres /data/postgresql
chmod 700 /data/postgresql

# 3) Patroni 설치(패키지 매니저 기반)
# Ubuntu 리포에 patroni가 있을 수 있으나 버전 변동이 있어 pip로 고정 권장
python3 -m pip install --upgrade pip
python3 -m pip install "patroni[etcd]==3.2.2"

# 4) 기본 PostgreSQL 서비스 비활성화(Patroni가 postgres를 직접 관리)
systemctl stop postgresql || true
systemctl disable postgresql || true

# 5) Patroni 설정 배치
mkdir -p /etc/patroni
if [[ "${ROLE}" == "node1" ]]; then
  install -m 0644 /workspace/infra/postgres/patroni/patroni.node1.yml /etc/patroni/patroni.yml
else
  install -m 0644 /workspace/infra/postgres/patroni/patroni.node2.yml /etc/patroni/patroni.yml
fi
chown -R postgres:postgres /etc/patroni

if [[ ! -f /etc/patroni/patroni.env ]]; then
  echo "⚠️ /etc/patroni/patroni.env가 없습니다. infra/postgres/patroni/patroni.env.example를 복사해 실제 비밀번호를 주입하세요." >&2
fi
chmod 640 /etc/patroni/patroni.env || true
chown postgres:postgres /etc/patroni/patroni.env || true

# 6) systemd 등록
install -m 0644 /workspace/infra/postgres/patroni/patroni.service /etc/systemd/system/patroni.service
systemctl daemon-reload
systemctl enable patroni
systemctl restart patroni
systemctl --no-pager status patroni

echo
echo "✅ Patroni 노드 설치/기동 완료: ${ROLE}"
echo "   - Patroni REST: http://$(hostname -I | awk '{print $1}'):8008"

