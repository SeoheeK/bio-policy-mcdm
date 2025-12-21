# MongoDB 7 Replica Set (온프레미스)

## 목표 구성

- Replica Set: `bems-replica-set`
  - Primary: `10.10.21.20:27017`
  - Secondary-1: `10.10.21.21:27017`
  - Secondary-2: `10.10.21.22:27017`

## 핵심 원칙

- systemd로 운영 시 `processManagement.fork: false` 권장
- Replica Set 인증을 위해 **keyFile**을 모든 노드에 동일하게 배포
- 백업은 일관성을 위해 `mongodump --oplog` 권장

## 산출물

- `conf/mongod.yml.*`: 노드별 설정 템플릿
- `scripts/`: keyFile 생성/배포, rs.initiate, 사용자 생성, 백업/복구 스크립트

