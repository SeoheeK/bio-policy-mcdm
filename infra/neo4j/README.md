# Neo4j 5.15 (Enterprise) — Core 3노드 클러스터 + neo4j-admin backup

## 전제(중요)

Neo4j **클러스터(Core/Read Replica) 및 온라인 백업(`neo4j-admin database backup`)**은 **Enterprise 구독**이 필요합니다.  
본 폴더는 Enterprise 기준으로 **3-Core 클러스터**를 구현 가능한 템플릿/스크립트로 제공합니다.

## 목표 구성

- Core-1: `10.10.21.30`
- Core-2: `10.10.21.31`
- Core-3: `10.10.21.32`

## 포트(기본)

- Client
  - Bolt: `7687/tcp`
  - HTTP: `7474/tcp`
- Cluster internal
  - Discovery/raft: `6000/tcp` (예시)
- Backup (Enterprise)
  - `6362/tcp`

## 산출물

- `conf/neo4j.core*.conf.template`: Core 노드 설정 템플릿
- `systemd/neo4j.service`: systemd 서비스 템플릿
- `scripts/install_neo4j_enterprise.sh`: 설치/설정/기동(예시)
- `scripts/neo4j_backup.sh`: `neo4j-admin database backup` 기반 백업
- `scripts/neo4j_restore.sh`: 오프라인 복구(restore) 가이드/스크립트

## 참고: Community 대안(필요 시)

Community에서는 클러스터가 불가하므로 단일 노드 + dump/load 백업으로 운영합니다(별도 문서로 분리 가능).

