#!/usr/bin/env bash
set -euo pipefail

## Neo4j Enterprise 설치/설정/기동(예시)
## - 배포/라이선스 방식은 조직 구독 계약에 따라 다르므로,
##   이 스크립트는 “파일 배치/서비스 등록” 중심 템플릿입니다.
##
## 사용법:
##   sudo NEO4J_PASSWORD=... ./install_neo4j_enterprise.sh core1|core2|core3
##
## 전제:
## - Neo4j Enterprise 패키지가 OS 패키지 저장소/사내 저장소에 준비되어 있어야 함
## - /data/neo4j 디스크 마운트(권장)

ROLE="${1:-}"
if [[ "${ROLE}" != "core1" && "${ROLE}" != "core2" && "${ROLE}" != "core3" ]]; then
  echo "Usage: NEO4J_PASSWORD=... $0 core1|core2|core3" >&2
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
  echo "root로 실행하세요." >&2
  exit 1
fi

: "${NEO4J_PASSWORD:?NEO4J_PASSWORD 필요}"

# (1) 설치: 조직 구독에 맞는 방식으로 설치해야 함
echo "⚠️ Neo4j Enterprise 설치는 구독/리포지토리 정책에 따라 달라 자동화하지 않습니다."
echo "   예: apt repo(enterprise), 사내 아티팩트, 오프라인 패키지 등"
echo "   설치 후 다음 파일들이 존재해야 합니다:"
echo "    - /usr/bin/neo4j"
echo "    - /usr/bin/neo4j-admin"
echo

# (2) 데이터 디렉토리
mkdir -p /data/neo4j
chown -R neo4j:neo4j /data/neo4j || true

# (3) 설정 배치
mkdir -p /etc/neo4j
case "${ROLE}" in
  core1) install -m 0644 /workspace/infra/neo4j/conf/neo4j.core1.conf.template /etc/neo4j/neo4j.conf ;;
  core2) install -m 0644 /workspace/infra/neo4j/conf/neo4j.core2.conf.template /etc/neo4j/neo4j.conf ;;
  core3) install -m 0644 /workspace/infra/neo4j/conf/neo4j.core3.conf.template /etc/neo4j/neo4j.conf ;;
esac

# (4) 초기 비밀번호 설정(첫 기동 전)
if command -v neo4j-admin >/dev/null 2>&1; then
  neo4j-admin dbms set-initial-password "${NEO4J_PASSWORD}" || true
fi

# (5) systemd 등록
install -m 0644 /workspace/infra/neo4j/systemd/neo4j.service /etc/systemd/system/neo4j.service
systemctl daemon-reload
systemctl enable neo4j
systemctl restart neo4j
systemctl --no-pager status neo4j

echo "✅ Neo4j Enterprise(${ROLE}) 설정/기동 완료(설치가 선행되어 있어야 함)"

