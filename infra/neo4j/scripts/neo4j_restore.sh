#!/usr/bin/env bash
set -euo pipefail

## Neo4j 복구(오프라인 restore 개념)
## - 실제 restore 절차는 Neo4j 버전/배포 방식에 따라 차이가 있어
##   여기서는 “운영 체크리스트” 형태로 제공합니다.
##
## 일반 절차(요약):
## 1) neo4j 서비스 중지
## 2) 대상 DB drop/이동(안전 백업)
## 3) 백업 산출물로 restore 또는 load 수행
## 4) 서비스 기동 및 정합성 확인
##
## 참고:
## - Enterprise online backup 산출물은 버전에 따라 restore 커맨드가 다를 수 있습니다.
## - 운영 중 복구는 장애 범위/클러스터 상태에 따라 Runbook이 별도로 필요합니다.

echo "이 스크립트는 자동 복구를 수행하지 않습니다(체크리스트만 제공합니다)."
echo
cat <<'EOF'
[Neo4j Restore 체크리스트]
1) 서비스 중지
   sudo systemctl stop neo4j

2) 데이터 디렉토리 확인(배포 방식에 따라 상이)
   - /var/lib/neo4j/data/databases/<db>

3) 백업 파일/디렉토리 준비
   - /backup/neo4j 하위의 backup set

4) 복구 실행(환경에 맞는 neo4j-admin 명령 사용)
   - neo4j-admin database restore ... (버전별 상이)

5) 서비스 기동 및 확인
   sudo systemctl start neo4j
   cypher-shell -u neo4j -p '***' "SHOW DATABASES;"
EOF

