# Redis 7.2 Cluster (3 Master + 3 Replica)

## 목표 구성

- Master-1: `10.10.21.40:6379` → Replica-1: `10.10.21.43:6379`
- Master-2: `10.10.21.41:6379` → Replica-2: `10.10.21.44:6379`
- Master-3: `10.10.21.42:6379` → Replica-3: `10.10.21.45:6379`

## 포트

- Redis: `6379/tcp`
- Cluster bus: `16379/tcp` (port+10000)

## 산출물

- `conf/redis.conf.template`: 공통 설정 템플릿(노드별 IP/announce 값만 변경)
- `systemd/redis@.service`: systemd 템플릿(종료 시 bind 문제 방지)
- `scripts/cluster_create.sh`: 6노드 클러스터 생성 명령 스크립트

