# 온프레미스 인프라 구현 산출물

이 디렉토리는 “데이터베이스 설계서(온프레미스)”에 기술된 구성을 실제 구현할 수 있도록 **설정 템플릿 / 스크립트 / 운영 가이드**를 제공합니다.

## 구성

- `postgres/`: PostgreSQL 15 HA (Streaming Replication + Patroni + etcd) 및 접속 프록시(HAProxy/PgBouncer) 템플릿
- `mongodb/`: MongoDB 7 Replica Set 설정 및 초기화 스크립트
- `redis/`: Redis 7.2 Cluster(3 master + 3 replica) 설정 및 systemd 템플릿
- `opensearch/`: OpenSearch 2.11 Cluster(3 master + 3 data) 설정/사전 튜닝/보안 초기화 가이드
- `neo4j/`: Neo4j 5.15 Cluster(3 core) 설정 템플릿
- `qdrant/`: Qdrant 1.7 컬렉션/백업 스크립트 및 compose 예시
- `minio/`: MinIO 4노드 분산 구성 systemd 템플릿 및 운영 스크립트
- `backup/`: 통합 백업/보관 정책 스크립트
- `monitoring/`: Prometheus 설정 및 알림 룰 예시
- `secrets/`: 비밀정보(패스워드/키/인증서) 관리 방식 및 예시 템플릿

## 보안(필수)

- 이 저장소에는 **실제 비밀번호/키/인증서 값을 절대 넣지 않습니다.**
- 모든 값은 환경변수 또는 Vault/Secret Manager/Ansible Vault/Kubernetes Secret으로 주입합니다.

