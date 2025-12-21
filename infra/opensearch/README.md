# OpenSearch 2.11 온프레미스 클러스터 + MinIO(S3) Snapshot Repository

## 목표 구성

- Master(3): `10.10.21.50`, `10.10.21.51`, `10.10.21.52`
- Data+Ingest(3): `10.10.21.55`, `10.10.21.56`, `10.10.21.57`
- HTTP: `9200`, Transport: `9300`
- Security plugin: TLS/인증 활성화
- Snapshot Repository: **MinIO(S3 호환)** (`bems-backups` 버킷 권장)

## 필수 사전 OS 튜닝(모든 노드)

- `vm.max_map_count=262144`
- swap off (또는 최소화)
- THP 비활성화(권장)
- ulimit(noFile/nproc) 상향

`scripts/preflight_tuning.sh` 참고.

## 설치/기동 흐름(요약)

1. (모든 노드) `scripts/preflight_tuning.sh` 실행
2. (모든 노드) OpenSearch 설치 및 systemd 등록: `scripts/install_opensearch.sh <role> <node_name> <ip>`
3. (모든 노드) 인증서 배치(또는 생성): `security/README.md` 참고
4. (초기 1회) Security 초기화: `scripts/init_security.sh`
5. (초기 1회) MinIO Snapshot repo 등록: `scripts/register_snapshot_repo_minio.sh`

## MinIO Snapshot 저장소(결정사항: B안)

- OpenSearch는 `repository-s3`를 사용합니다.
- 민감정보(access/secret key)는 **keystore**에 저장하고, repository 등록 요청에는 넣지 않습니다.

