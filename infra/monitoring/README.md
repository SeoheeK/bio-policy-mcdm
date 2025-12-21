# 모니터링(온프레미스) — Prometheus + Grafana 템플릿

## 목표

- Prometheus: 지표 수집/알림 룰
- Grafana: 대시보드 시각화

## 산출물

- `docker-compose.yml`: Prometheus + Grafana 실행 템플릿(옵션)
- `prometheus/prometheus.yml`: scrape 설정 템플릿
- `alerts/database_alerts.yml`: DB/스토리지/클러스터 알림 룰 예시

## Exporter(예시 포트)

- node_exporter: `9100`
- postgres_exporter: `9187`
- mongodb_exporter: `9216`
- redis_exporter: `9121`

OpenSearch는 exporter를 별도 배포하거나, API 기반 헬스체크를 혼합 운영할 수 있습니다.

