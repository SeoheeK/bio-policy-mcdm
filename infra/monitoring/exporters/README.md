# Exporter 배포 템플릿 (systemd)

Prometheus가 실제로 지표를 수집하려면 각 서버에 exporter를 설치해야 합니다.

## 포함 exporter

- node_exporter: 서버 OS/디스크/CPU/RAM
- postgres_exporter: PostgreSQL 지표
- mongodb_exporter: MongoDB 지표
- redis_exporter: Redis 지표

## 공통 규칙

- 모든 exporter는 **systemd**로 기동
- 포트는 내부망에서만 접근(방화벽/보안그룹/VLAN 정책 적용)

