# 통합 백업(온프레미스) — 정책/보관기간 일치

이 폴더는 PostgreSQL/MongoDB/Neo4j/OpenSearch/Qdrant/MinIO/Redis 백업을 **하나의 오케스트레이션 스크립트**로 실행하고, **보관기간(정책)**에 맞춰 자동 정리합니다.

## 정책(기본값)

- PostgreSQL: **매일**, 보관 **30일**
- MongoDB: **매일**, 보관 **30일**
- Neo4j: **매일**, 보관 **30일**
- OpenSearch Snapshot(→ MinIO): **매일**, 보관 **30일**
- Redis: **매일 스냅샷 트리거**, 보관 **7일**
- Qdrant Snapshot: **주 1회(일요일)**, 보관 **90일**
- MinIO: 자체 분산/복제 + (선택) 외부 mirror, 보관 **90일**

> 실제 운영에서는 백업 대상 호스트에 대한 SSH 접근(키 기반) 또는 각 호스트에서 로컬 스케줄러로 실행하는 방식 중 하나로 표준화하세요.

## 산출물

- `backup.env.example`: 환경변수 템플릿(호스트/자격증명은 외부 주입)
- `scripts/bems_backup_all.sh`: 통합 백업 오케스트레이터

