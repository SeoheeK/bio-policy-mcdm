# MinIO (4-Node Distributed, 온프레미스)

## 목표 구성

- Node-1: `10.10.31.10`
- Node-2: `10.10.31.11`
- Node-3: `10.10.31.12`
- Node-4: `10.10.31.13`

포트:
- S3 API: `9000/tcp`
- Console: `9001/tcp`

## systemd brace-expansion 이슈 해결 방식

systemd `Environment=`는 bash brace expansion(`{10...13}`)을 수행하지 않습니다.  
따라서 본 구현은:

- `/etc/minio/minio.env`에 **MINIO_VOLUMES를 “명시적으로 펼친 문자열”**로 저장
- `minio.service`는 `EnvironmentFile`로 해당 env를 읽어 기동

## 산출물

- `systemd/minio.service`: systemd 유닛
- `systemd/minio.env.example`: env 예시(볼륨은 펼친 형태로 제공)
- `scripts/install_minio_node.sh`: MinIO 바이너리 설치 + 유저/디렉토리 + systemd 등록
- `scripts/generate_minio_env.sh`: 노드 IP/디스크 수 기준으로 minio.env 생성(brace-expansion 없이)
- `scripts/install_mc.sh`: MinIO Client(mc) 설치
- `scripts/bootstrap_buckets.sh`: 버킷 생성/기본 정책 적용 예제

