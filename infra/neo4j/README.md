# Neo4j 5.15 (Community) — 단일 노드 운영안

## 전제(중요)

Neo4j **Community Edition**은 **클러스터(코어/리드레플리카), Raft 기반 자동 페일오버**를 지원하지 않습니다.  
따라서 본 문서는 다음을 목표로 합니다.

- **단일 노드 Neo4j 5.15**를 안정적으로 운영
- 정기 **백업/복구(neo4j-admin database dump/load)** 절차 제공
- (옵션) 외부 HA 구성은 별도 의사결정 후 적용

## 권장 운영 구성(기본)

- Neo4j 서버: `10.10.21.30`
- 포트
  - Bolt: `7687/tcp`
  - HTTP: `7474/tcp`
  - HTTPS(선택): `7473/tcp`

## HA(가용성) 대안(의사결정 필요)

Community 기반에서 HA를 하려면 DB 레벨이 아니라 **인프라 레벨**로 접근합니다.

- **A안(기본)**: 단일 노드 + 백업/복구(가장 단순)
  - 장애 시 복구(수동) 중심, RTO/RPO는 백업 주기에 좌우
- **B안(권장)**: Warm Standby 1대 + 주기적 dump 전송 + VIP(Keepalived)
  - RPO: dump 주기(예: 1시간), RTO: 수십 분~1시간대 가능
- **C안(고급)**: 스토리지 레벨 복제(DRBD/스토리지 미러링)
  - 운영 복잡/위험(일관성 보장 주의), 별도 설계 필요

## 산출물

- `conf/neo4j.conf.template`: 단일 노드 설정 템플릿
- `scripts/install_neo4j.sh`: Neo4j 설치/기동(예시)
- `scripts/neo4j_backup.sh`: database dump 백업
- `scripts/neo4j_restore.sh`: database load 복구

